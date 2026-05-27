import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant }

enum MessageType { text, image }

class Message extends Equatable {
  final String id;
  final String conversationId;
  final MessageRole role;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final bool isGrounded;
  
  // Rich triage response fields (backend integration)
  final String? riskLevel;
  final List<String>? redFlags;
  final List<String>? sources;
  final Map<String, dynamic>? sdui;

  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.type,
    required this.content,
    required this.timestamp,
    this.isGrounded = false,
    this.riskLevel,
    this.redFlags,
    this.sources,
    this.sdui,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    MessageType? type,
    String? content,
    DateTime? timestamp,
    bool? isGrounded,
    String? riskLevel,
    List<String>? redFlags,
    List<String>? sources,
    Map<String, dynamic>? sdui,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isGrounded: isGrounded ?? this.isGrounded,
      riskLevel: riskLevel ?? this.riskLevel,
      redFlags: redFlags ?? this.redFlags,
      sources: sources ?? this.sources,
      sdui: sdui ?? this.sdui,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        role,
        type,
        content,
        timestamp,
        isGrounded,
        riskLevel,
        redFlags,
        sources,
        sdui,
      ];
}

