

abstract class ProfileEvent{
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  const LoadProfile();
}

class RefreshProfile extends ProfileEvent {
  const RefreshProfile();
}

class ClearProfile extends ProfileEvent {
  const ClearProfile();
}