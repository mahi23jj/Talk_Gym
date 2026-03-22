// lib/home/widgets/animated_stat_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talk_gym/core/Appcolor.dart';
import 'package:talk_gym/core/Theme/theme_provider.dart';
import 'package:talk_gym/feature/home/model/home_models.dart';

class AnimatedStatCard extends StatelessWidget {
  const AnimatedStatCard({required this.data, super.key});

  final StatCardData data;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [AppColors.darkPrimary, AppColors.darkSecondary]
                : [Color(data.startColorHex), Color(data.endColorHex)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: (isDark 
                  ? AppColors.darkPrimary 
                  : Color(data.endColorHex)).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                // Icon(_iconFromName(data.icon), size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  data.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              data.value,
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              data.unit,
              style: const TextStyle(
                color: Color(0xFFE8EEFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


