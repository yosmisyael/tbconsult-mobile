import 'package:TBConsult/features/health_hub/domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.role,
    required super.type,
    required super.content,
    required super.timestamp,
    super.isGrounded,
    super.riskLevel,
    super.redFlags,
    super.sources,
    super.sdui,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      role: MessageRole.values.byName(json['role'] as String),
      type: MessageType.values.byName(json['type'] as String),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isGrounded: json['isGrounded'] as bool? ?? false,
      riskLevel: json['riskLevel'] as String?,
      redFlags: (json['redFlags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      sources: (json['sources'] as List<dynamic>?)?.map((e) => e as String).toList(),
      sdui: json['sdui'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'role': role.name,
      'type': type.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isGrounded': isGrounded,
      'riskLevel': riskLevel,
      'redFlags': redFlags,
      'sources': sources,
      'sdui': sdui,
    };
  }

  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      conversationId: message.conversationId,
      role: message.role,
      type: message.type,
      content: message.content,
      timestamp: message.timestamp,
      isGrounded: message.isGrounded,
      riskLevel: message.riskLevel,
      redFlags: message.redFlags,
      sources: message.sources,
      sdui: message.sdui,
    );
  }
}

