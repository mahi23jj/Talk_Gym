import '../model/home_models.dart';
import 'home_repository.dart';

class MockHomeRepository implements HomeRepository {
  @override
  Future<HomeDashboardData> fetchDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return const HomeDashboardData(
      userName: 'Solomon',
      stats: <StatCardData>[
        StatCardData(
          label: 'Streak',
          value: '7',
          unit: 'days',
          icon: 'local_fire_department',
          startColorHex: 0xFFFF7A00,
          endColorHex: 0xFFFF5C00,
        ),
        StatCardData(
          label: 'Today',
          value: '120',
          unit: 'points',
          icon: 'auto_awesome',
          startColorHex: 0xFF3F7BFF,
          endColorHex: 0xFF1E5CE6,
        ),
        StatCardData(
          label: 'Level',
          value: '12',
          unit: 'expert',
          icon: 'emoji_events',
          startColorHex: 0xFFB14CFF,
          endColorHex: 0xFF8A2BE2,
        ),
      ],
      challenge: DailyChallenge(
        title: 'Explain a complex idea simply',
        description:
            "Describe how the internet works to someone who's never used a computer. Aim for clarity and avoid jargon.",
        durationMinutes: 3,
        xpReward: 50,
      ),
      achievements: <Achievement>[
        Achievement(title: '7-Day Streak', emoji: '🔥'),
        Achievement(title: 'Clarity Master', emoji: '🎯'),
        Achievement(title: 'Quick Thinker', emoji: '⚡'),
        Achievement(title: 'Top 10%', emoji: '🏆', isLocked: true),
      ],
    );
  }
}
