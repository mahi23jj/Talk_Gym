import 'package:flutter/material.dart';

class AchievementChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool achieved;

  const AchievementChip({
    super.key,
    required this.icon,
    required this.label,
    required this.achieved,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icon,
        size: 18,
        color: achieved ? Colors.amber[700] : Colors.grey[400],
      ),
      label: Text(label),
      backgroundColor: achieved 
          ? Colors.amber[100] 
          : Theme.of(context).disabledColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: achieved ? Colors.amber[900] : Colors.grey[600],
        fontWeight: achieved ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}