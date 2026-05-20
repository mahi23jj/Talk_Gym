
import 'package:talk_gym/feature/profile/data/models/profile_model.dart';

import 'profile_status.dart';

class ProfileState {
  final ProfileStatus status;
  final ProfileModel? profile;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileModel? profile,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading => status == ProfileStatus.loading;
  bool get isRefreshing => status == ProfileStatus.refreshing;
  bool get hasProfile => profile != null;
  bool get hasError => status == ProfileStatus.error;

  @override
  List<Object?> get props => [status, profile, errorMessage];
}