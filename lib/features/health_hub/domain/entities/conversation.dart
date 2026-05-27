import 'package:equatable/equatable.dart';

import 'message.dart';

class Conversation extends Equatable {
  final String id;
  final String title;
  final DateTime startedAt;
  final DateTime lastMessageAt;
  final List<Message> messages;
  final String? summaryText;
  final List<String> keyInsights;
  final List<String> recommendations;

  const Conversation({
    required this.id,
    required this.title,
    required this.startedAt,
    required this.lastMessageAt,
    this.messages = const [],
    this.summaryText,
    this.keyInsights = const [],
    this.recommendations = const [],
  });

  bool get hasSummary => summaryText != null;

  Message? get lastMessage => messages.isEmpty ? null : messages.last;

  Conversation copyWith({
    String? id,
    String? title,
    DateTime? startedAt,
    DateTime? lastMessageAt,
    List<Message>? messages,
    String? summaryText,
    List<String>? keyInsights,
    List<String>? recommendations,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      startedAt: startedAt ?? this.startedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messages: messages ?? this.messages,
      summaryText: summaryText ?? this.summaryText,
      keyInsights: keyInsights ?? this.keyInsights,
      recommendations: recommendations ?? this.recommendations,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        startedAt,
        lastMessageAt,
        messages,
        summaryText,
        keyInsights,
        recommendations,
      ];
}
