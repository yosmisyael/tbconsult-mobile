import 'package:equatable/equatable.dart';

enum TBKnowledgeCategory {
  symptoms,
  medication,
  sideEffects,
  diet,
  treatmentProtocol,
  emergencySigns,
  dosing,
}

class TBKnowledgeChunk extends Equatable {
  final String id;
  final TBKnowledgeCategory category;
  final String title;
  final String content;
  final List<String> keywords;

  const TBKnowledgeChunk({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.keywords,
  });

  @override
  List<Object?> get props => [id, category, title, content, keywords];
}
