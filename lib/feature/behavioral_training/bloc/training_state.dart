import 'package:flutter/foundation.dart';
import 'package:talk_gym/feature/behavioral_training/models/behavioral_question.dart';
import 'package:talk_gym/feature/behavioral_training/models/evaluation_result.dart';
import 'package:talk_gym/feature/behavioral_training/models/highlight_info.dart';

enum FormzStatus {
  pure,
  valid,
  invalid,
  submissionInProgress,
  submissionSuccess,
  submissionFailure,
}

@immutable
class TrainingState {
  const TrainingState({
    this.questions = const <BehavioralQuestion>[],
    this.selectedQuestion,
    this.originalContent = '',
    this.currentAnswer = '',
    this.highlightedSentences = const <String, HighlightInfo>{},
    this.evaluationResult,
    this.aiCallsRemaining = 2,
    this.isAnalyzing = false,
    this.isEvaluating = false,
    this.status = FormzStatus.pure,
    this.popupHighlight,
    this.popupRequestId = 0,
    this.finalInterviewRequestId = 0,
    this.systemMessage,
  });

  final List<BehavioralQuestion> questions;
  final BehavioralQuestion? selectedQuestion;
  final String originalContent;
  final String currentAnswer;
  final Map<String, HighlightInfo> highlightedSentences;
  final EvaluationResult? evaluationResult;
  final int aiCallsRemaining;
  final bool isAnalyzing;
  final bool isEvaluating;
  final FormzStatus status;
  final HighlightInfo? popupHighlight;
  final int popupRequestId;
  final int finalInterviewRequestId;
  final String? systemMessage;

  bool get canEvaluate => aiCallsRemaining > 0 && !isEvaluating;
  bool get hasEvaluation => evaluationResult != null;
  bool get canTakeFinalInterview => evaluationResult != null;

  TrainingState copyWith({
    List<BehavioralQuestion>? questions,
    BehavioralQuestion? selectedQuestion,
    bool clearSelectedQuestion = false,
    String? originalContent,
    String? currentAnswer,
    Map<String, HighlightInfo>? highlightedSentences,
    EvaluationResult? evaluationResult,
    bool clearEvaluation = false,
    int? aiCallsRemaining,
    bool? isAnalyzing,
    bool? isEvaluating,
    FormzStatus? status,
    HighlightInfo? popupHighlight,
    bool clearPopupHighlight = false,
    int? popupRequestId,
    int? finalInterviewRequestId,
    String? systemMessage,
    bool clearSystemMessage = false,
  }) {
    return TrainingState(
      questions: questions ?? this.questions,
      selectedQuestion: clearSelectedQuestion
          ? null
          : (selectedQuestion ?? this.selectedQuestion),
      originalContent: originalContent ?? this.originalContent,
      currentAnswer: currentAnswer ?? this.currentAnswer,
      highlightedSentences: highlightedSentences ?? this.highlightedSentences,
      evaluationResult: clearEvaluation
          ? null
          : (evaluationResult ?? this.evaluationResult),
      aiCallsRemaining: aiCallsRemaining ?? this.aiCallsRemaining,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isEvaluating: isEvaluating ?? this.isEvaluating,
      status: status ?? this.status,
      popupHighlight: clearPopupHighlight
          ? null
          : (popupHighlight ?? this.popupHighlight),
      popupRequestId: popupRequestId ?? this.popupRequestId,
      finalInterviewRequestId: finalInterviewRequestId ?? this.finalInterviewRequestId,
      systemMessage: clearSystemMessage ? null : (systemMessage ?? this.systemMessage),
    );
  }
}
