enum JourneyNodeState { completed, current, upcoming, locked }

class JourneyNode {
  const JourneyNode({
    required this.id,
    required this.title,
    required this.prompt,
    required this.centerX,
    required this.top,
    required this.state,
    required this.level,
    this.stars = 0,
  });

  final String id;
  final String title;
  final String prompt;
  final double centerX;
  final double top;
  final JourneyNodeState state;
  final int level;
  final int stars;
}

class JourneyData {
  const JourneyData({
    required this.title,
    required this.subtitle,
    required this.nodes,
  });

  final String title;
  final String subtitle;
  final List<JourneyNode> nodes;
}
