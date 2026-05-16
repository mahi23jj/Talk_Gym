import 'package:flutter/foundation.dart';
import 'package:talk_gym/feature/analysis_results/data/model/analysis_result.dart';
import 'package:talk_gym/feature/behavioral_training/data/model/behavioral_training_result.dart';

enum BehavioralTrainingStatus {
  initial,
  loading,
  ready,
  submitting,
  polling,
  failure,
}

@immutable
class TrainingState {
  const TrainingState({
    this.analysisResult,
    this.attemptId = 0,
    this.editedSentences = const <int, String>{},
    this.attemptsUsed = 0,
    this.maxAttempts = 2,
    this.submissionResult,
    this.evaluationResult,
    this.status = BehavioralTrainingStatus.initial,
    this.finalInterviewRequestId = 0,
    this.systemMessage,
    this.errorMessage,
  });

  final AnalysisResult? analysisResult;
  final int attemptId;
  final Map<int, String> editedSentences;
  final int attemptsUsed;
  final int maxAttempts;
  final BehavioralTrainingSubmissionResult? submissionResult;
  final BehavioralTrainingAttemptResult? evaluationResult;
  final BehavioralTrainingStatus status;
  final int finalInterviewRequestId;
  final String? systemMessage;
  final String? errorMessage;

  bool get isLoading => status == BehavioralTrainingStatus.loading;
  bool get isSubmitting => status == BehavioralTrainingStatus.submitting;
  bool get isPolling => status == BehavioralTrainingStatus.polling;
  bool get hasLoadedAnalysis => analysisResult != null;
  bool get hasEvaluation => evaluationResult != null;
  bool get hasPassed => evaluationResult?.analysis?.passed == true;
  bool get attemptLimitReached => attemptsUsed >= maxAttempts && !hasPassed;
  bool get canTakeFinalInterview => hasPassed || attemptLimitReached;
  bool get canSubmitEvaluation =>
      hasLoadedAnalysis &&
      !isLoading &&
      !isSubmitting &&
      !isPolling &&
      !hasPassed &&
      attemptsUsed < maxAttempts &&
      currentTranscript.trim().isNotEmpty;

  List<int> get orderedSentenceIndices {
    final AnalysisResult? result = analysisResult;
    if (result == null) {
      return const <int>[];
    }
    return result.orderedSentenceIndices;
  }

  String sentenceTextFor(int index) {
    return editedSentences[index] ?? analysisResult?.transcriptSentences[index] ?? '';
  }

  SentenceFeedback? feedbackFor(int index) {
    final AnalysisResult? result = analysisResult;
    if (result == null) {
      return null;
    }

    for (final SentenceFeedback feedback in result.sentenceFeedback) {
      if (feedback.sentenceIndex == index) {
        return feedback;
      }
    }
    return null;
  }

  String get currentTranscript {
    if (analysisResult == null) {
      return '';
    }

    return orderedSentenceIndices.map(sentenceTextFor).join(' ');
  }

  List<BehavioralQuestions> get coachingQuestions =>
      analysisResult?.behavioralQuestions ?? const <BehavioralQuestions>[];

  TrainingState copyWith({
    AnalysisResult? analysisResult,
    bool clearAnalysisResult = false,
    int? attemptId,
    Map<int, String>? editedSentences,
    int? attemptsUsed,
    int? maxAttempts,
    BehavioralTrainingSubmissionResult? submissionResult,
    bool clearSubmissionResult = false,
    BehavioralTrainingAttemptResult? evaluationResult,
    bool clearEvaluationResult = false,
    BehavioralTrainingStatus? status,
    int? finalInterviewRequestId,
    String? systemMessage,
    bool clearSystemMessage = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return TrainingState(
      analysisResult: clearAnalysisResult
          ? null
          : (analysisResult ?? this.analysisResult),
      attemptId: attemptId ?? this.attemptId,
      editedSentences: editedSentences ?? this.editedSentences,
      attemptsUsed: attemptsUsed ?? this.attemptsUsed,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      submissionResult: clearSubmissionResult
          ? null
          : (submissionResult ?? this.submissionResult),
      evaluationResult: clearEvaluationResult
          ? null
          : (evaluationResult ?? this.evaluationResult),
      status: status ?? this.status,
      finalInterviewRequestId: finalInterviewRequestId ?? this.finalInterviewRequestId,
      systemMessage: clearSystemMessage ? null : (systemMessage ?? this.systemMessage),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
