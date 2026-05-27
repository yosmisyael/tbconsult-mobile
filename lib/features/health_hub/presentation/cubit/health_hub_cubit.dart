import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:TBConsult/features/health_hub/domain/usecases/get_conversations_usecase.dart';
import 'package:TBConsult/features/health_hub/domain/repositories/conversation_repository.dart';
import 'health_hub_state.dart';

class HealthHubCubit extends Cubit<HealthHubState> {
  final GetConversationsUseCase getConversations;
  final ConversationRepository conversationRepository;

  HealthHubCubit({
    required this.getConversations,
    required this.conversationRepository,
  }) : super(const HealthHubInitial());

  Future<void> loadRecentConversations() async {
    emit(const HealthHubLoading());
    try {
      final conversations = await getConversations(
        const GetConversationsParams(limit: 10),
      );
      emit(HealthHubLoaded(recentConversations: conversations));
    } catch (e) {
      emit(HealthHubError(message: e.toString()));
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      await conversationRepository.deleteConversation(id);
      await loadRecentConversations();
    } catch (e) {
      emit(HealthHubError(message: e.toString()));
    }
  }

  void refresh() => loadRecentConversations();
}
