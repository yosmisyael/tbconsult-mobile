import 'package:equatable/equatable.dart';

class TriageResponse extends Equatable {
  final String riskLevel;
  final String responseText;
  final List<String> redFlags;
  final List<String> sources;
  final Map<String, dynamic>? sdui;

  const TriageResponse({
    required this.riskLevel,
    required this.responseText,
    required this.redFlags,
    required this.sources,
    this.sdui,
  });

  @override
  List<Object?> get props => [
        riskLevel,
        responseText,
        redFlags,
        sources,
        sdui,
      ];
}
