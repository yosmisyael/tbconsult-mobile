import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:TBConsult/features/health_hub/domain/entities/message.dart';
import 'package:TBConsult/features/health_hub/domain/entities/triage_response.dart';
import 'package:TBConsult/features/health_hub/domain/usecases/send_message_usecase.dart';

class TriageRemoteDataSource implements TriageService {
  final String apiKey;
  final SharedPreferences prefs;
  
  GenerativeModel? _geminiModel;
  ChatSession? _geminiChatSession;
  
  static const _uuid = Uuid();

  TriageRemoteDataSource({
    required this.apiKey,
    required this.prefs,
  });

  // ── Backend URL & Authentication ────────────────────────────────────────

  String _getBackendUrl() {
    final baseUrl = dotenv.env['BACKEND_BASE_URL'] ?? 'http://localhost:8000/v1';
    if (!kIsWeb && Platform.isAndroid) {
      if (baseUrl.contains('localhost')) {
        return baseUrl.replaceAll('localhost', '10.0.2.2');
      }
      if (baseUrl.contains('127.0.0.1')) {
        return baseUrl.replaceAll('127.0.0.1', '10.0.2.2');
      }
    }
    return baseUrl;
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
      final payload = parts[1];
      var normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64.decode(normalized));
      final Map<String, dynamic> payloadMap = jsonDecode(resp);
      
      if (payloadMap.containsKey('exp')) {
        final exp = payloadMap['exp'] as int;
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        // Treat as expired if within 5 minutes of expiration to avoid race conditions
        return DateTime.now().isAfter(expiryTime.subtract(const Duration(minutes: 5)));
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  Future<String> _getAccessToken({bool forceRefresh = false}) async {
    var token = prefs.getString('backend_jwt_token');
    if (token != null && !forceRefresh && !_isTokenExpired(token)) {
      return token;
    }

    var deviceUserId = prefs.getString('device_user_id');
    if (deviceUserId == null) {
      deviceUserId = _uuid.v4();
      await prefs.setString('device_user_id', deviceUserId);
    }

    final url = Uri.parse('${_getBackendUrl()}/auth/token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': deviceUserId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['access_token'] as String;
      await prefs.setString('backend_jwt_token', accessToken);
      return accessToken;
    } else {
      throw HttpException('Failed to acquire JWT token from backend: ${response.statusCode}');
    }
  }

  // ── Triage Chat Message ──────────────────────────────────────────────────

  @override
  Future<TriageResponse> sendMessage({
    required String userMessage,
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String sessionId,
    List<int>? imageBytes,
  }) async {
    try {
      final backendUrl = _getBackendUrl();
      final token = await _getAccessToken();
      
      final chatUri = Uri.parse('$backendUrl/triage/chat');
      
      final response = await http.post(
        chatUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'session_id': sessionId,
          'message': userMessage,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 401) {
        // Expired or invalid token, refresh once and retry
        debugPrint('TriageRemoteDataSource: Token expired (401), refreshing...');
        final refreshedToken = await _getAccessToken(forceRefresh: true);
        final retryResponse = await http.post(
          chatUri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $refreshedToken',
          },
          body: jsonEncode({
            'session_id': sessionId,
            'message': userMessage,
          }),
        ).timeout(const Duration(seconds: 60));

        if (retryResponse.statusCode == 200) {
          return _parseTriageResponse(retryResponse.body);
        } else {
          throw HttpException('Backend triage retry failed with: ${retryResponse.statusCode}');
        }
      }

      if (response.statusCode == 200) {
        return _parseTriageResponse(response.body);
      } else {
        throw HttpException('Backend triage request failed: ${response.statusCode}');
      }
    } catch (e) {
      // Graceful fallback to local/direct Gemini API
      debugPrint('TriageRemoteDataSource: Backend call failed ($e). Falling back to direct Gemini...');
      try {
        return await _sendGeminiFallback(
          userMessage: userMessage,
          systemPrompt: systemPrompt,
          history: history,
          imageBytes: imageBytes,
        );
      } catch (geminiError) {
        debugPrint('TriageRemoteDataSource: Gemini fallback also failed ($geminiError). Using local response.');
        return _localFallbackResponse(userMessage);
      }
    }
  }

  TriageResponse _parseTriageResponse(String body) {
    final Map<String, dynamic> json = jsonDecode(body);
    return TriageResponse(
      riskLevel: json['risk_level'] as String? ?? 'Low',
      responseText: json['response_text'] as String? ?? '',
      redFlags: (json['red_flags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      sources: (json['sources'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      sdui: json['sdui'] as Map<String, dynamic>?,
    );
  }

  Future<TriageResponse> _sendGeminiFallback({
    required String userMessage,
    required String systemPrompt,
    required List<Map<String, String>> history,
    List<int>? imageBytes,
  }) async {
    _geminiModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(systemPrompt),
    );

    final List<Content> historyContent = [];
    for (final m in history) {
      final role = m['role'] == 'user' ? 'user' : 'model';
      final text = m['content'] ?? '';
      
      if (historyContent.isNotEmpty && historyContent.last.role == role) {
        final prevParts = historyContent.last.parts.toList();
        prevParts.add(TextPart('\n\n$text'));
        historyContent[historyContent.length - 1] = Content(role, prevParts);
      } else {
        historyContent.add(Content(role, [TextPart(text)]));
      }
    }
    
    // Gemini startChat requires the last message in history to be from the model 
    // if we are about to send a user message.
    if (historyContent.isNotEmpty && historyContent.last.role == 'user') {
      historyContent.removeLast();
    }

    _geminiChatSession = _geminiModel!.startChat(history: historyContent);

    final List<Part> parts = [TextPart(userMessage)];
    if (imageBytes != null && imageBytes.isNotEmpty) {
      parts.add(DataPart('image/jpeg', Uint8List.fromList(imageBytes)));
    }

    final response = await _geminiChatSession!.sendMessage(Content.multi(parts));
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    return TriageResponse(
      riskLevel: 'Low',
      responseText: text,
      redFlags: const [],
      sources: const [],
      sdui: null,
    );
  }

  TriageResponse _localFallbackResponse(String userMessage) {
    final lower = userMessage.toLowerCase();
    
    String responseText;
    if (lower.contains('halo') || lower.contains('hello') || lower.contains('hi') || lower.contains('selamat')) {
      responseText = 'Halo! Saya TBConsult, asisten kesehatan untuk pasien TB. '
          'Maaf, saat ini saya sedang mengalami gangguan koneksi. '
          'Silakan coba lagi nanti atau hubungi petugas DOTS Anda untuk bantuan lebih lanjut.';
    } else if (lower.contains('sakit') || lower.contains('nyeri') || lower.contains('demam')) {
      responseText = 'Saya mengerti Anda sedang mengalami gejala yang tidak nyaman. '
          'Mohon segera konsultasikan dengan dokter atau petugas DOTS Anda untuk penanganan yang tepat. '
          'Jika Anda mengalami gejala darurat seperti sesak nafas berat atau batuk darah, segera kunjungi fasilitas kesehatan terdekat.';
    } else if (lower.contains('obat') || lower.contains('medication') || lower.contains('dosis')) {
      responseText = 'Untuk pertanyaan tentang obat dan dosis, sangat penting untuk berkonsultasi langsung dengan dokter atau petugas DOTS Anda. '
          'Mereka memiliki informasi lengkap tentang riwayat pengobatan Anda dan dapat memberikan saran yang tepat.';
    } else {
      responseText = 'Maaf, saya sedang mengalami gangguan koneksi dengan layanan AI saya. '
          'Silakan coba lagi nanti. Jika Anda memerlukan bantuan segera, '
          'jangan ragu untuk menghubungi petugas DOTS atau fasilitas kesehatan terdekat.\n\n'
          'Saya sarankan untuk berkonsultasi dengan dokter atau petugas DOTS Anda untuk pertanyaan ini.';
    }
    
    return TriageResponse(
      riskLevel: 'Low',
      responseText: responseText,
      redFlags: const [],
      sources: const [],
      sdui: null,
    );
  }

  // ── Conversation Summary (Direct Gemini Call) ───────────────────────────

  @override
  Future<String> generateConversationSummary(List<Message> messages) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_summarySystemPrompt),
    );

    final conversationText = messages.map((m) {
      final role = m.role == MessageRole.user ? 'Patient' : 'TBConsult';
      return '$role: ${m.content}';
    }).join('\n');

    final prompt = '''Analyze this TB patient conversation and provide a structured summary.

CONVERSATION:
$conversationText

Respond in EXACTLY this format:
## SUMMARY
[2-3 sentence overview of the conversation]

## KEY INSIGHTS
- [insight 1]
- [insight 2]
- [insight 3]

## RECOMMENDATIONS
- [recommendation 1]
- [recommendation 2]
- [recommendation 3]

RULES:
- Never mention specific doctor names
- Focus on actionable health guidance
- Keep each point concise (1 sentence)
- Write in the same language the patient used''';

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Empty summary response from Gemini');
    }

    return text;
  }

  static const _summarySystemPrompt =
      'You are a medical conversation summarizer for TB patients. '
      'Produce structured, concise summaries. Never invent medical facts. '
      'Never recommend specific doctors by name.';
}
