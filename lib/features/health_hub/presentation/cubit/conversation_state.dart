import 'package:equatable/equatable.dart';

import 'package:TBConsult/features/health_hub/domain/entities/conversation.dart';

abstract class ConversationState extends Equatable {
  final Conversation? conversation;

  const ConversationState({this.conversation});

  @override
  List<Object?> get props => [conversation];
}

class ConversationInitial extends ConversationState {
  const ConversationInitial();
}

class ConversationReady extends ConversationState {
  const ConversationReady({required Conversation conversation})
    : super(conversation: conversation);
}

class ConversationMessaging extends ConversationState {
  final bool isWaitingForResponse;
  final bool isListening;
  final bool isTranscribing;

  const ConversationMessaging({
    required Conversation conversation,
    this.isWaitingForResponse = false,
    this.isListening = false,
    this.isTranscribing = false,
  }) : super(conversation: conversation);

  @override
  List<Object?> get props => [
    conversation,
    isWaitingForResponse,
    isListening,
    isTranscribing,
  ];
}

class ConversationSummarizing extends ConversationState {
  const ConversationSummarizing({required Conversation conversation})
    : super(conversation: conversation);
}

class ConversationSummarized extends ConversationState {
  const ConversationSummarized({required Conversation conversation})
    : super(conversation: conversation);
}

class ConversationError extends ConversationState {
  final String message;

  const ConversationError({super.conversation, required this.message});

  @override
  List<Object?> get props => [conversation, message];
}
