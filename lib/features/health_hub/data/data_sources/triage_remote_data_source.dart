import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import 'package:TBConsult/features/health_hub/domain/entities/message.dart';
import 'package:TBConsult/features/health_hub/domain/entities/triage_response.dart';
import 'package:TBConsult/features/health_hub/domain/usecases/send_message_usecase.dart';

class TriageRemoteDataSource implements TriageService {
  final String apiKey;
  final SharedPreferences prefs;

  GenerativeModel? _geminiModel;
  ChatSession? _geminiChatSession;

  TriageRemoteDataSource({required this.apiKey, required this.prefs});

  // ── Backend URL & Authentication ────────────────────────────────────────

  String _getBackendUrl() {
    final baseUrl =
        dotenv.env['BACKEND_BASE_URL'] ?? 'http://localhost:8000/v1';
    var url = baseUrl;
    if (!kIsWeb && Platform.isAndroid) {
      if (url.contains('localhost')) {
        url = url.replaceAll('localhost', '10.0.2.2');
      }
      if (url.contains('127.0.0.1')) {
        url = url.replaceAll('127.0.0.1', '10.0.2.2');
      }
    }
    // Strip trailing slash to prevent double slashes when concatenating paths
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Future<String> _getAccessToken() async {
    final token = prefs.getString('backend_jwt_token');
    if (token != null) {
      return token;
    }
    throw const HttpException('No active session token found');
  }

  // ── Triage Chat Message ──────────────────────────────────────────────────

  Future<Position?> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('TriageRemoteDataSource: Location permission denied');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('TriageRemoteDataSource: Location permission denied forever');
        return null;
      }

      // Try last known position first (instantaneous)
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          debugPrint('TriageRemoteDataSource: Using last known location: ${lastKnown.latitude}, ${lastKnown.longitude}');
          return lastKnown;
        }
      } catch (e) {
        debugPrint('TriageRemoteDataSource: getLastKnownPosition error: $e');
      }

      // Fallback to active current location lookup
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('TriageRemoteDataSource: _getUserLocation error: $e');
      return null;
    }
  }

  @override
  Future<TriageResponse> sendMessage({
    required String userMessage,
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String sessionId,
    List<List<int>>? imagesBytes,
  }) async {
    try {
      final backendUrl = _getBackendUrl();
      final token = await _getAccessToken();

      final chatUri = Uri.parse('$backendUrl/triage/chat');

      double? lat;
      double? lng;
      try {
        final pos = await _getUserLocation();
        if (pos != null) {
          lat = pos.latitude;
          lng = pos.longitude;
          debugPrint('TriageRemoteDataSource: Location fetched: $lat, $lng');
        } else {
          debugPrint('TriageRemoteDataSource: Location fetched was null');
        }
      } catch (e) {
        debugPrint('TriageRemoteDataSource: location fetch error: $e');
      }

      // Encode images as base64 strings for the backend to analyze
      final List<String>? base64Images = imagesBytes?.map(
        (bytes) => base64Encode(bytes),
      ).toList();

      final response = await http
          .post(
            chatUri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'session_id': sessionId,
              'message': userMessage,
              'history': history,
              'latitude':? lat,
              'longitude':? lng,
              if (base64Images != null && base64Images.isNotEmpty)
                'images': base64Images,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 401) {
        throw const HttpException('Unauthorized');
      }

      if (response.statusCode == 200) {
        return _parseTriageResponse(utf8.decode(response.bodyBytes));
      } else {
        throw HttpException(
          'Backend triage request failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint(
        'TriageRemoteDataSource: Backend call failed ($e). Falling back to direct Gemini...',
      );
      try {
        return await _sendGeminiFallback(
          userMessage: userMessage,
          systemPrompt: systemPrompt,
          history: history,
          imagesBytes: imagesBytes,
        );
      } catch (geminiError) {
        debugPrint(
          'TriageRemoteDataSource: Gemini fallback also failed ($geminiError). Using local response.',
        );
        return _localFallbackResponse(userMessage);
      }
    }
  }

  TriageResponse _parseTriageResponse(String body) {
    try {
      final Map<String, dynamic> json = jsonDecode(body);
      return TriageResponse(
        riskLevel: json['risk_level'] as String? ?? '',
        responseText: json['response_text'] as String? ?? '',
        redFlags:
            (json['red_flags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        sources:
            (json['sources'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        sdui: json['sdui'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint(
        'TriageRemoteDataSource: Failed to parse triage response: $e. Body: $body',
      );
      rethrow;
    }
  }

  Future<TriageResponse> _sendGeminiFallback({
    required String userMessage,
    required String systemPrompt,
    required List<Map<String, String>> history,
    List<List<int>>? imagesBytes,
  }) async {
    _geminiModel = GenerativeModel(
      model: 'gemini-2.5-flash',
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
    if (imagesBytes != null && imagesBytes.isNotEmpty) {
      for (final bytes in imagesBytes) {
        parts.add(DataPart('image/jpeg', Uint8List.fromList(bytes)));
      }
    }

    final response = await _geminiChatSession!.sendMessage(
      Content.multi(parts),
    );
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
    if (lower.contains('halo') ||
        lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('selamat')) {
      responseText =
          'Halo! Saya TBConsult, asisten kesehatan untuk pasien TB. '
          'Maaf, saat ini saya sedang mengalami gangguan koneksi. '
          'Silakan coba lagi nanti atau hubungi petugas kesehatan Anda untuk bantuan lebih lanjut.';
    } else if (lower.contains('sakit') ||
        lower.contains('nyeri') ||
        lower.contains('demam')) {
      responseText =
          'Saya mengerti Anda sedang mengalami gejala yang tidak nyaman. '
          'Mohon segera konsultasikan dengan dokter atau petugas kesehatan Anda untuk penanganan yang tepat. '
          'Jika Anda mengalami gejala darurat seperti sesak nafas berat atau batuk darah, segera kunjungi fasilitas kesehatan terdekat.';
    } else if (lower.contains('obat') ||
        lower.contains('medication') ||
        lower.contains('dosis')) {
      responseText =
          'Untuk pertanyaan tentang obat dan dosis, sangat penting untuk berkonsultasi langsung dengan dokter atau petugas kesehatan Anda. '
          'Mereka memiliki informasi lengkap tentang riwayat pengobatan Anda dan dapat memberikan saran yang tepat.';
    } else {
      responseText =
          'Maaf, saya sedang mengalami gangguan koneksi dengan layanan AI saya. '
          'Silakan coba lagi nanti. Jika Anda memerlukan bantuan segera, '
          'jangan ragu untuk menghubungi petugas kesehatan atau fasilitas kesehatan terdekat.\n\n'
          'Saya sarankan untuk berkonsultasi dengan dokter atau petugas kesehatan Anda untuk pertanyaan ini.';
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
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_summarySystemPrompt),
    );

    final conversationText = messages
        .map((m) {
          final role = m.role == MessageRole.user ? 'Patient' : 'TBConsult';
          return '$role: ${m.content}';
        })
        .join('\n');

    final prompt =
        '''Analyze this TB patient conversation and provide a structured summary.

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
