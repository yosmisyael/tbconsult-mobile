import 'package:TBConsult/features/health_hub/data/models/message_model.dart';
import 'package:TBConsult/features/health_hub/domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.title,
    required super.startedAt,
    required super.lastMessageAt,
    super.messages,
    super.summaryText,
    super.keyInsights,
    super.recommendations,
  });

  /// Full deserialization including messages.
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final messagesList = (json['messages'] as List<dynamic>?)
            ?.map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];

    return ConversationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      messages: messagesList,
      summaryText: json['summaryText'] as String?,
      keyInsights: (json['keyInsights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Full serialization including messages.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startedAt': startedAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'messages': messages
          .map((m) => MessageModel.fromEntity(m).toJson())
          .toList(),
      'summaryText': summaryText,
      'keyInsights': keyInsights,
      'recommendations': recommendations,
    };
  }

  /// Metadata-only serialization for the conversation index.
  /// Does NOT include messages — used for O(1) hub page loads.
  Map<String, dynamic> toIndexJson() {
    return {
      'id': id,
      'title': title,
      'startedAt': startedAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'hasSummary': hasSummary,
      'messageCount': messages.length,
      'lastMessagePreview': lastMessage?.content ?? '',
    };
  }

  /// Metadata-only deserialization from the conversation index.
  factory ConversationModel.fromIndexJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
    );
  }

  factory ConversationModel.fromEntity(Conversation conversation) {
    return ConversationModel(
      id: conversation.id,
      title: conversation.title,
      startedAt: conversation.startedAt,
      lastMessageAt: conversation.lastMessageAt,
      messages: conversation.messages,
      summaryText: conversation.summaryText,
      keyInsights: conversation.keyInsights,
      recommendations: conversation.recommendations,
    );
  }
}
