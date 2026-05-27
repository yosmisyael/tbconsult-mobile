import 'package:flutter_test/flutter_test.dart';
import 'package:TBConsult/features/health_hub/domain/entities/conversation.dart';
import 'package:TBConsult/features/health_hub/domain/entities/message.dart';
import 'package:TBConsult/features/health_hub/domain/entities/tb_knowledge_chunk.dart';
import 'package:TBConsult/features/health_hub/domain/entities/triage_response.dart';
import 'package:TBConsult/features/health_hub/domain/repositories/conversation_repository.dart';
import 'package:TBConsult/features/health_hub/domain/repositories/tb_knowledge_repository.dart';
import 'package:TBConsult/features/health_hub/domain/usecases/send_message_usecase.dart';

// Manual mock implementations for tests
class MockConversationRepository implements ConversationRepository {
  List<Message> appendedMessages = [];

  @override
  Future<void> appendMessage(String conversationId, Message message) async {
    appendedMessages.add(message);
  }

  @override
  Future<List<Conversation>> getRecentConversations({int limit = 10}) async => [];

  @override
  Future<Conversation?> getConversationById(String id) async => null;

  @override
  Future<void> saveConversation(Conversation conversation) async {}

  @override
  Future<void> updateConversationSummary(
    String conversationId,
    String summary,
    List<String> insights,
    List<String> recommendations,
  ) async {}

  @override
  Future<void> deleteConversation(String id) async {}
}

class MockTBKnowledgeRepository implements TBKnowledgeRepository {
  @override
  Future<List<TBKnowledgeChunk>> retrieveRelevantChunks(String query, {int topK = 3}) async {
    return [
      const TBKnowledgeChunk(
        id: 'chunk-1',
        category: TBKnowledgeCategory.symptoms,
        title: 'TB Symptoms',
        content: 'Common symptoms include cough and fever.',
        keywords: ['cough', 'fever'],
      ),
    ];
  }

  @override
  Future<List<TBKnowledgeChunk>> getAllChunks() async => [];

  @override
  Future<List<TBKnowledgeChunk>> getChunksByCategory(TBKnowledgeCategory category) async => [];
}

class MockTriageService implements TriageService {
  String? lastUserMessage;
  String? lastSystemPrompt;
  List<Map<String, String>>? lastHistory;
  String? lastSessionId;

  @override
  Future<TriageResponse> sendMessage({
    required String userMessage,
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String sessionId,
    List<int>? imageBytes,
  }) async {
    lastUserMessage = userMessage;
    lastSystemPrompt = systemPrompt;
    lastHistory = history;
    lastSessionId = sessionId;

    return const TriageResponse(
      riskLevel: 'Moderate',
      responseText: 'Please consult a doctor.',
      redFlags: ['cough'],
      sources: ['TB Symptoms'],
      sdui: {
        'components': [
          {'type': 'button', 'label': 'Action'}
        ]
      },
    );
  }

  @override
  Future<String> generateConversationSummary(List<Message> messages) async {
    return 'Summary text';
  }
}

void main() {
  late SendMessageUseCase useCase;
  late MockConversationRepository mockConversationRepository;
  late MockTBKnowledgeRepository mockTBKnowledgeRepository;
  late MockTriageService mockTriageService;

  setUp(() {
    mockConversationRepository = MockConversationRepository();
    mockTBKnowledgeRepository = MockTBKnowledgeRepository();
    mockTriageService = MockTriageService();
    useCase = SendMessageUseCase(
      conversationRepository: mockConversationRepository,
      knowledgeRepository: mockTBKnowledgeRepository,
      triageService: mockTriageService,
    );
  });

  test('should retrieve context, call service, and append message to repository', () async {
    // arrange
    const params = SendMessageParams(
      conversationId: 'conv-123',
      userMessage: 'I have a cough.',
      responseMessageId: 'res-456',
      conversationMessages: [],
    );

    // act
    final result = await useCase(params);

    // assert
    expect(result.id, 'res-456');
    expect(result.content, 'Please consult a doctor.');
    expect(result.role, MessageRole.assistant);
    expect(result.riskLevel, 'Moderate');
    expect(result.redFlags, const ['cough']);
    expect(result.sources, const ['TB Symptoms']);
    expect(result.isGrounded, true);
    expect(result.sdui?['components']?.first['type'], 'button');

    // Check repository was updated
    expect(mockConversationRepository.appendedMessages.length, 1);
    expect(mockConversationRepository.appendedMessages.first, result);

    // Check service parameters
    expect(mockTriageService.lastUserMessage, 'I have a cough.');
    expect(mockTriageService.lastSessionId, 'conv-123');
    expect(mockTriageService.lastSystemPrompt, contains('Common symptoms include cough and fever.'));
  });
}
