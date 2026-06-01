import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:TBConsult/features/health_hub/domain/entities/message.dart';

class GeminiRemoteDataSource {
  final String apiKey;
  GenerativeModel? _model;
  ChatSession? _chatSession;

  GeminiRemoteDataSource({required this.apiKey});

  GenerativeModel _getModel(String systemPrompt) {
    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(systemPrompt),
    );
  }

  Future<String> sendMessage({
    required String userMessage,
    required String systemPrompt,
    required List<Map<String, String>> history,
    List<int>? imageBytes,
  }) async {
    // Recreate model with updated system prompt (includes RAG context)
    _model = _getModel(systemPrompt);

    // Reconstruct chat history for multi-turn context
    final historyContent = history.map((m) {
      final role = m['role'] == 'user' ? 'user' : 'model';
      return Content(role, [TextPart(m['content'] ?? '')]);
    }).toList();

    _chatSession = _model!.startChat(history: historyContent);

    // Build content parts
    final List<Part> parts = [TextPart(userMessage)];

    if (imageBytes != null && imageBytes.isNotEmpty) {
      parts.add(DataPart('image/jpeg', Uint8List.fromList(imageBytes)));
    }

    final response = await _chatSession!.sendMessage(
      Content.multi(parts),
    );

    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    return text;
  }

  Future<String> generateConversationSummary(List<Message> messages) async {
    final model = _getModel(_summarySystemPrompt);

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
