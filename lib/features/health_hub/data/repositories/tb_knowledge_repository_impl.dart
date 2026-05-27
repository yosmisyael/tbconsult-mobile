import 'package:TBConsult/features/health_hub/data/data_sources/tb_knowledge_local_data_source.dart';
import 'package:TBConsult/features/health_hub/domain/entities/tb_knowledge_chunk.dart';
import 'package:TBConsult/features/health_hub/domain/repositories/tb_knowledge_repository.dart';

class TBKnowledgeRepositoryImpl implements TBKnowledgeRepository {
  final TBKnowledgeLocalDataSource localDataSource;

  TBKnowledgeRepositoryImpl({required this.localDataSource});

  @override
  Future<List<TBKnowledgeChunk>> retrieveRelevantChunks(
    String query, {
    int topK = 3,
  }) async {
    return localDataSource.retrieveRelevantChunks(query, topK: topK);
  }

  @override
  Future<List<TBKnowledgeChunk>> getChunksByCategory(
    TBKnowledgeCategory category,
  ) async {
    return localDataSource.getChunksByCategory(category);
  }

  @override
  Future<List<TBKnowledgeChunk>> getAllChunks() async {
    return localDataSource.getAllChunks();
  }
}
