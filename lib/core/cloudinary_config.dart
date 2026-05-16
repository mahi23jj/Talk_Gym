/// Configure via `--dart-define=CLOUDINARY_CLOUD_NAME=...` and
/// `--dart-define=CLOUDINARY_UPLOAD_PRESET=...` (unsigned video preset).
abstract final class CloudinaryConfig {
  static const String cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'dxl7h8j1a',
  );
  static const String uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'talkgym_audio',
  );
}
