import 'package:TBConsult/core/usecases/usecase.dart';
import 'package:TBConsult/features/health_hub/domain/entities/conversation.dart';
import 'package:TBConsult/features/health_hub/domain/repositories/conversation_repository.dart';

class GetConversationDetailUseCase
    extends UseCase<Conversation?, String> {
  final ConversationRepository repository;

  GetConversationDetailUseCase(this.repository);

  @override
  Future<Conversation?> call(String conversationId) async {
    return repository.getConversationById(conversationId);
  }
}
