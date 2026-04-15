import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/data/services/mock_ai_evaluator.dart';
import 'package:talk_gym/data/services/mock_training_api.dart';
import 'package:talk_gym/feature/behavioral_training/bloc/training_event.dart';
import 'package:talk_gym/feature/behavioral_training/bloc/training_state.dart';
import 'package:talk_gym/feature/behavioral_training/models/behavioral_question.dart';
import 'package:talk_gym/feature/behavioral_training/models/evaluation_result.dart';
import 'package:talk_gym/feature/behavioral_training/models/highlight_info.dart';

class TrainingBloc extends Bloc<TrainingEvent, TrainingState> {
  TrainingBloc({
    required MockTrainingApi trainingApi,
    required MockAiEvaluator aiEvaluator,
  })  : _trainingApi = trainingApi,
        _aiEvaluator = aiEvaluator,
        super(const TrainingState()) {
    on<LoadQuestionsEvent>(_onLoadQuestions);
    on<SelectQuestionEvent>(_onSelectQuestion);
    on<LoadOriginalContentEvent>(_onLoadOriginalContent);
    on<UpdateAnswerEvent>(_onUpdateAnswer);
    on<HighlightSentencesEvent>(_onHighlightSentences);
    on<RequestEvaluationEvent>(_onRequestEvaluation);
    on<RequestSecondEvaluationEvent>(_onRequestSecondEvaluation);
    on<ShowImprovementPopupEvent>(_onShowImprovementPopup);
    on<ApplySuggestionEvent>(_onApplySuggestion);
    on<ApplyImprovedVersionEvent>(_onApplyImprovedVersion);
    on<DismissImprovementPopupEvent>(_onDismissImprovementPopup);
    on<ClearSystemMessageEvent>(_onClearSystemMessage);
    on<StartFinalInterviewEvent>(_onStartFinalInterview);
  }

  final MockTrainingApi _trainingApi;
  final MockAiEvaluator _aiEvaluator;

  Future<void> _onLoadQuestions(
    LoadQuestionsEvent event,
    Emitter<TrainingState> emit,
  ) async {
    emit(state.copyWith(status: FormzStatus.submissionInProgress));
    try {
      final List<BehavioralQuestion> questions = await _trainingApi.fetchQuestions();
      final BehavioralQuestion? selectedQuestion =
          questions.isNotEmpty ? questions.first : null;

      emit(
        state.copyWith(
          questions: questions,
          selectedQuestion: selectedQuestion,
          aiCallsRemaining: 2,
          status: FormzStatus.valid,
          clearEvaluation: true,
          highlightedSentences: const <String, HighlightInfo>{},
          currentAnswer: '',
          originalContent: '',
        ),
      );

      if (selectedQuestion != null) {
        add(const LoadOriginalContentEvent());
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: FormzStatus.submissionFailure,
          systemMessage: 'Unable to load training questions. Please try again.',
        ),
      );
    }
  }

  Future<void> _onSelectQuestion(
    SelectQuestionEvent event,
    Emitter<TrainingState> emit,
  ) async {
    final BehavioralQuestion? next = state.questions
        .cast<BehavioralQuestion?>()
        .firstWhere((BehavioralQuestion? q) => q?.id == event.questionId, orElse: () => null);

    if (next == null) {
      return;
    }

    emit(
      state.copyWith(
        selectedQuestion: next,
        aiCallsRemaining: 2,
        highlightedSentences: const <String, HighlightInfo>{},
        clearEvaluation: true,
      ),
    );

    add(const LoadOriginalContentEvent());
  }

  Future<void> _onLoadOriginalContent(
    LoadOriginalContentEvent event,
    Emitter<TrainingState> emit,
  ) async {
    final BehavioralQuestion? selected = state.selectedQuestion;
    if (selected == null) {
      return;
    }

    final String content = await _trainingApi.fetchOriginalContent(selected.id);
    emit(
      state.copyWith(
        originalContent: content,
        currentAnswer: content,
        highlightedSentences: const <String, HighlightInfo>{},
        clearEvaluation: true,
        status: FormzStatus.valid,
      ),
    );

    add(const HighlightSentencesEvent());
  }

  void _onUpdateAnswer(
    UpdateAnswerEvent event,
    Emitter<TrainingState> emit,
  ) {
    emit(
      state.copyWith(
        currentAnswer: event.newText,
        status: event.newText.trim().isEmpty ? FormzStatus.invalid : FormzStatus.valid,
      ),
    );
  }

  Future<void> _onHighlightSentences(
    HighlightSentencesEvent event,
    Emitter<TrainingState> emit,
  ) async {
    if (state.currentAnswer.trim().isEmpty) {
      emit(
        state.copyWith(
          highlightedSentences: const <String, HighlightInfo>{},
          status: FormzStatus.invalid,
        ),
      );
      return;
    }

    emit(state.copyWith(isAnalyzing: true));
    final Map<String, HighlightInfo> highlighted =
        await _aiEvaluator.highlightWeakSentences(state.currentAnswer);

    emit(
      state.copyWith(
        highlightedSentences: highlighted,
        isAnalyzing: false,
        status: FormzStatus.valid,
      ),
    );
  }

  Future<void> _onRequestEvaluation(
    RequestEvaluationEvent event,
    Emitter<TrainingState> emit,
  ) async {
    await _evaluate(emit, isSecondEvaluation: false);
  }

  Future<void> _onRequestSecondEvaluation(
    RequestSecondEvaluationEvent event,
    Emitter<TrainingState> emit,
  ) async {
    await _evaluate(emit, isSecondEvaluation: true);
  }

  Future<void> _evaluate(
    Emitter<TrainingState> emit, {
    required bool isSecondEvaluation,
  }) async {
    if (state.isEvaluating || state.aiCallsRemaining <= 0 || state.currentAnswer.trim().isEmpty) {
      return;
    }

    if (isSecondEvaluation && state.aiCallsRemaining != 1) {
      return;
    }

    emit(state.copyWith(isEvaluating: true, status: FormzStatus.submissionInProgress));

    final EvaluationResult result = await _aiEvaluator.evaluateAnswer(
      answer: state.currentAnswer,
      isFinalPolish: isSecondEvaluation,
    );

    final int nextCalls = (state.aiCallsRemaining - 1).clamp(0, 2);
    emit(
      state.copyWith(
        evaluationResult: result,
        aiCallsRemaining: nextCalls,
        isEvaluating: false,
        status: FormzStatus.submissionSuccess,
        systemMessage: isSecondEvaluation
            ? 'This was your final AI evaluation. Use the feedback to polish your answer, then take the final interview simulation.'
            : null,
      ),
    );
  }

  void _onShowImprovementPopup(
    ShowImprovementPopupEvent event,
    Emitter<TrainingState> emit,
  ) {
    final HighlightInfo? info = state.highlightedSentences[event.sentence];
    if (info == null) {
      return;
    }

    emit(
      state.copyWith(
        popupHighlight: info,
        popupRequestId: state.popupRequestId + 1,
      ),
    );
  }

  void _onApplySuggestion(
    ApplySuggestionEvent event,
    Emitter<TrainingState> emit,
  ) {
    final String updated = state.currentAnswer.replaceFirst(event.oldSentence, event.newSentence);

    emit(
      state.copyWith(
        currentAnswer: updated,
        clearPopupHighlight: true,
      ),
    );

    add(const HighlightSentencesEvent());
  }

  void _onApplyImprovedVersion(
    ApplyImprovedVersionEvent event,
    Emitter<TrainingState> emit,
  ) {
    final String? improved = state.evaluationResult?.improvedVersion;
    if (improved == null || improved.trim().isEmpty) {
      return;
    }

    emit(state.copyWith(currentAnswer: improved));
    add(const HighlightSentencesEvent());
  }

  void _onDismissImprovementPopup(
    DismissImprovementPopupEvent event,
    Emitter<TrainingState> emit,
  ) {
    emit(state.copyWith(clearPopupHighlight: true));
  }

  void _onClearSystemMessage(
    ClearSystemMessageEvent event,
    Emitter<TrainingState> emit,
  ) {
    emit(state.copyWith(clearSystemMessage: true));
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
}
