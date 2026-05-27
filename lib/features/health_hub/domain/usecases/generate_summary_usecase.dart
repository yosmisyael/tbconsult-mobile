import 'package:equatable/equatable.dart';

import 'package:TBConsult/core/usecases/usecase.dart';
import 'package:TBConsult/features/health_hub/domain/entities/conversation.dart';
import 'package:TBConsult/features/health_hub/domain/repositories/conversation_repository.dart';
import 'package:TBConsult/features/health_hub/domain/usecases/send_message_usecase.dart';

class GenerateSummaryUseCase
    extends UseCase<Conversation, GenerateSummaryParams> {
  final ConversationRepository conversationRepository;
  final TriageService triageService;

  GenerateSummaryUseCase({
    required this.conversationRepository,
    required this.triageService,
  });

  @override
  Future<Conversation> call(GenerateSummaryParams params) async {
    final conversation =
        await conversationRepository.getConversationById(params.conversationId);
    if (conversation == null) {
      throw Exception('Conversation not found: ${params.conversationId}');
    }

    final summaryJson = await triageService.generateConversationSummary(
      conversation.messages,
    );

    // Parse structured summary from Gemini response
    final parsed = _parseSummary(summaryJson);

    await conversationRepository.updateConversationSummary(
      params.conversationId,
      parsed.summary,
      parsed.insights,
      parsed.recommendations,
    );

    return conversation.copyWith(
      summaryText: parsed.summary,
      keyInsights: parsed.insights,
      recommendations: parsed.recommendations,
    );
  }

  _ParsedSummary _parseSummary(String rawResponse) {
    // Gemini is instructed to return structured text with markers.
    // Fallback: treat entire response as summary if parsing fails.
    final lines = rawResponse.split('\n').where((l) => l.trim().isNotEmpty);

    String summary = rawResponse;
    List<String> insights = [];
    List<String> recommendations = [];

    String currentSection = 'summary';

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toUpperCase().startsWith('KEY INSIGHTS:') ||
          trimmed.toUpperCase().startsWith('## KEY INSIGHTS')) {
        currentSection = 'insights';
        continue;
      }
      if (trimmed.toUpperCase().startsWith('RECOMMENDATIONS:') ||
          trimmed.toUpperCase().startsWith('## RECOMMENDATIONS')) {
        currentSection = 'recommendations';
        continue;
      }
      if (trimmed.toUpperCase().startsWith('SUMMARY:') ||
          trimmed.toUpperCase().startsWith('## SUMMARY')) {
        currentSection = 'summary';
        summary = '';
        continue;
      }

      final cleaned =
          trimmed.startsWith('- ') ? trimmed.substring(2) : trimmed;

      switch (currentSection) {
        case 'insights':
          if (cleaned.isNotEmpty) insights.add(cleaned);
        case 'recommendations':
          if (cleaned.isNotEmpty) recommendations.add(cleaned);
        case 'summary':
          summary += summary.isEmpty ? cleaned : '\n$cleaned';
      }
    }

    // Fallback: if parsing yielded nothing structured
    if (insights.isEmpty && recommendations.isEmpty) {
      return _ParsedSummary(
        summary: rawResponse,
        insights: ['Conversation reviewed by TBConsult AI'],
        recommendations: [
          'Continue following your treatment plan',
          'Consult your healthcare provider for specific concerns',
        ],
      );
    }

    return _ParsedSummary(
      summary: summary.trim(),
      insights: insights,
      recommendations: recommendations,
    );
  }
}

class _ParsedSummary {
  final String summary;
  final List<String> insights;
  final List<String> recommendations;

  _ParsedSummary({
    required this.summary,
    required this.insights,
    required this.recommendations,
  });
}

class GenerateSummaryParams extends Equatable {
  final String conversationId;

  const GenerateSummaryParams({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}
