import 'package:flutter/foundation.dart';

@immutable
sealed class TrainingEvent {
  const TrainingEvent();
}

class LoadQuestionsEvent extends TrainingEvent {
  const LoadQuestionsEvent();
}

class SelectQuestionEvent extends TrainingEvent {
  const SelectQuestionEvent(this.questionId);

  final String questionId;
}

class LoadOriginalContentEvent extends TrainingEvent {
  const LoadOriginalContentEvent();
}

class UpdateAnswerEvent extends TrainingEvent {
  const UpdateAnswerEvent(this.newText);

  final String newText;
}

class HighlightSentencesEvent extends TrainingEvent {
  const HighlightSentencesEvent();
}

class RequestEvaluationEvent extends TrainingEvent {
  const RequestEvaluationEvent();
}

class RequestSecondEvaluationEvent extends TrainingEvent {
  const RequestSecondEvaluationEvent();
}

class ShowImprovementPopupEvent extends TrainingEvent {
  const ShowImprovementPopupEvent(this.sentence, this.feedback);

  final String sentence;
  final String feedback;
}

class ApplySuggestionEvent extends TrainingEvent {
  const ApplySuggestionEvent(this.oldSentence, this.newSentence);

  final String oldSentence;
  final String newSentence;
}

class ApplyImprovedVersionEvent extends TrainingEvent {
  const ApplyImprovedVersionEvent();
}

class DismissImprovementPopupEvent extends TrainingEvent {
  const DismissImprovementPopupEvent();
}

class ClearSystemMessageEvent extends TrainingEvent {
  const ClearSystemMessageEvent();
}

class StartFinalInterviewEvent extends TrainingEvent {
  const StartFinalInterviewEvent();
}
