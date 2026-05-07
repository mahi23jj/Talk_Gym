import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/feature/analysis_results/data/model/analysis_result.dart';
import 'package:talk_gym/feature/behavioral_training/bloc/training_event.dart';
import 'package:talk_gym/feature/behavioral_training/bloc/training_state.dart';
import 'package:talk_gym/feature/behavioral_training/data/model/behavioral_training_result.dart';
import 'package:talk_gym/feature/behavioral_training/data/repository/behavioral_training_repository.dart';

class TrainingBloc extends Bloc<TrainingEvent, TrainingState> {
  TrainingBloc({required BehavioralTrainingRepository repository})
    : _repository = repository,
      super(const TrainingState()) {
    on<LoadBehavioralTrainingEvent>(_onLoadBehavioralTraining);
    on<UpdateTranscriptSentenceEvent>(_onUpdateTranscriptSentence);
    on<SubmitEvaluationEvent>(_onSubmitEvaluation);
    on<StartFinalInterviewEvent>(_onStartFinalInterview);
    on<ClearSystemMessageEvent>(_onClearSystemMessage);
  }

  final BehavioralTrainingRepository _repository;

  Future<void> _onLoadBehavioralTraining(
    LoadBehavioralTrainingEvent event,
    Emitter<TrainingState> emit,
  ) async {
    final Map<int, String> initialSentences = <int, String>{};
    for (final MapEntry<int, String> entry in event.analysisResult.transcriptSentences.entries) {
      initialSentences[entry.key] = entry.value;
    }

    emit(
      state.copyWith(
        analysisResult: event.analysisResult,
        attemptId: event.attemptId,
        editedSentences: initialSentences,
        attemptsUsed: 0,
        maxAttempts: 2,
        clearSubmissionResult: true,
        clearEvaluationResult: true,
        status: BehavioralTrainingStatus.ready,
        clearSystemMessage: true,
        clearErrorMessage: true,
      ),
    );
  }

  void _onUpdateTranscriptSentence(
    UpdateTranscriptSentenceEvent event,
    Emitter<TrainingState> emit,
  ) {
    final Map<int, String> updated = Map<int, String>.from(state.editedSentences)
      ..[event.sentenceIndex] = event.text;

    emit(
      state.copyWith(
        editedSentences: updated,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> _onSubmitEvaluation(
    SubmitEvaluationEvent event,
    Emitter<TrainingState> emit,
  ) async {
    if (!state.canSubmitEvaluation) {
      return;
    }

    final AnalysisResult? analysis = state.analysisResult;
    if (analysis == null) {
      return;
    }

    final String transcript = state.currentTranscript.trim();
    if (transcript.isEmpty) {
      emit(
        state.copyWith(
          status: BehavioralTrainingStatus.failure,
          errorMessage: 'Transcript is empty. Add your answer before submitting.',
        ),
      );
      return;
    }

    BehavioralTrainingSubmissionResult? submission;
    int updatedAttemptsUsed = state.attemptsUsed;

    emit(
      state.copyWith(
        status: BehavioralTrainingStatus.submitting,
        clearErrorMessage: true,
        clearSystemMessage: true,
      ),
    );

    try {
      submission = await _repository.submitTrainingAttempt(
        attemptId: state.attemptId,
        transcript: transcript,
        trainingType: 'behavioral_training',
      );

      updatedAttemptsUsed = state.attemptsUsed + 1;
      emit(
        state.copyWith(
          submissionResult: submission,
          attemptsUsed: updatedAttemptsUsed,
          status: BehavioralTrainingStatus.polling,
          clearErrorMessage: true,
          clearSystemMessage: true,
        ),
      );

      final BehavioralTrainingAttemptResult result =
          await _repository.pollTrainingAttemptResultUntilDone(
        trainingAttemptId: submission.trainingAttemptId,
        jobId: submission.jobId,
      );

      final BehavioralTrainingEvaluationAnalysis? analysisResult = result.analysis;
      if (analysisResult == null) {
        throw StateError('Behavioral training result did not include analysis.');
      }

      final bool passed = analysisResult.passed;
      final bool maxAttemptsReached = updatedAttemptsUsed >= state.maxAttempts;
      final String? systemMessage = passed
          ? 'Behavioral training passed. Final interview unlocked.'
          : maxAttemptsReached
              ? 'You reached the maximum number of evaluation attempts.'
              : analysisResult.feedback;

      emit(
        state.copyWith(
          evaluationResult: result,
          status: BehavioralTrainingStatus.ready,
          systemMessage: systemMessage,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          attemptsUsed: updatedAttemptsUsed,
          submissionResult: submission ?? state.submissionResult,
          status: BehavioralTrainingStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onStartFinalInterview(
    StartFinalInterviewEvent event,
    Emitter<TrainingState> emit,
  ) {
    if (!state.canTakeFinalInterview) {
      return;
    }

    emit(
      state.copyWith(finalInterviewRequestId: state.finalInterviewRequestId + 1),
    );
  }

  void _onClearSystemMessage(
    ClearSystemMessageEvent event,
    Emitter<TrainingState> emit,
  ) {
    emit(
      state.copyWith(
        clearSystemMessage: true,
        clearErrorMessage: true,
      ),
    );
  }
}
