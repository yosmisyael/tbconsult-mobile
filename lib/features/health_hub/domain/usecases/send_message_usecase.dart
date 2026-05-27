import 'package:equatable/equatable.dart';
import 'package:TBConsult/features/health_hub/domain/entities/triage_response.dart';
import 'package:TBConsult/core/usecases/usecase.dart';
import 'package:TBConsult/features/health_hub/domain/entities/message.dart';
import 'package:TBConsult/features/health_hub/domain/entities/tb_knowledge_chunk.dart';
import 'package:TBConsult/features/health_hub/domain/repositories/conversation_repository.dart';
import 'package:TBConsult/features/health_hub/domain/repositories/tb_knowledge_repository.dart';

class SendMessageUseCase extends UseCase<Message, SendMessageParams> {
  final ConversationRepository conversationRepository;
  final TBKnowledgeRepository knowledgeRepository;
  final TriageService triageService;

  SendMessageUseCase({
    required this.conversationRepository,
    required this.knowledgeRepository,
    required this.triageService,
  });

  @override
  Future<Message> call(SendMessageParams params) async {
    // 1. Retrieve relevant TB context via keyword matching
    final chunks = await knowledgeRepository.retrieveRelevantChunks(
      params.userMessage,
      topK: 3,
    );

    // 2. Compose system prompt with injected knowledge (fallback context)
    final systemPrompt = _composeSystemPrompt(chunks);

    // 3. Build message history for triage context
    final history = params.conversationMessages
        .map((m) => {
              'role': m.role == MessageRole.user ? 'user' : 'model',
              'content': m.content,
            })
        .toList();

    // 4. Call Triage Service (backend)
    final triageResponse = await triageService.sendMessage(
      userMessage: params.userMessage,
      systemPrompt: systemPrompt,
      history: history,
      sessionId: params.conversationId,
      imageBytes: params.imageBytes,
    );

    // 5. Create the assistant Message entity with rich backend details
    final assistantMessage = Message(
      id: params.responseMessageId,
      conversationId: params.conversationId,
      role: MessageRole.assistant,
      type: MessageType.text,
      content: triageResponse.responseText,
      timestamp: DateTime.now(),
      isGrounded: triageResponse.sources.isNotEmpty,
      riskLevel: triageResponse.riskLevel,
      redFlags: triageResponse.redFlags,
      sources: triageResponse.sources,
      sdui: triageResponse.sdui,
    );

    // 6. Persist
    await conversationRepository.appendMessage(
      params.conversationId,
      assistantMessage,
    );

    return assistantMessage;
  }

  String _composeSystemPrompt(List<TBKnowledgeChunk> chunks) {
    const base = '''You are TBConsult, a friendly and empathetic AI assistant for tuberculosis (TB) patients.

STRICT RULES:
1. ONLY use the TB clinical facts provided below. Do NOT invent dosages, drug names, or treatment protocols.
2. If a question falls outside the provided knowledge, say: "Saya sarankan untuk berkonsultasi dengan dokter atau petugas DOTS Anda untuk pertanyaan ini."
3. Never recommend specific doctors by name.
4. Always remind patients that TBConsult supplements — never replaces — their healthcare provider.
5. Keep responses concise (2-3 paragraphs max), supportive, and in the language the patient uses.
6. For emergency signs (hemoptysis, severe hepatotoxicity symptoms), always advise going to the nearest health facility immediately.''';

    if (chunks.isEmpty) return base;

    final context =
        chunks.map((c) => '### ${c.title}\n${c.content}').join('\n\n');
    return '$base\n\n## Relevant TB Medical Knowledge:\n$context';
  }
}

/// Abstract interface for remote Triage and Gemini calls — implemented in data layer.
abstract class TriageService {
  Future<TriageResponse> sendMessage({
    required String userMessage,
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String sessionId,
    List<int>? imageBytes,
  });

  Future<String> generateConversationSummary(List<Message> messages);
}

class SendMessageParams extends Equatable {
  final String conversationId;
  final String userMessage;
  final String responseMessageId;
  final List<Message> conversationMessages;
  final List<int>? imageBytes;

  const SendMessageParams({
    required this.conversationId,
    required this.userMessage,
    required this.responseMessageId,
    required this.conversationMessages,
    this.imageBytes,
  });

  @override
  List<Object?> get props => [
        conversationId,
        userMessage,
        responseMessageId,
        conversationMessages,
        imageBytes,
      ];
}

