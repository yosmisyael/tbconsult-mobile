import 'package:TBConsult/core/usecases/usecase.dart';
import 'package:TBConsult/features/health_hub/domain/entities/tb_knowledge_chunk.dart';
import 'package:TBConsult/features/health_hub/domain/repositories/tb_knowledge_repository.dart';

class RetrieveTBContextUseCase
    extends UseCase<List<TBKnowledgeChunk>, RetrieveTBContextParams> {
  final TBKnowledgeRepository repository;

  RetrieveTBContextUseCase(this.repository);

  @override
  Future<List<TBKnowledgeChunk>> call(RetrieveTBContextParams params) async {
    return repository.retrieveRelevantChunks(
      params.query,
      topK: params.topK,
    );
  }
}

class RetrieveTBContextParams {
  final String query;
  final int topK;

  const RetrieveTBContextParams({required this.query, this.topK = 3});
}
