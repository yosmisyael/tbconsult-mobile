import 'package:TBConsult/core/usecases/usecase.dart';
import 'package:TBConsult/features/health_hub/domain/entities/conversation.dart';
import 'package:TBConsult/features/health_hub/domain/repositories/conversation_repository.dart';

class SaveConversationUseCase extends UseCase<void, Conversation> {
  final ConversationRepository repository;

  SaveConversationUseCase(this.repository);

  @override
  Future<void> call(Conversation conversation) async {
    return repository.saveConversation(conversation);
  }
}
