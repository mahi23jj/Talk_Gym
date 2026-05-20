import 'package:bloc/bloc.dart';
import 'package:talk_gym/feature/profile/data/repositories/profile_repository.dart';

import 'profile_event.dart';
import 'profile_state.dart';
import 'profile_status.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc({required this.repository}) : super(const ProfileState()) {
    on<LoadProfile>(_onLoadProfile);
    on<RefreshProfile>(_onRefreshProfile);
    on<ClearProfile>(_onClearProfile);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      status: ProfileStatus.loading,
      errorMessage: null,
    ));

    try {
      final profile = await repository.getProfile();
      emit(state.copyWith(
        status: ProfileStatus.loaded,
        profile: profile,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      ));

      try {
        final mockProfile = await repository.getMockProfile();
        emit(state.copyWith(
          status: ProfileStatus.loaded,
          profile: mockProfile,
          errorMessage: 'Using mock data: ${e.toString()}',
        ));
      } catch (_) {}
    }
  }

  Future<void> _onRefreshProfile(
    RefreshProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      status: ProfileStatus.refreshing,
      errorMessage: null,
    ));

    try {
      final profile = await repository.getProfile();
      emit(state.copyWith(
        status: ProfileStatus.loaded,
        profile: profile,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onClearProfile(
    ClearProfile event,
    Emitter<ProfileState> emit,
  ) {
    emit(const ProfileState());
  }
}