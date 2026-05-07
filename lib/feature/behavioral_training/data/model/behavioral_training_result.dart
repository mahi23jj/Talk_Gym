import 'package:flutter/foundation.dart';

@immutable
class BehavioralTrainingSubmissionResult {
  const BehavioralTrainingSubmissionResult({
    required this.jobId,
    required this.trainingAttemptId,
    required this.message,
  });

  final int jobId;
  final int trainingAttemptId;
  final String message;

  factory BehavioralTrainingSubmissionResult.fromJson(Map<String, dynamic> json) {
    return BehavioralTrainingSubmissionResult(
      jobId: _asInt(json['job_id']),
      trainingAttemptId: _asInt(json['training_attempt_id']),
      message: _asString(json['message']),
    );
  }
}

@immutable
class BehavioralTrainingEvaluationAnalysis {
  const BehavioralTrainingEvaluationAnalysis({
    required this.id,
    required this.trainingAttemptId,
    required this.passed,
    required this.feedback,
    required this.score,
  });

  final int id;
  final int trainingAttemptId;
  final bool passed;
  final String feedback;
  final int score;

  factory BehavioralTrainingEvaluationAnalysis.fromJson(Map<String, dynamic> json) {
    return BehavioralTrainingEvaluationAnalysis(
      id: _asInt(json['id']),
      trainingAttemptId: _asInt(json['training_attempt_id']),
      passed: _asBool(json['passed']),
      feedback: _asString(json['feedback']),
      score: _asInt(json['score']),
    );
  }
}

@immutable
class BehavioralTrainingAttemptResult {
  const BehavioralTrainingAttemptResult({
    required this.status,
    this.message,
    this.analysis,
  });

  final String status;
  final String? message;
  final BehavioralTrainingEvaluationAnalysis? analysis;

  bool get isDone => status == 'done';
  bool get isProcessing => status == 'processing';
  bool get isFailed => status == 'failed' || status == 'error';

  factory BehavioralTrainingAttemptResult.fromJson(Map<String, dynamic> json) {
    return BehavioralTrainingAttemptResult(
      status: _asString(json['status']).toLowerCase(),
      message: _asString(json['message']).trim().isEmpty
          ? null
          : _asString(json['message']),
      analysis: json['analysis'] is Map
          ? BehavioralTrainingEvaluationAnalysis.fromJson(
              Map<String, dynamic>.from(json['analysis'] as Map),
            )
          : null,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  final String text = value?.toString().trim().toLowerCase() ?? '';
  return text == 'true' || text == '1' || text == 'yes';
}

String _asString(dynamic value) => value?.toString() ?? '';
