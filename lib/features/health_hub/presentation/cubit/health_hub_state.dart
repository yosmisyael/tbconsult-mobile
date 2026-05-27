import 'package:equatable/equatable.dart';

import 'package:TBConsult/features/health_hub/domain/entities/conversation.dart';

abstract class HealthHubState extends Equatable {
  const HealthHubState();

  @override
  List<Object?> get props => [];
}

class HealthHubInitial extends HealthHubState {
  const HealthHubInitial();
}

class HealthHubLoading extends HealthHubState {
  const HealthHubLoading();
}

class HealthHubLoaded extends HealthHubState {
  final List<Conversation> recentConversations;

  const HealthHubLoaded({required this.recentConversations});

  @override
  List<Object?> get props => [recentConversations];
}

class HealthHubError extends HealthHubState {
  final String message;

  const HealthHubError({required this.message});

  @override
  List<Object?> get props => [message];
}
