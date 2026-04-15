import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/feature/star_training/viewmodel/star_training_bloc.dart';

class CountdownPage extends StatefulWidget {
  const CountdownPage({super.key});

  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    int remaining = 3;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      remaining -= 1;
      HapticFeedback.selectionClick();

      if (!mounted) {
        return;
      }

      if (remaining <= 0) {
        context.read<StarTrainingBloc>().openFlow();
        timer.cancel();
        return;
      }

      context.read<StarTrainingBloc>().setCountdown(remaining);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StarTrainingBloc, StarTrainingState>(
      builder: (BuildContext context, StarTrainingState state) {
        final int value = state.countdownValue;
        final double progress = value / 3;

        return Container(
          color: const Color(0xFFF8F9FA),
          width: double.infinity,
          child: Stack(
            children: <Widget>[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Get ready for a real interview simulation',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _PrepCard(
                        icon: Icons.mic_none_rounded,
                        text: 'Speak clearly',
                      ),
                      const SizedBox(height: 8),
                      const _PrepCard(
                        icon: Icons.notes_rounded,
                        text: 'Be specific',
                      ),
                      const SizedBox(height: 8),
                      const _PrepCard(
                        icon: Icons.star_border_rounded,
                        text: 'Focus on YOUR actions',
                      ),
                      const SizedBox(height: 24),
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (BuildContext context, _) {
                          final double scale = 0.95 + (_pulse.value * 0.05);
                          return Transform.scale(
                            scale: scale,
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  CircularProgressIndicator(
                                    value: 1,
                                    strokeWidth: 8,
                                    color: AppColors.cardBorder,
                                  ),
                                  CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 8,
                                    color: AppColors.accent,
                                  ),
                                  Text(
                                    '$value',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Starting in $value...',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      _timer?.cancel();
                      context.read<StarTrainingBloc>().skipCountdown();
                    },
                    child: const Text(
                      'Skip preparation',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrepCard extends StatelessWidget {
  const _PrepCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
