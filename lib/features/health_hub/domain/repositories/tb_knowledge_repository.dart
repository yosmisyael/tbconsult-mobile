import 'package:TBConsult/features/health_hub/domain/entities/tb_knowledge_chunk.dart';

abstract class TBKnowledgeRepository {
  Future<List<TBKnowledgeChunk>> retrieveRelevantChunks(
    String query, {
    int topK = 3,
  });
  Future<List<TBKnowledgeChunk>> getChunksByCategory(
    TBKnowledgeCategory category,
  );
  Future<List<TBKnowledgeChunk>> getAllChunks();
}
