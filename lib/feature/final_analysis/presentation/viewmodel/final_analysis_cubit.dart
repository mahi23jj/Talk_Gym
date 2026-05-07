import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/feature/final_analysis/data/model/final_interview_result.dart';
import 'package:talk_gym/feature/final_analysis/domain/repository/final_analysis_repository.dart';

enum FinalAnalysisStatus { initial, loading, processing, success, failure }

class FinalAnalysisState {
  const FinalAnalysisState({
    this.status = FinalAnalysisStatus.initial,
    this.result,
    this.errorMessage,
  });

  final FinalAnalysisStatus status;
  final FinalInterviewResult? result;
  final String? errorMessage;

  FinalAnalysisState copyWith({
    FinalAnalysisStatus? status,
    FinalInterviewResult? result,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FinalAnalysisState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class FinalAnalysisCubit extends Cubit<FinalAnalysisState> {
  FinalAnalysisCubit({
    required FinalAnalysisRepository repository,
    required String sessionId,
  }) : _repository = repository,
       _sessionId = sessionId,
       super(const FinalAnalysisState());

  final FinalAnalysisRepository _repository;
  final String _sessionId;

  Future<void> load() async {
    emit(state.copyWith(status: FinalAnalysisStatus.loading, clearError: true));
    await _poll();
  }

  Future<void> retry() async {
    await load();
  }

  Future<void> _poll() async {
    final DateTime start = DateTime.now();
    const Duration timeout = Duration(minutes: 3);
    const Duration pollInterval = Duration(seconds: 2);

    while (DateTime.now().difference(start) < timeout) {
      try {
        final FinalInterviewResult result = await _repository.getFinalResult(
          _sessionId,
        );
        final String status = result.status.toLowerCase();
        if (status == 'completed') {
          emit(
            state.copyWith(
              status: FinalAnalysisStatus.success,
              result: result,
              clearError: true,
            ),
          );
          return;
        }
        if (status == 'failed' || status == 'error') {
          emit(
            state.copyWith(
              status: FinalAnalysisStatus.failure,
              errorMessage: result.message ?? 'Final analysis failed.',
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            status: FinalAnalysisStatus.processing,
            result: result,
            clearError: true,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: FinalAnalysisStatus.failure,
            errorMessage: e.toString(),
          ),
        );
        return;
      }

      await Future<void>.delayed(pollInterval);
    }

    emit(
      state.copyWith(
        status: FinalAnalysisStatus.failure,
        errorMessage: 'Final analysis is taking longer than expected.',
      ),
    );
  }
}
