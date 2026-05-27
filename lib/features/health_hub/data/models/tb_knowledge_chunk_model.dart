import 'package:TBConsult/features/health_hub/domain/entities/tb_knowledge_chunk.dart';

class TBKnowledgeChunkModel extends TBKnowledgeChunk {
  const TBKnowledgeChunkModel({
    required super.id,
    required super.category,
    required super.title,
    required super.content,
    required super.keywords,
  });

  factory TBKnowledgeChunkModel.fromJson(Map<String, dynamic> json) {
    return TBKnowledgeChunkModel(
      id: json['id'] as String,
      category: _parseCategory(json['category'] as String),
      title: json['title'] as String,
      content: json['content'] as String,
      keywords: (json['keywords'] as List<dynamic>)
          .map((e) => (e as String).toLowerCase())
          .toList(),
    );
  }

  static TBKnowledgeCategory _parseCategory(String value) {
    return switch (value) {
      'symptoms' => TBKnowledgeCategory.symptoms,
      'medication' => TBKnowledgeCategory.medication,
      'sideEffects' || 'side_effects' => TBKnowledgeCategory.sideEffects,
      'diet' => TBKnowledgeCategory.diet,
      'treatmentProtocol' ||
      'treatment_protocol' =>
        TBKnowledgeCategory.treatmentProtocol,
      'emergencySigns' ||
      'emergency_signs' =>
        TBKnowledgeCategory.emergencySigns,
      'dosing' => TBKnowledgeCategory.dosing,
      _ => TBKnowledgeCategory.symptoms,
    };
  }
}
