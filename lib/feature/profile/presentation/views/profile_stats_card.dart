import 'package:flutter/material.dart';

class StatItem {
  final String label;
  final String value;
  final String subtitle;
  final bool isWarning;

  StatItem({
    required this.label,
    required this.value,
    required this.subtitle,
    this.isWarning = false,
  });
}

class ProfileStatsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<StatItem> stats;
  final double? progress;

  const ProfileStatsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.stats,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (progress != null) ...[
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(
                  progress! > 0.8 ? Colors.orange : Theme.of(context).colorScheme.primary,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: stats.map((stat) => _StatItemWidget(stat: stat)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItemWidget extends StatelessWidget {
  final StatItem stat;

  const _StatItemWidget({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: stat.isWarning ? Colors.red : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}