import 'package:TBConsult/core/usecases/usecase.dart';
import 'package:TBConsult/features/health_hub/domain/entities/conversation.dart';
import 'package:TBConsult/features/health_hub/domain/repositories/conversation_repository.dart';

class GetConversationsUseCase
    extends UseCase<List<Conversation>, GetConversationsParams> {
  final ConversationRepository repository;

  GetConversationsUseCase(this.repository);

  @override
  Future<List<Conversation>> call(GetConversationsParams params) async {
    return repository.getRecentConversations(limit: params.limit);
  }
}

class GetConversationsParams {
  final int limit;

  const GetConversationsParams({this.limit = 10});
}
