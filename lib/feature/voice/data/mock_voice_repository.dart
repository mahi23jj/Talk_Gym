import '../model/voice_models.dart';
import 'voice_repository.dart';

class MockVoiceRepository implements VoiceRepository {
  @override
  Future<List<VoiceScenario>> fetchScenarios() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));

    return const <VoiceScenario>[
      VoiceScenario(
        id: 'sarah_delivery',
        personName: 'Sarah',
        avatarEmoji: '👩‍💼',
        context: 'Customer Service',
        topic: 'Upset about delayed delivery',
        durationSeconds: 45,
        difficulty: VoiceDifficulty.easy,
      ),
      VoiceScenario(
        id: 'michael_interview',
        personName: 'Michael',
        avatarEmoji: '👨‍💼',
        context: 'Job Interview',
        topic: 'Asking about career goals',
        durationSeconds: 38,
        difficulty: VoiceDifficulty.medium,
      ),
      VoiceScenario(
        id: 'emily_conflict',
        personName: 'Emily',
        avatarEmoji: '👩‍💻',
        context: 'Conflict Resolution',
        topic: 'Team disagreement',
        durationSeconds: 52,
        difficulty: VoiceDifficulty.hard,
      ),
      VoiceScenario(
        id: 'james_sales',
        personName: 'James',
        avatarEmoji: '🧑‍💼',
        context: 'Sales Call',
        topic: 'Price negotiation',
        durationSeconds: 41,
        difficulty: VoiceDifficulty.medium,
      ),
      VoiceScenario(
        id: 'lisa_feedback',
        personName: 'Lisa',
        avatarEmoji: '🧑‍🏫',
        context: 'Feedback Session',
        topic: 'Performance review',
        durationSeconds: 49,
        difficulty: VoiceDifficulty.hard,
      ),
    ];
  }
}
