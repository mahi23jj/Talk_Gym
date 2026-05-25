// lib/widgets/loading_animations.dart (Add these new animations)
// Add these to the existing loading_animations.dart file

// Completed Animation
import 'package:flutter/material.dart';
import 'package:talk_gym/core/constants/app_color.dart';

class CompletedAnimation extends StatefulWidget {
  const CompletedAnimation({super.key});

  @override
  State<CompletedAnimation> createState() => _CompletedAnimationState();
}

class _CompletedAnimationState extends State<CompletedAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _checkAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.pureBlack.withOpacity(_glowAnimation.value * 0.15),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100 * _checkAnimation.value,
                  height: 100 * _checkAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.pureBlack.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: _checkAnimation.value,
                  child: Icon(
                    Icons.check_rounded,
                    size: 50,
                    color: AppTheme.pureBlack.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Error Animation
class ErrorAnimation extends StatelessWidget {
  const ErrorAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.signal_wifi_off_rounded,
          size: 50,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}