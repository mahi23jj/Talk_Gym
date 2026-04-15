import 'package:flutter/foundation.dart';

@immutable
class EvaluationResult {
  const EvaluationResult({
    required this.score,
    required this.starMethodScore,
    required this.overallFeedback,
    required this.specificSuggestions,
    required this.strengths,
    this.improvedVersion,
  });

  final int score;
  final Map<String, int> starMethodScore;
  final String overallFeedback;
  final List<String> specificSuggestions;
  final List<String> strengths;
  final String? improvedVersion;
}
