import '../model/voice_models.dart';

abstract class VoiceRepository {
  Future<List<VoiceScenario>> fetchScenarios();
}
