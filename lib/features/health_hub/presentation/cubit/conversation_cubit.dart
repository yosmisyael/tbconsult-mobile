import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:TBConsult/features/health_hub/domain/entities/conversation.dart';
import 'package:TBConsult/features/health_hub/domain/entities/message.dart';
import 'package:TBConsult/features/health_hub/domain/usecases/send_message_usecase.dart';
import 'package:TBConsult/features/health_hub/domain/usecases/save_conversation_usecase.dart';
import 'package:TBConsult/features/health_hub/domain/usecases/get_conversation_detail_usecase.dart';
import 'package:TBConsult/features/health_hub/domain/usecases/generate_summary_usecase.dart';
import 'conversation_state.dart';

class ConversationCubit extends Cubit<ConversationState> {
  final SendMessageUseCase sendMessageUseCase;
  final SaveConversationUseCase saveConversationUseCase;
  final GetConversationDetailUseCase getConversationDetailUseCase;
  final GenerateSummaryUseCase generateSummaryUseCase;

  static const _uuid = Uuid();

  ConversationCubit({
    required this.sendMessageUseCase,
    required this.saveConversationUseCase,
    required this.getConversationDetailUseCase,
    required this.generateSummaryUseCase,
  }) : super(const ConversationInitial());

  // ── Lifecycle ──────────────────────────────────────────────────────────

  Future<void> startNewConversation() async {
    final now = DateTime.now();
    final conversation = Conversation(
      id: _uuid.v4(),
      title: 'New Conversation',
      startedAt: now,
      lastMessageAt: now,
    );

    emit(ConversationReady(conversation: conversation));
  }

  Future<void> loadExistingConversation(String conversationId) async {
    try {
      final conversation = await getConversationDetailUseCase(conversationId);
      if (conversation != null) {
        if (conversation.hasSummary) {
          emit(ConversationSummarized(conversation: conversation));
        } else {
          emit(ConversationReady(conversation: conversation));
        }
      } else {
        emit(const ConversationError(message: 'Conversation not found'));
      }
    } catch (e) {
      emit(ConversationError(message: e.toString()));
    }
  }

  // ── Messaging ──────────────────────────────────────────────────────────

  Future<void> sendTextMessage(String text) async {
    final conversation = state.conversation;
    if (conversation == null || text.trim().isEmpty) return;

    // Guard against rapid double-tap sending parallel messages
    if (state is ConversationMessaging &&
        (state as ConversationMessaging).isWaitingForResponse) {
      return;
    }

    final userMessage = Message(
      id: _uuid.v4(),
      conversationId: conversation.id,
      role: MessageRole.user,
      type: MessageType.text,
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    // Update title from first user message
    final updatedTitle = conversation.messages.isEmpty
        ? _generateTitle(text)
        : conversation.title;

    final withUserMsg = conversation.copyWith(
      title: updatedTitle,
      lastMessageAt: userMessage.timestamp,
      messages: [...conversation.messages, userMessage],
    );

    // Save user message immediately (crash safety)
    await saveConversationUseCase(withUserMsg);

    emit(
      ConversationMessaging(
        conversation: withUserMsg,
        isWaitingForResponse: true,
      ),
    );

    try {
      final responseId = _uuid.v4();
      final assistantMessage = await sendMessageUseCase(
        SendMessageParams(
          conversationId: conversation.id,
          userMessage: text.trim(),
          responseMessageId: responseId,
          conversationMessages: conversation.messages,
        ),
      );

      final withBotMsg = withUserMsg.copyWith(
        lastMessageAt: assistantMessage.timestamp,
        messages: [...withUserMsg.messages, assistantMessage],
      );

      await saveConversationUseCase(withBotMsg);
      emit(ConversationMessaging(conversation: withBotMsg));
    } catch (e) {
      emit(
        ConversationError(
          conversation: withUserMsg,
          message: 'Failed: ${e.toString().replaceAll('Exception: ', '')}',
        ),
      );
    }
  }

  Future<void> editAndResendLatestMessage(String text) async {
    final conversation = state.conversation;
    if (conversation == null || text.trim().isEmpty) return;

    if (state is ConversationMessaging &&
        (state as ConversationMessaging).isWaitingForResponse) {
      return;
    }

    final messages = List<Message>.from(conversation.messages);

    // Find last user message index
    int lastUserIndex = -1;
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == MessageRole.user) {
        lastUserIndex = i;
        break;
      }
    }

    if (lastUserIndex == -1) return;

    final subList = messages.sublist(0, lastUserIndex);

    final userMessage = Message(
      id: _uuid.v4(),
      conversationId: conversation.id,
      role: MessageRole.user,
      type: MessageType.text,
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    final updatedTitle = subList.isEmpty
        ? _generateTitle(text)
        : conversation.title;

    final withUserMsg = conversation.copyWith(
      title: updatedTitle,
      lastMessageAt: userMessage.timestamp,
      messages: [...subList, userMessage],
    );

    await saveConversationUseCase(withUserMsg);

    emit(
      ConversationMessaging(
        conversation: withUserMsg,
        isWaitingForResponse: true,
      ),
    );

    try {
      final responseId = _uuid.v4();
      final assistantMessage = await sendMessageUseCase(
        SendMessageParams(
          conversationId: conversation.id,
          userMessage: text.trim(),
          responseMessageId: responseId,
          conversationMessages: subList,
        ),
      );

      final withBotMsg = withUserMsg.copyWith(
        lastMessageAt: assistantMessage.timestamp,
        messages: [...withUserMsg.messages, assistantMessage],
      );

      await saveConversationUseCase(withBotMsg);
      emit(ConversationMessaging(conversation: withBotMsg));
    } catch (e) {
      emit(
        ConversationError(
          conversation: withUserMsg,
          message: 'Failed: ${e.toString().replaceAll('Exception: ', '')}',
        ),
      );
    }
  }

  Future<void> sendImageMessage(List<File> images, {String? prompt}) async {
    final conversation = state.conversation;
    if (conversation == null) return;

    final String finalPrompt =
        prompt ??
        'What do you see in this image? Analyze it for any TB-related health concerns.';

    final userMessage = Message(
      id: _uuid.v4(),
      conversationId: conversation.id,
      role: MessageRole.user,
      type: MessageType.image,
      content: '${images.map((e) => e.path).join(',')}|$finalPrompt',
      timestamp: DateTime.now(),
    );

    final withUserMsg = conversation.copyWith(
      lastMessageAt: userMessage.timestamp,
      messages: [...conversation.messages, userMessage],
    );

    await saveConversationUseCase(withUserMsg);

    emit(
      ConversationMessaging(
        conversation: withUserMsg,
        isWaitingForResponse: true,
      ),
    );

    try {
      final List<List<int>> imageBytesList = [];
      for (var img in images) {
        imageBytesList.add(await img.readAsBytes());
      }
      final responseId = _uuid.v4();
      final assistantMessage = await sendMessageUseCase(
        SendMessageParams(
          conversationId: conversation.id,
          userMessage: finalPrompt,
          responseMessageId: responseId,
          conversationMessages: conversation.messages,
          imagesBytes: imageBytesList,
        ),
      );

      final withBotMsg = withUserMsg.copyWith(
        lastMessageAt: assistantMessage.timestamp,
        messages: [...withUserMsg.messages, assistantMessage],
      );

      await saveConversationUseCase(withBotMsg);
      emit(ConversationMessaging(conversation: withBotMsg));
    } catch (e) {
      emit(
        ConversationError(
          conversation: withUserMsg,
          message: 'Failed to analyze image. Please try again.',
        ),
      );
    }
  }

  // ── Speech-to-Text ────────────────────────────────────────────────────

  void startListening() {
    final conversation = state.conversation;
    if (conversation == null) return;
    emit(ConversationMessaging(conversation: conversation, isListening: true));
  }

  void stopListening() {
    final conversation = state.conversation;
    if (conversation == null) return;
    emit(
      ConversationMessaging(conversation: conversation, isTranscribing: true),
    );
  }

  void finishTranscription() {
    final conversation = state.conversation;
    if (conversation == null) return;
    emit(ConversationMessaging(conversation: conversation));
  }

  // ── Summary ────────────────────────────────────────────────────────────

  Future<void> generateSummary() async {
    final conversation = state.conversation;
    if (conversation == null || conversation.messages.length < 2) return;

    emit(ConversationSummarizing(conversation: conversation));

    try {
      final summarized = await generateSummaryUseCase(
        GenerateSummaryParams(conversationId: conversation.id),
      );
      emit(ConversationSummarized(conversation: summarized));
    } catch (e) {
      emit(
        ConversationError(
          conversation: conversation,
          message: 'Failed to generate summary.',
        ),
      );
    }
  }

  // ── Save on exit ───────────────────────────────────────────────────────

  Future<void> saveBeforeExit() async {
    final conversation = state.conversation;
    if (conversation != null && conversation.messages.isNotEmpty) {
      await saveConversationUseCase(conversation);
    }
  }

  // ── Private ────────────────────────────────────────────────────────────

  String _generateTitle(String firstMessage) {
    final trimmed = firstMessage.trim();
    if (trimmed.length <= 40) return trimmed;
    return '${trimmed.substring(0, 37)}...';
  }
}
