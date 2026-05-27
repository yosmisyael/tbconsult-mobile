import 'package:TBConsult/features/health_hub/domain/entities/conversation.dart';
import 'package:TBConsult/features/health_hub/domain/entities/message.dart';

abstract class ConversationRepository {
  Future<List<Conversation>> getRecentConversations({int limit = 10});
  Future<Conversation?> getConversationById(String id);
  Future<void> saveConversation(Conversation conversation);
  Future<void> appendMessage(String conversationId, Message message);
  Future<void> updateConversationSummary(
    String conversationId,
    String summary,
    List<String> insights,
    List<String> recommendations,
  );
  Future<void> deleteConversation(String id);
}
