import 'package:flutter/material.dart';
import 'package:talk_gym/core/appcolor.dart';

class AiCallCounter extends StatelessWidget {
  const AiCallCounter({required this.remaining, super.key});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        'AI Evaluations Left: $remaining',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
