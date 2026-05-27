import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:TBConsult/features/health_hub/data/models/tb_knowledge_chunk_model.dart';
import 'package:TBConsult/features/health_hub/domain/entities/tb_knowledge_chunk.dart';

abstract class TBKnowledgeLocalDataSource {
  Future<void> initialize();
  List<TBKnowledgeChunkModel> retrieveRelevantChunks(
    String query, {
    int topK = 3,
  });
  List<TBKnowledgeChunkModel> getChunksByCategory(
    TBKnowledgeCategory category,
  );
  List<TBKnowledgeChunkModel> getAllChunks();
}

class TBKnowledgeLocalDataSourceImpl implements TBKnowledgeLocalDataSource {
  List<TBKnowledgeChunkModel> _chunks = [];
  bool _initialized = false;

  /// Indonesian stopwords to strip before keyword matching.
  static const _stopwords = {
    'dan', 'di', 'ke', 'dari', 'yang', 'untuk', 'dengan', 'pada',
    'ini', 'itu', 'atau', 'juga', 'sudah', 'saya', 'apa', 'ada',
    'tidak', 'bisa', 'akan', 'lebih', 'sangat', 'kalau', 'karena',
    'tapi', 'saat', 'bagaimana', 'kenapa', 'mengapa', 'apakah',
    // English stopwords
    'the', 'is', 'are', 'was', 'were', 'a', 'an', 'and', 'or',
    'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by',
    'i', 'my', 'me', 'do', 'does', 'can', 'how', 'what', 'why',
    'when', 'if', 'it', 'this', 'that', 'have', 'has', 'am',
  };

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    final jsonString = await rootBundle.loadString(
      'assets/knowledge/tb_knowledge.json',
    );
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;

    _chunks = jsonList
        .map((e) =>
            TBKnowledgeChunkModel.fromJson(e as Map<String, dynamic>))
        .toList();

    _initialized = true;
  }

  @override
  List<TBKnowledgeChunkModel> retrieveRelevantChunks(
    String query, {
    int topK = 3,
  }) {
    if (!_initialized || _chunks.isEmpty) return [];

    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) return _fallbackChunks();

    // Score each chunk by keyword overlap ratio
    final scored = <_ScoredChunk>[];
    for (final chunk in _chunks) {
      final hits =
          chunk.keywords.where((k) => queryTokens.contains(k)).length;
      if (hits > 0) {
        final score = hits / chunk.keywords.length;
        scored.add(_ScoredChunk(chunk: chunk, score: score));
      }
    }

    if (scored.isEmpty) return _fallbackChunks();

    // Sort descending by score
    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored.take(topK).map((s) => s.chunk).toList();
  }

  @override
  List<TBKnowledgeChunkModel> getChunksByCategory(
    TBKnowledgeCategory category,
  ) {
    return _chunks.where((c) => c.category == category).toList();
  }

  @override
  List<TBKnowledgeChunkModel> getAllChunks() => List.unmodifiable(_chunks);

  // ── Private helpers ────────────────────────────────────────────────────

  /// Tokenize and normalize query: lowercase, remove stopwords, split on
  /// whitespace and common punctuation.
  List<String> _tokenize(String query) {
    final normalized = query.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ');
    return normalized
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1 && !_stopwords.contains(t))
        .toList();
  }

  /// Fallback: return medication + symptoms chunks when no keyword hits.
  List<TBKnowledgeChunkModel> _fallbackChunks() {
    final fallback = _chunks
        .where((c) =>
            c.category == TBKnowledgeCategory.medication ||
            c.category == TBKnowledgeCategory.symptoms)
        .take(3)
        .toList();
    return fallback;
  }
}

class _ScoredChunk {
  final TBKnowledgeChunkModel chunk;
  final double score;

  _ScoredChunk({required this.chunk, required this.score});
}
