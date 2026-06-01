import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:TBConsult/features/health_hub/domain/entities/conversation.dart';
import 'package:TBConsult/features/health_hub/domain/entities/message.dart';
import 'package:TBConsult/features/health_hub/domain/entities/tb_knowledge_chunk.dart';
import 'package:TBConsult/features/health_hub/domain/entities/triage_response.dart';
import 'package:TBConsult/features/health_hub/domain/repositories/conversation_repository.dart';
import 'package:TBConsult/features/health_hub/domain/repositories/tb_knowledge_repository.dart';
import 'package:TBConsult/features/health_hub/domain/usecases/send_message_usecase.dart';

// ── Mock Dependencies ───────────────────────────────────────────────────────

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
    // Return general TB knowledge even for irrelevant images
    return [
      const TBKnowledgeChunk(
        id: 'chunk-1',
        category: TBKnowledgeCategory.symptoms,
        title: 'TB Symptoms',
        content: 'Common TB symptoms include persistent cough, fever, night sweats, and weight loss.',
        keywords: ['cough', 'fever', 'sweat', 'weight loss'],
      ),
      const TBKnowledgeChunk(
        id: 'chunk-2',
        category: TBKnowledgeCategory.emergencySigns,
        title: 'Image Analysis Limitations',
        content: 'AI image analysis for TB is limited. Chest X-rays require professional radiologist interpretation.',
        keywords: ['x-ray', 'image', 'analysis', 'radiologist'],
      ),
    ];
  }

  @override
  Future<List<TBKnowledgeChunk>> getAllChunks() async => [];

  @override
  Future<List<TBKnowledgeChunk>> getChunksByCategory(TBKnowledgeCategory category) async => [];
}

class CapturingTriageService implements TriageService {
  String? lastUserMessage;
  String? lastSystemPrompt;
  List<Map<String, String>>? lastHistory;
  String? lastSessionId;
  List<List<int>>? lastImagesBytes;

  @override
  Future<TriageResponse> sendMessage({
    required String userMessage,
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String sessionId,
    List<List<int>>? imagesBytes,
  }) async {
    lastUserMessage = userMessage;
    lastSystemPrompt = systemPrompt;
    lastHistory = history;
    lastSessionId = sessionId;
    lastImagesBytes = imagesBytes;

    // Simulate a response for an irrelevant image (fish in TB app)
    // The AI should note that the image is not TB-related
    final bool hasImages = imagesBytes != null && imagesBytes.isNotEmpty;
    String responseText;
    String riskLevel;
    List<String> redFlags;

    if (hasImages) {
      responseText =
          'Terima kasih telah mengirimkan gambar. Namun, gambar yang Anda kirimkan tampaknya bukan gambar medis yang relevan dengan pemeriksaan TB (Tuberkulosis).\n\n'
          'Untuk analisis gambar yang akurat terkait kondisi TB, saya membutuhkan:\n'
          '1. Foto hasil rontgen dada (chest X-ray) jika ada\n'
          '2. Foto dokumen medis terkait\n'
          '3. Atau deskripsikan gejala Anda secara detail\n\n'
          'Apakah Anda memiliki gejala seperti batuk berkepanjangan (>2-3 minggu), demam, berkeringat di malam hari, atau penurunan berat badan tanpa sebab?';
      riskLevel = 'Low';
      redFlags = [];
    } else {
      responseText = 'Please consult a doctor for proper TB evaluation.';
      riskLevel = 'Moderate';
      redFlags = ['cough'];
    }

    return TriageResponse(
      riskLevel: riskLevel,
      responseText: responseText,
      redFlags: redFlags,
      sources: const ['TB Symptoms', 'Image Analysis Guidelines'],
      sdui: hasImages
          ? {
              'components': [
                {
                  'type': 'button',
                  'label': 'Upload Chest X-Ray',
                  'action': 'upload_xray',
                },
                {
                  'type': 'button',
                  'label': 'Describe Symptoms',
                  'action': 'describe_symptoms',
                },
              ]
            }
          : null,
    );
  }

  @override
  Future<String> generateConversationSummary(List<Message> messages) async {
    return 'Summary: Patient sent an image for analysis.';
  }
}

void main() {
  late SendMessageUseCase useCase;
  late MockConversationRepository mockConversationRepository;
  late MockTBKnowledgeRepository mockTBKnowledgeRepository;
  late CapturingTriageService capturingTriageService;

  setUp(() {
    mockConversationRepository = MockConversationRepository();
    mockTBKnowledgeRepository = MockTBKnowledgeRepository();
    capturingTriageService = CapturingTriageService();
    useCase = SendMessageUseCase(
      conversationRepository: mockConversationRepository,
      knowledgeRepository: mockTBKnowledgeRepository,
      triageService: capturingTriageService,
    );
  });

  group('Triage Conversation with Fish Image (Test Credentials: gamissamir@gmail.com)', () {
    test(
        'should send fish image bytes to triage service and receive appropriate non-medical-image response',
        () async {
      // arrange: Simulate fish image bytes (irrelevant to TB)
      // In reality, this would be the bytes of the tuna fish image
      final fishImageBytes = List<int>.generate(1024, (index) => index % 256);
      final secondImageBytes = List<int>.generate(512, (index) => (index * 2) % 256);

      final params = SendMessageParams(
        conversationId: 'triage-test-fish-001',
        userMessage: 'What do you see in this image?',
        responseMessageId: 'resp-fish-001',
        conversationMessages: [],
        imagesBytes: [fishImageBytes, secondImageBytes],
      );

      // act
      final result = await useCase(params);

      // assert: Verify image bytes were passed to triage service
      expect(capturingTriageService.lastImagesBytes, isNotNull);
      expect(capturingTriageService.lastImagesBytes!.length, 2);
      expect(capturingTriageService.lastImagesBytes![0], equals(fishImageBytes));
      expect(capturingTriageService.lastImagesBytes![1], equals(secondImageBytes));

      // assert: Verify the service received the correct session and message
      expect(capturingTriageService.lastUserMessage, 'What do you see in this image?');
      expect(capturingTriageService.lastSessionId, 'triage-test-fish-001');

      // assert: Verify system prompt contains TB knowledge (even for irrelevant images)
      expect(
        capturingTriageService.lastSystemPrompt,
        contains('Tuberculosis'),
      );

      // assert: Verify assistant response is appropriate for non-medical image
      expect(result.id, 'resp-fish-001');
      expect(result.role, MessageRole.assistant);
      expect(result.riskLevel, 'Low');
      expect(result.redFlags, isEmpty);
      expect(result.isGrounded, true);
      expect(result.sources, contains('Image Analysis Guidelines'));

      // assert: Response should indicate image is not medically relevant
      expect(
        result.content.toLowerCase(),
        contains('gambar'),
        reason: 'Response should be in Indonesian noting the image issue',
      );

      // assert: SDUI should provide actionable next steps
      expect(result.sdui, isNotNull);
      expect(result.sdui!['components'], isA<List>());
      expect(result.sdui!['components'].length, 2);
      expect(result.sdui!['components'][0]['label'], 'Upload Chest X-Ray');

      // assert: Repository was updated
      expect(mockConversationRepository.appendedMessages.length, 1);
      expect(mockConversationRepository.appendedMessages.first, result);
    });

    test('should handle single fish image with empty prompt', () async {
      // arrange
      final fishImageBytes = List<int>.generate(2048, (index) => index % 256);

      final params = SendMessageParams(
        conversationId: 'triage-test-fish-002',
        userMessage: '', // Empty prompt, only image
        responseMessageId: 'resp-fish-002',
        conversationMessages: [],
        imagesBytes: [fishImageBytes],
      );

      // act
      final result = await useCase(params);

      // assert
      expect(capturingTriageService.lastImagesBytes, isNotNull);
      expect(capturingTriageService.lastImagesBytes!.length, 1);
      expect(result.riskLevel, 'Low');
      expect(result.content.isNotEmpty, true);
    });

    test('should include conversation history when sending fish image in ongoing conversation',
        () async {
      // arrange: Simulate an ongoing conversation with previous messages
      final previousMessages = [
        Message(
          id: 'msg-prev-1',
          conversationId: 'triage-test-fish-003',
          role: MessageRole.user,
          type: MessageType.text,
          content: 'I have been coughing for 2 weeks',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        Message(
          id: 'msg-prev-2',
          conversationId: 'triage-test-fish-003',
          role: MessageRole.assistant,
          type: MessageType.text,
          content: 'I understand. Any fever or night sweats?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
      ];

      final fishImageBytes = List<int>.generate(1024, (index) => index % 256);

      final params = SendMessageParams(
        conversationId: 'triage-test-fish-003',
        userMessage: 'Here is a photo',
        responseMessageId: 'resp-fish-003',
        conversationMessages: previousMessages,
        imagesBytes: [fishImageBytes],
      );

      // act
      final result = await useCase(params);

      // assert: Verify history was passed to triage service
      expect(capturingTriageService.lastHistory, isNotNull);
      expect(capturingTriageService.lastHistory!.length, 2);
      expect(capturingTriageService.lastHistory![0]['role'], 'user');
      expect(
        capturingTriageService.lastHistory![0]['content'],
        'I have been coughing for 2 weeks',
      );
      expect(capturingTriageService.lastHistory![1]['role'], 'model');
      expect(
        capturingTriageService.lastHistory![1]['content'],
        'I understand. Any fever or night sweats?',
      );

      // assert: Image bytes still passed
      expect(capturingTriageService.lastImagesBytes, isNotNull);
      expect(capturingTriageService.lastImagesBytes!.length, 1);

      // assert: Response acknowledges the conversation context
      expect(result.id, 'resp-fish-003');
    });
  });

  group('Triage Conversation Image Validation', () {
    test('should handle null imagesBytes gracefully', () async {
      // arrange
      final params = SendMessageParams(
        conversationId: 'triage-test-no-image',
        userMessage: 'I have a cough',
        responseMessageId: 'resp-no-image',
        conversationMessages: [],
        imagesBytes: null,
      );

      // act
      final result = await useCase(params);

      // assert
      expect(capturingTriageService.lastImagesBytes, isNull);
      expect(result.riskLevel, 'Moderate');
      expect(result.redFlags, isNotEmpty);
    });

    test('should handle empty imagesBytes list', () async {
      // arrange
      final params = SendMessageParams(
        conversationId: 'triage-test-empty-images',
        userMessage: 'I have a cough',
        responseMessageId: 'resp-empty-images',
        conversationMessages: [],
        imagesBytes: [],
      );

      // act
      final result = await useCase(params);

      // assert: Empty list should be treated as no images
      // The CapturingTriageService treats empty list as hasImages = false
      expect(capturingTriageService.lastImagesBytes, isNotNull);
      expect(capturingTriageService.lastImagesBytes!.isEmpty, true);
      expect(result.riskLevel, 'Moderate');
    });
  });

  group('Credentials Context Test', () {
    test('should verify test credentials format is valid', () {
      const email = 'gamissamir@gmail.com';
      const password = 'Password123!';

      // Validate email format
      expect(
        RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email),
        isTrue,
        reason: 'Test email should be valid format',
      );

      // Validate password meets minimum requirements
      expect(password.length, greaterThanOrEqualTo(6));
      expect(password.contains(RegExp(r'[A-Z]')), isTrue);
      expect(password.contains(RegExp(r'[0-9]')), isTrue);
      expect(password.contains(RegExp(r'[!@#$%^&*]')), isTrue);
    });
  });
}
