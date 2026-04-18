import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/feature/analysis_results/data/model/analysis_result.dart';
import 'package:talk_gym/feature/analysis_results/data/repository/analysis_results_repository.dart';

@immutable
sealed class AnalysisResultsEvent {
  const AnalysisResultsEvent();
}

class AnalysisResultsStarted extends AnalysisResultsEvent {
  const AnalysisResultsStarted();
}

class AnalysisResultsRefreshed extends AnalysisResultsEvent {
  const AnalysisResultsRefreshed();
}

class AnalysisSentenceTapped extends AnalysisResultsEvent {
  const AnalysisSentenceTapped(this.sentenceIndex);

  final int sentenceIndex;
}

class AnalysisSentenceImprovementApplied extends AnalysisResultsEvent {
  const AnalysisSentenceImprovementApplied({
    required this.sentenceIndex,
    required this.replacement,
  });

  final int sentenceIndex;
  final String replacement;
}

class AnalysisPopupClosed extends AnalysisResultsEvent {
  const AnalysisPopupClosed();
}

class AnalysisReviewed extends AnalysisResultsEvent {
  const AnalysisReviewed();
}

class AnalysisResultsRetryRequested extends AnalysisResultsEvent {
  const AnalysisResultsRetryRequested();
}

enum AnalysisResultsStatus { initial, loading, success, failure }

@immutable
class AnalysisResultsState {
  const AnalysisResultsState({
    this.status = AnalysisResultsStatus.initial,
    this.analysis,
    this.editedSentences = const <int, String>{},
    this.sentenceVersions = const <int, int>{},
    this.selectedSentenceIndex,
    this.popupRequestId = 0,
    this.loadToken = 0,
    this.hasReviewedAnalysis = false,
    this.errorMessage,
  });

  final AnalysisResultsStatus status;
  final AnalysisResult? analysis;
  final Map<int, String> editedSentences;
  final Map<int, int> sentenceVersions;
  final int? selectedSentenceIndex;
  final int popupRequestId;
  final int loadToken;
  final bool hasReviewedAnalysis;
  final String? errorMessage;

  bool get hasAnalysis => analysis != null;

  List<int> get orderedSentenceIndices {
    final AnalysisResult? result = analysis;
    if (result == null) {
      return const <int>[];
    }
    return result.orderedSentenceIndices;
  }

  String sentenceTextFor(int index) {
    return editedSentences[index] ?? analysis?.transcriptSentences[index] ?? '';
  }

  int sentenceVersionFor(int index) {
    return sentenceVersions[index] ?? 0;
  }

  SentenceFeedback? feedbackFor(int index) {
    final AnalysisResult? result = analysis;
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
    if (analysis == null) {
      return '';
    }

    return orderedSentenceIndices.map(sentenceTextFor).join(' ');
  }

  SentenceFeedback? get selectedFeedback {
    final int? selectedIndex = selectedSentenceIndex;
    if (selectedIndex == null) {
      return null;
    }
    return feedbackFor(selectedIndex);
  }

  AnalysisResultsState copyWith({
    AnalysisResultsStatus? status,
    AnalysisResult? analysis,
    bool clearAnalysis = false,
    Map<int, String>? editedSentences,
    Map<int, int>? sentenceVersions,
    int? selectedSentenceIndex,
    bool clearSelectedSentence = false,
    int? popupRequestId,
    int? loadToken,
    bool? hasReviewedAnalysis,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AnalysisResultsState(
      status: status ?? this.status,
      analysis: clearAnalysis ? null : (analysis ?? this.analysis),
      editedSentences: editedSentences != null
          ? Map<int, String>.unmodifiable(editedSentences)
          : this.editedSentences,
      sentenceVersions: sentenceVersions != null
          ? Map<int, int>.unmodifiable(sentenceVersions)
          : this.sentenceVersions,
      selectedSentenceIndex: clearSelectedSentence
          ? null
          : (selectedSentenceIndex ?? this.selectedSentenceIndex),
      popupRequestId: popupRequestId ?? this.popupRequestId,
      loadToken: loadToken ?? this.loadToken,
      hasReviewedAnalysis: hasReviewedAnalysis ?? this.hasReviewedAnalysis,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}

class AnalysisResultsBloc
    extends Bloc<AnalysisResultsEvent, AnalysisResultsState> {
  AnalysisResultsBloc({required AnalysisResultsRepository repository})
    : _repository = repository,
      super(const AnalysisResultsState()) {
    on<AnalysisResultsStarted>(_onStarted);
    on<AnalysisResultsRefreshed>(_onRefreshed);
    on<AnalysisSentenceTapped>(_onSentenceTapped);
    on<AnalysisSentenceImprovementApplied>(_onImprovementApplied);
    on<AnalysisPopupClosed>(_onPopupClosed);
    on<AnalysisReviewed>(_onReviewed);
    on<AnalysisResultsRetryRequested>(_onRetryRequested);
  }

  final AnalysisResultsRepository _repository;

  Future<void> _onStarted(
    AnalysisResultsStarted event,
    Emitter<AnalysisResultsState> emit,
  ) async {
    await _loadAnalysis(emit);
  }

  Future<void> _onRefreshed(
    AnalysisResultsRefreshed event,
    Emitter<AnalysisResultsState> emit,
  ) async {
    await _loadAnalysis(emit);
  }

  void _onSentenceTapped(
    AnalysisSentenceTapped event,
    Emitter<AnalysisResultsState> emit,
  ) {
    final SentenceFeedback? feedback = state.feedbackFor(event.sentenceIndex);
    if (feedback == null) {
      return;
    }

    emit(
      state.copyWith(
        selectedSentenceIndex: event.sentenceIndex,
        popupRequestId: state.popupRequestId + 1,
        hasReviewedAnalysis: true,
      ),
    );
  }

  void _onImprovementApplied(
    AnalysisSentenceImprovementApplied event,
    Emitter<AnalysisResultsState> emit,
  ) {
    final Map<int, String> updatedSentences = Map<int, String>.from(
      state.editedSentences,
    )..[event.sentenceIndex] = event.replacement;

    final Map<int, int> updatedVersions =
        Map<int, int>.from(state.sentenceVersions)
          ..[event.sentenceIndex] =
              state.sentenceVersionFor(event.sentenceIndex) + 1;

    emit(
      state.copyWith(
        editedSentences: updatedSentences,
        sentenceVersions: updatedVersions,
        hasReviewedAnalysis: true,
      ),
    );
  }

  void _onPopupClosed(
    AnalysisPopupClosed event,
    Emitter<AnalysisResultsState> emit,
  ) {
    emit(state.copyWith(clearSelectedSentence: true));
  }

  void _onReviewed(AnalysisReviewed event, Emitter<AnalysisResultsState> emit) {
    emit(state.copyWith(hasReviewedAnalysis: true));
  }

  Future<void> _onRetryRequested(
    AnalysisResultsRetryRequested event,
    Emitter<AnalysisResultsState> emit,
  ) async {
    await _loadAnalysis(emit);
  }

  Future<void> _loadAnalysis(Emitter<AnalysisResultsState> emit) async {
    emit(
      state.copyWith(
        status: AnalysisResultsStatus.loading,
        clearErrorMessage: true,
        clearAnalysis: true,
        clearSelectedSentence: true,
        editedSentences: const <int, String>{},
        sentenceVersions: const <int, int>{},
        hasReviewedAnalysis: false,
      ),
    );

    try {
      final AnalysisResult analysis = await _repository.fetchAnalysisResults();
      final Map<int, int> versions = <int, int>{};
      for (final int index in analysis.orderedSentenceIndices) {
        versions[index] = 0;
      }

      emit(
        state.copyWith(
          status: AnalysisResultsStatus.success,
          analysis: analysis,
          editedSentences: const <int, String>{},
          sentenceVersions: versions,
          loadToken: state.loadToken + 1,
          hasReviewedAnalysis: false,
          clearErrorMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AnalysisResultsStatus.failure,
          errorMessage: 'Unable to load AI analysis. Please try again.',
        ),
      );
    }
  }
}
