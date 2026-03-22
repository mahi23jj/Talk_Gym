import '../model/voice_models.dart';
import 'voice_repository.dart';

class ApiVoiceRepository implements VoiceRepository {
  const ApiVoiceRepository();

  @override
  Future<List<VoiceScenario>> fetchScenarios() {
    // TODO: Replace with real API call and mapping.
    throw UnimplementedError('Voice API repository is not implemented yet.');
  }
}
