import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/feature/question/data/model/question_item.dart';
import 'package:talk_gym/feature/question/data/repository/question_repository.dart';

@immutable
sealed class QuestionListingEvent {
  const QuestionListingEvent();
}

class QuestionListingInitialized extends QuestionListingEvent {
  const QuestionListingInitialized();
}

class QuestionListingRefreshed extends QuestionListingEvent {
  const QuestionListingRefreshed();
}

class QuestionSearchChanged extends QuestionListingEvent {
  const QuestionSearchChanged(this.query);

  final String query;
}

class QuestionFilterChanged extends QuestionListingEvent {
  const QuestionFilterChanged(this.filter);

  final String filter;
}

class QuestionFiltersCleared extends QuestionListingEvent {
  const QuestionFiltersCleared();
}

class QuestionLoadMoreRequested extends QuestionListingEvent {
  const QuestionLoadMoreRequested();
}

enum QuestionListingStatus { initial, loading, success, failure }

@immutable
class QuestionListingState {
  const QuestionListingState({
    this.status = QuestionListingStatus.initial,
    this.items = const <QuestionItem>[],
    this.availableFilters = const <String>['All'],
    this.activeFilter = 'All',
    this.searchQuery = '',
    this.hasMore = true,
    this.page = 0,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentDay = 4,
  });

  final QuestionListingStatus status;
  final List<QuestionItem> items;
  final List<String> availableFilters;
  final String activeFilter;
  final String searchQuery;
  final bool hasMore;
  final int page;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentDay;

  QuestionListingState copyWith({
    QuestionListingStatus? status,
    List<QuestionItem>? items,
    List<String>? availableFilters,
    String? activeFilter,
    String? searchQuery,
    bool? hasMore,
    int? page,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentDay,
    bool clearErrorMessage = false,
  }) {
    return QuestionListingState(
      status: status ?? this.status,
      items: items ?? this.items,
      availableFilters: availableFilters ?? this.availableFilters,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      currentDay: currentDay ?? this.currentDay,
    );
  }
}

class QuestionListingBloc
    extends Bloc<QuestionListingEvent, QuestionListingState> {
  QuestionListingBloc({required QuestionRepository repository})
    : _repository = repository,
      super(const QuestionListingState()) {
    on<QuestionListingInitialized>(_onInitialize);
    on<QuestionListingRefreshed>(_onRefresh);
    on<QuestionSearchChanged>(_onSearchChanged);
    on<QuestionFilterChanged>(_onFilterChanged);
    on<QuestionFiltersCleared>(_onFiltersCleared);
    on<QuestionLoadMoreRequested>(_onLoadMore);
  }

  final QuestionRepository _repository;

  static const int _pageSize = 10;

  Future<void> _onInitialize(
    QuestionListingInitialized event,
    Emitter<QuestionListingState> emit,
  ) async {
    await _loadFirstPage(emit);
  }

  Future<void> _onRefresh(
    QuestionListingRefreshed event,
    Emitter<QuestionListingState> emit,
  ) async {
    await _loadFirstPage(emit, forceLoadingState: false);
  }

  Future<void> _onSearchChanged(
    QuestionSearchChanged event,
    Emitter<QuestionListingState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    await _loadFirstPage(emit);
  }

  Future<void> _onFilterChanged(
    QuestionFilterChanged event,
    Emitter<QuestionListingState> emit,
  ) async {
    emit(state.copyWith(activeFilter: event.filter));
    await _loadFirstPage(emit);
  }

  Future<void> _onFiltersCleared(
    QuestionFiltersCleared event,
    Emitter<QuestionListingState> emit,
  ) async {
    emit(state.copyWith(activeFilter: 'All', searchQuery: ''));
    await _loadFirstPage(emit);
  }

  Future<void> _onLoadMore(
    QuestionLoadMoreRequested event,
    Emitter<QuestionListingState> emit,
  ) async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.status == QuestionListingStatus.loading) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true, clearErrorMessage: true));

    try {
      final QuestionPageResult result = await _repository.fetchQuestions(
        page: state.page + 1,
        pageSize: _pageSize,
        searchQuery: state.searchQuery,
        activeFilter: state.activeFilter,
      );

      emit(
        state.copyWith(
          status: QuestionListingStatus.success,
          items: <QuestionItem>[...state.items, ...result.items],
          availableFilters: result.availableFilters,
          page: state.page + 1,
          hasMore: result.hasMore,
          isLoadingMore: false,
          clearErrorMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          status: QuestionListingStatus.failure,
          errorMessage: 'Could not load more questions.',
        ),
      );
    }
  }

  Future<void> _loadFirstPage(
    Emitter<QuestionListingState> emit, {
    bool forceLoadingState = true,
  }) async {
    if (forceLoadingState) {
      emit(
        state.copyWith(
          status: QuestionListingStatus.loading,
          page: 0,
          hasMore: true,
          clearErrorMessage: true,
        ),
      );
    }

    try {
      final QuestionPageResult result = await _repository.fetchQuestions(
        page: 0,
        pageSize: _pageSize,
        searchQuery: state.searchQuery,
        activeFilter: state.activeFilter,
      );

      emit(
        state.copyWith(
          status: QuestionListingStatus.success,
          items: result.items,
          availableFilters: result.availableFilters,
          activeFilter: result.availableFilters.contains(state.activeFilter)
              ? state.activeFilter
              : 'All',
          page: 0,
          hasMore: result.hasMore,
          isLoadingMore: false,
          clearErrorMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: QuestionListingStatus.failure,
          items: const <QuestionItem>[],
          hasMore: false,
          isLoadingMore: false,
          errorMessage: 'Unable to load questions. Pull to retry.',
        ),
      );
    }
  }
}
