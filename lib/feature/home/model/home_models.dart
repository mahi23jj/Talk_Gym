class DailyChallenge {
  const DailyChallenge({
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.xpReward,
  });

  final String title;
  final String description;
  final int durationMinutes;
  final int xpReward;
}

class StatCardData {
  const StatCardData({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.startColorHex,
    required this.endColorHex,
  });

  final String label;
  final String value;
  final String unit;
  final String icon;
  final int startColorHex;
  final int endColorHex;
}

class Achievement {
  const Achievement({
    required this.title,
    required this.emoji,
    this.isLocked = false,
  });

  final String title;
  final String emoji;
  final bool isLocked;
}

class HomeDashboardData {
  const HomeDashboardData({
    required this.userName,
    required this.stats,
    required this.challenge,
    required this.achievements,
  });

  final String userName;
  final List<StatCardData> stats;
  final DailyChallenge challenge;
  final List<Achievement> achievements;
}
