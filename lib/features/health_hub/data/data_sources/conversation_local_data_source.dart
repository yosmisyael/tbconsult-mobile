import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:TBConsult/features/health_hub/data/models/conversation_model.dart';
import 'package:TBConsult/features/health_hub/data/models/message_model.dart';

abstract class ConversationLocalDataSource {
  Future<List<ConversationModel>> getRecentConversations({int limit = 10});
  Future<ConversationModel?> getConversationById(String id);
  Future<void> saveConversation(ConversationModel conversation);
  Future<void> appendMessage(String conversationId, MessageModel message);
  Future<void> updateConversationSummary(
    String conversationId,
    String summary,
    List<String> insights,
    List<String> recommendations,
  );
  Future<void> deleteConversation(String id);
}

class ConversationLocalDataSourceImpl implements ConversationLocalDataSource {
  final SharedPreferences prefs;

  static const _indexKey = 'conversationIndex';
  static String _detailKey(String id) => 'conversation_$id';

  ConversationLocalDataSourceImpl({required this.prefs});

  // ── Index helpers ──────────────────────────────────────────────────────

  List<Map<String, dynamic>> _readIndex() {
    final raw = prefs.getString(_indexKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> _writeIndex(List<Map<String, dynamic>> index) async {
    await prefs.setString(_indexKey, jsonEncode(index));
  }

  // ── Public API ─────────────────────────────────────────────────────────

  @override
  Future<List<ConversationModel>> getRecentConversations({
    int limit = 10,
  }) async {
    final index = _readIndex();

    // Sort by lastMessageAt descending
    index.sort((a, b) {
      final aDate = DateTime.parse(a['lastMessageAt'] as String);
      final bDate = DateTime.parse(b['lastMessageAt'] as String);
      return bDate.compareTo(aDate);
    });

    final limited = index.take(limit);
    return limited.map((e) => ConversationModel.fromIndexJson(e)).toList();
  }

  @override
  Future<ConversationModel?> getConversationById(String id) async {
    final raw = prefs.getString(_detailKey(id));
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return ConversationModel.fromJson(json);
  }

  @override
  Future<void> saveConversation(ConversationModel conversation) async {
    // 1. Persist full conversation detail
    final json = conversation.toJson();
    await prefs.setString(_detailKey(conversation.id), jsonEncode(json));

    // 2. Update index
    final index = _readIndex();
    final existingIdx = index.indexWhere((e) => e['id'] == conversation.id);
    final indexEntry = conversation.toIndexJson();

    if (existingIdx >= 0) {
      index[existingIdx] = indexEntry;
    } else {
      index.add(indexEntry);
    }

    await _writeIndex(index);
  }

  @override
  Future<void> appendMessage(
    String conversationId,
    MessageModel message,
  ) async {
    final conversation = await getConversationById(conversationId);
    if (conversation == null) return;

    final updatedMessages = [...conversation.messages, message];
    final updated = ConversationModel(
      id: conversation.id,
      title: conversation.title,
      startedAt: conversation.startedAt,
      lastMessageAt: message.timestamp,
      messages: updatedMessages,
      summaryText: conversation.summaryText,
      keyInsights: conversation.keyInsights,
      recommendations: conversation.recommendations,
    );

    await saveConversation(updated);
  }

  @override
  Future<void> updateConversationSummary(
    String conversationId,
    String summary,
    List<String> insights,
    List<String> recommendations,
  ) async {
    final conversation = await getConversationById(conversationId);
    if (conversation == null) return;

    final updated = ConversationModel(
      id: conversation.id,
      title: conversation.title,
      startedAt: conversation.startedAt,
      lastMessageAt: conversation.lastMessageAt,
      messages: conversation.messages,
      summaryText: summary,
      keyInsights: insights,
      recommendations: recommendations,
    );

    await saveConversation(updated);
  }

  @override
  Future<void> deleteConversation(String id) async {
    // Remove detail
    await prefs.remove(_detailKey(id));

    // Remove from index
    final index = _readIndex();
    index.removeWhere((e) => e['id'] == id);
    await _writeIndex(index);
  }
}
