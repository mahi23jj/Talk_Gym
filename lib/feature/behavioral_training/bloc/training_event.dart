import 'package:flutter/foundation.dart';
import 'package:talk_gym/feature/analysis_results/data/model/analysis_result.dart';

@immutable
sealed class TrainingEvent {
  const TrainingEvent();
}

class LoadBehavioralTrainingEvent extends TrainingEvent {
  const LoadBehavioralTrainingEvent({
    required this.analysisResult,
    required this.attemptId,
  });

  final AnalysisResult analysisResult;
  final int attemptId;
}

class UpdateTranscriptSentenceEvent extends TrainingEvent {
  const UpdateTranscriptSentenceEvent({
    required this.sentenceIndex,
    required this.text,
  });

  final int sentenceIndex;
  final String text;
}

class SubmitEvaluationEvent extends TrainingEvent {
  const SubmitEvaluationEvent();
}

class StartFinalInterviewEvent extends TrainingEvent {
  const StartFinalInterviewEvent();
}

class ClearSystemMessageEvent extends TrainingEvent {
  const ClearSystemMessageEvent();
}
