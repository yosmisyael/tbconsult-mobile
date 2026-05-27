import 'package:TBConsult/features/health_hub/data/data_sources/conversation_local_data_source.dart';
import 'package:TBConsult/features/health_hub/data/models/conversation_model.dart';
import 'package:TBConsult/features/health_hub/data/models/message_model.dart';
import 'package:TBConsult/features/health_hub/domain/entities/conversation.dart';
import 'package:TBConsult/features/health_hub/domain/entities/message.dart';
import 'package:TBConsult/features/health_hub/domain/repositories/conversation_repository.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  final ConversationLocalDataSource localDataSource;

  ConversationRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Conversation>> getRecentConversations({int limit = 10}) async {
    return localDataSource.getRecentConversations(limit: limit);
  }

  @override
  Future<Conversation?> getConversationById(String id) async {
    return localDataSource.getConversationById(id);
  }

  @override
  Future<void> saveConversation(Conversation conversation) async {
    final model = ConversationModel.fromEntity(conversation);
    await localDataSource.saveConversation(model);
  }

  @override
  Future<void> appendMessage(String conversationId, Message message) async {
    final model = MessageModel.fromEntity(message);
    await localDataSource.appendMessage(conversationId, model);
  }

  @override
  Future<void> updateConversationSummary(
    String conversationId,
    String summary,
    List<String> insights,
    List<String> recommendations,
  ) async {
    await localDataSource.updateConversationSummary(
      conversationId,
      summary,
      insights,
      recommendations,
    );
  }

  @override
  Future<void> deleteConversation(String id) async {
    await localDataSource.deleteConversation(id);
  }
}
