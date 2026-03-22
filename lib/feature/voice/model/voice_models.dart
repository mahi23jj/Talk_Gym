enum VoiceDifficulty { easy, medium, hard }

class VoiceScenario {
  const VoiceScenario({
    required this.id,
    required this.personName,
    required this.avatarEmoji,
    required this.context,
    required this.topic,
    required this.durationSeconds,
    required this.difficulty,
  });

  final String id;
  final String personName;
  final String avatarEmoji;
  final String context;
  final String topic;
  final int durationSeconds;
  final VoiceDifficulty difficulty;
}
