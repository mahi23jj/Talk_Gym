import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/feature/question/data/model/question_item.dart';
import 'package:talk_gym/feature/star_training/data/model/star_training_models.dart';
import 'package:talk_gym/feature/star_training/data/repository/star_training_repository.dart';

enum StarTrainingStatus { initial, loading, ready, failure, submitting, submitted }

enum StarTrainingStage { welcome, countdown, flow, review, success }

@immutable
class StarTrainingState {
  const StarTrainingState({
    this.status = StarTrainingStatus.initial,
    this.stage = StarTrainingStage.welcome,
    this.session,
    this.currentStep = 0,
    this.completedSteps = const <int>{},
    this.answers = const <StarPart, StarAnswer>{},
    this.countdownValue = 3,
    this.isExampleExpanded = false,
    this.isTextMode = false,
    this.errorMessage,
  });

  final StarTrainingStatus status;
  final StarTrainingStage stage;
  final StarTrainingSession? session;
  final int currentStep;
  final Set<int> completedSteps;
  final Map<StarPart, StarAnswer> answers;
  final int countdownValue;
  final bool isExampleExpanded;
  final bool isTextMode;
  final String? errorMessage;

  bool get hasSession => session != null;

  StarStepContent? get activeStep {
    if (session == null || session!.steps.isEmpty) {
      return null;
    }
    return session!.steps[currentStep];
  }

  StarAnswer answerFor(StarPart part) {
    return answers[part] ?? const StarAnswer();
  }

  bool get canGoNext {
    final StarStepContent? step = activeStep;
    if (step == null) {
      return false;
    }
    return answerFor(step.part).hasAny;
  }

  String? get durationWarning {
    final StarStepContent? step = activeStep;
    if (step == null) {
      return null;
    }

    final StarAnswer answer = answerFor(step.part);
    final int? seconds = answer.durationSeconds;
    if (seconds == null) {
      return null;
    }
    if (seconds < 3) {
      return 'Your answer is very short. Try adding more detail.';
    }
    if (seconds > 60) {
      return 'Keep it concise. Aim for 30-45 seconds.';
    }
    return null;
  }

  StarTrainingState copyWith({
    StarTrainingStatus? status,
    StarTrainingStage? stage,
    StarTrainingSession? session,
    int? currentStep,
    Set<int>? completedSteps,
    Map<StarPart, StarAnswer>? answers,
    int? countdownValue,
    bool? isExampleExpanded,
    bool? isTextMode,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StarTrainingState(
      status: status ?? this.status,
      stage: stage ?? this.stage,
      session: session ?? this.session,
      currentStep: currentStep ?? this.currentStep,
      completedSteps: completedSteps ?? this.completedSteps,
      answers: answers ?? this.answers,
      countdownValue: countdownValue ?? this.countdownValue,
      isExampleExpanded: isExampleExpanded ?? this.isExampleExpanded,
      isTextMode: isTextMode ?? this.isTextMode,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class StarTrainingBloc extends Cubit<StarTrainingState> {
  StarTrainingBloc({required StarTrainingRepository repository})
      : _repository = repository,
        super(const StarTrainingState());

  final StarTrainingRepository _repository;

  Future<void> load(QuestionItem question) async {
    emit(
      state.copyWith(
        status: StarTrainingStatus.loading,
        clearError: true,
      ),
    );

    try {
      final StarTrainingSession session = await _repository.fetchSession(question);
      emit(
        state.copyWith(
          status: StarTrainingStatus.ready,
          session: session,
          stage: StarTrainingStage.welcome,
          currentStep: 0,
          completedSteps: <int>{},
          answers: <StarPart, StarAnswer>{},
          countdownValue: 3,
          isExampleExpanded: false,
          isTextMode: false,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: StarTrainingStatus.failure,
          errorMessage: 'Failed to load question. Please try again.',
        ),
      );
    }
  }

  void openCountdown() {
    emit(
      state.copyWith(
        stage: StarTrainingStage.countdown,
        countdownValue: 3,
      ),
    );
  }

  void setCountdown(int value) {
    emit(state.copyWith(countdownValue: value));
  }

  void skipCountdown() {
    emit(state.copyWith(stage: StarTrainingStage.flow));
  }

  void openFlow() {
    emit(state.copyWith(stage: StarTrainingStage.flow));
  }

  void toggleExample() {
    emit(state.copyWith(isExampleExpanded: !state.isExampleExpanded));
  }

  void toggleTextMode() {
    emit(state.copyWith(isTextMode: !state.isTextMode));
  }

  void setTextAnswer(StarPart part, String value) {
    final Map<StarPart, StarAnswer> updated = Map<StarPart, StarAnswer>.from(state.answers);
    final StarAnswer current = updated[part] ?? const StarAnswer();
    updated[part] = current.copyWith(text: value);
    emit(state.copyWith(answers: updated));
  }

  void saveVoiceAnswer({
    required StarPart part,
    required String audioPath,
    required int durationSeconds,
    required List<double> waveform,
  }) {
    final Map<StarPart, StarAnswer> updated = Map<StarPart, StarAnswer>.from(state.answers);
    final StarAnswer current = updated[part] ?? const StarAnswer();
    updated[part] = current.copyWith(
      audioPath: audioPath,
      durationSeconds: durationSeconds,
      waveform: waveform,
    );
    emit(state.copyWith(answers: updated));
  }

  void clearAnswer(StarPart part) {
    final Map<StarPart, StarAnswer> updated = Map<StarPart, StarAnswer>.from(state.answers);
    final StarAnswer current = updated[part] ?? const StarAnswer();
    updated[part] = current.copyWith(
      clearAudio: true,
      waveform: const <double>[],
      text: '',
    );
    emit(state.copyWith(answers: updated));
  }

  void jumpToStep(int index) {
    if (state.session == null || index < 0 || index >= state.session!.steps.length) {
      return;
    }

    final bool isCompleted = state.completedSteps.contains(index);
    final bool isCurrent = state.currentStep == index;
    if (isCompleted || isCurrent) {
      emit(state.copyWith(currentStep: index));
    }
  }

  void nextStep() {
    final StarStepContent? active = state.activeStep;
    if (active == null) {
      return;
    }

    final Set<int> completed = Set<int>.from(state.completedSteps)..add(state.currentStep);

    final int next = state.currentStep + 1;
    if (state.session != null && next < state.session!.steps.length) {
      emit(
        state.copyWith(
          currentStep: next,
          completedSteps: completed,
          isTextMode: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        completedSteps: completed,
        stage: StarTrainingStage.review,
      ),
    );
  }

  void backToEdit() {
    emit(state.copyWith(stage: StarTrainingStage.flow));
  }

  Future<void> submitFinal() async {
    emit(state.copyWith(status: StarTrainingStatus.submitting));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    emit(
      state.copyWith(
        status: StarTrainingStatus.submitted,
        stage: StarTrainingStage.success,
      ),
    );
  }
}
