import 'package:flutter/foundation.dart';

enum HighlightIssueType {
  tooVague,
  missingSTAR,
  noMetric,
  noAction,
  passiveVoice,
  cliche,
}

extension HighlightIssueTypeX on HighlightIssueType {
  String get label {
    switch (this) {
      case HighlightIssueType.tooVague:
        return 'Too Vague';
      case HighlightIssueType.missingSTAR:
        return 'Missing STAR Element';
      case HighlightIssueType.noMetric:
        return 'No Metric';
      case HighlightIssueType.noAction:
        return 'No Action';
      case HighlightIssueType.passiveVoice:
        return 'Team Attribution';
      case HighlightIssueType.cliche:
        return 'Cliche Language';
    }
  }
}

@immutable
class HighlightInfo {
  const HighlightInfo({
    required this.sentence,
    required this.issueType,
    required this.suggestion,
    required this.example,
    required this.startIndex,
    required this.endIndex,
  });

  final String sentence;
  final HighlightIssueType issueType;
  final String suggestion;
  final String example;
  final int startIndex;
  final int endIndex;

  HighlightInfo copyWith({
    String? sentence,
    HighlightIssueType? issueType,
    String? suggestion,
    String? example,
    int? startIndex,
    int? endIndex,
  }) {
    return HighlightInfo(
      sentence: sentence ?? this.sentence,
      issueType: issueType ?? this.issueType,
      suggestion: suggestion ?? this.suggestion,
      example: example ?? this.example,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
    );
  }
}
