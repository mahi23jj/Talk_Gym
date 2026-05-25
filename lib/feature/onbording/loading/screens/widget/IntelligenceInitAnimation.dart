// lib/widgets/loading_animations.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:talk_gym/core/constants/app_color.dart';

// LOADING 1 — Initializing Intelligence
class IntelligenceInitAnimation extends StatefulWidget {
  const IntelligenceInitAnimation({super.key});

  @override
  State<IntelligenceInitAnimation> createState() => _IntelligenceInitAnimationState();
}

class _IntelligenceInitAnimationState extends State<IntelligenceInitAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _ring1Animation;
  late Animation<double> _ring2Animation;
  late Animation<double> _ring3Animation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _ring1Animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeInOut)),
    );
    
    _ring2Animation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.7, curve: Curves.easeInOut)),
    );
    
    _ring3Animation = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.9, curve: Curves.easeInOut)),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
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
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.pureBlack.withOpacity(_pulseAnimation.value * 0.1),
                  blurRadius: 40,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ring 3 (outer)
                Container(
                  width: 180 * _ring3Animation.value,
                  height: 180 * _ring3Animation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.pureBlack.withOpacity(0.08),
                      width: 1.5,
                    ),
                  ),
                ),
                // Ring 2 (middle)
                Container(
                  width: 140 * _ring2Animation.value,
                  height: 140 * _ring2Animation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.pureBlack.withOpacity(0.12),
                      width: 2,
                    ),
                  ),
                ),
                // Ring 1 (inner)
                Container(
                  width: 100 * _ring1Animation.value,
                  height: 100 * _ring1Animation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.pureBlack.withOpacity(0.2),
                      width: 2.5,
                    ),
                  ),
                ),
                // Center core
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.pureBlack.withOpacity(0.05),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.pureBlack.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.pureBlack.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
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

// LOADING 2 — Calibrating Voice Analysis
class VoiceCalibrationAnimation extends StatefulWidget {
  const VoiceCalibrationAnimation({super.key});

  @override
  State<VoiceCalibrationAnimation> createState() => _VoiceCalibrationAnimationState();
}

class _VoiceCalibrationAnimationState extends State<VoiceCalibrationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _particleAnimations;
  late Animation<double> _waveformAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _particleAnimations = List.generate(12, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.08,
            index * 0.08 + 0.5,
            curve: Curves.easeInOutSine,
          ),
        ),
      );
    });
    
    _waveformAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
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
            width: 220,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Floating particles
                ...List.generate(12, (index) {
                  final angle = (index * 30) * (3.14159 / 180);
                  final radius = 60.0;
                  final x = radius * cos(angle);
                  final y = radius * sin(angle);
                  
                  return Positioned(
                    left: 110 + x * _particleAnimations[index].value,
                    top: 75 + y * _particleAnimations[index].value,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.pureBlack.withOpacity(
                          0.2 * (1 - _particleAnimations[index].value),
                        ),
                      ),
                    ),
                  );
                }),
                
                // Waveform bars
                ...List.generate(7, (index) {
                  final height = 20.0 * _waveformAnimation.value * (1 + index * 0.3);
                  return Positioned(
                    left: 60 + index * 18.0,
                    bottom: 75 - height / 2,
                    child: Container(
                      width: 6,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppTheme.pureBlack.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
                
                // Stable center waveform
                CustomPaint(
                  size: const Size(200, 80),
                  painter: WaveformPainter(
                    progress: _waveformAnimation.value,
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

// LOADING 3 — Personalizing Coaching
class PersonalizingAnimation extends StatefulWidget {
  const PersonalizingAnimation({super.key});

  @override
  State<PersonalizingAnimation> createState() => _PersonalizingAnimationState();
}

class _PersonalizingAnimationState extends State<PersonalizingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flowAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    _flowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    
    _rotateAnimation = Tween<double>(begin: 0.0, end: 360.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
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
          child: Transform.rotate(
            angle: _rotateAnimation.value * (3.14159 / 180),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.pureBlack.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                // Flowing energy streams
                CustomPaint(
                  size: const Size(160, 160),
                  painter: FlowStreamPainter(progress: _flowAnimation.value),
                ),
                // Adaptive paths
                CustomPaint(
                  size: const Size(160, 160),
                  painter: AdaptivePathPainter(progress: _flowAnimation.value),
                ),
                // Center waveform
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.pureBlack.withOpacity(0.03),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.waves,
                      size: 30,
                      color: AppTheme.pureBlack.withOpacity(0.2),
                    ),
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

// LOADING 4 — Ready
class ReadyAnimation extends StatefulWidget {
  const ReadyAnimation({super.key});

  @override
  State<ReadyAnimation> createState() => _ReadyAnimationState();
}

class _ReadyAnimationState extends State<ReadyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _stabilizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _expandAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    
    _stabilizeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
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
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.pureBlack.withOpacity(_glowAnimation.value * 0.15),
                  blurRadius: 50,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Expanding energy rings
                Container(
                  width: 180 * _expandAnimation.value,
                  height: 180 * _expandAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.pureBlack.withOpacity(0.08),
                        Colors.transparent,
                      ],
                      radius: 1.0,
                    ),
                  ),
                ),
                // Refined waveform symbol
                CustomPaint(
                  size: const Size(120, 80),
                  painter: RefinedWaveformPainter(
                    progress: _stabilizeAnimation.value,
                  ),
                ),
                // Center dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.pureBlack.withOpacity(0.4),
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

// Custom Painters
class WaveformPainter extends CustomPainter {
  final double progress;
  
  WaveformPainter({required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.pureBlack.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final path = Path();
    final centerY = size.height / 2;
    final width = size.width;
    
    for (double x = 0; x <= width; x += 10) {
      final y = centerY + 
          sin(x * 0.1 + progress * 4) * 15 * progress +
          cos(x * 0.15) * 8;
      
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class FlowStreamPainter extends CustomPainter {
  final double progress;
  
  FlowStreamPainter({required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.pureBlack.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final angle = i * 120 + progress * 360;
      final startAngle = angle * (3.14159 / 180);
      
      for (double t = 0; t <= 1; t += 0.05) {
        final r = radius * (0.3 + t * 0.7);
        final a = startAngle + t * 2 * 3.14159;
        final x = center.dx + r * cos(a);
        final y = center.dy + r * sin(a);
        
        if (t == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant FlowStreamPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class AdaptivePathPainter extends CustomPainter {
  final double progress;
  
  AdaptivePathPainter({required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.pureBlack.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final path = Path();
    for (double angle = 0; angle <= 360; angle += 10) {
      final rad = angle * (3.14159 / 180);
      final r = radius * (0.4 + sin(angle * 3 + progress * 360) * 0.1);
      final x = center.dx + r * cos(rad);
      final y = center.dy + r * sin(rad);
      
      if (angle == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant AdaptivePathPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class RefinedWaveformPainter extends CustomPainter {
  final double progress;
  
  RefinedWaveformPainter({required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.pureBlack.withOpacity(0.3 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    
    final path = Path();
    final centerY = size.height / 2;
    final width = size.width;
    final left = (size.width - width) / 2;
    
    for (double x = 0; x <= width; x += 5) {
      final y = centerY + 
          sin(x * 0.12) * 12 * progress +
          cos(x * 0.08) * 6 * progress;
      
      if (x == 0) {
        path.moveTo(left + x, y);
      } else {
        path.lineTo(left + x, y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw confidence pulse at center
    final pulsePaint = Paint()
      ..color = AppTheme.pureBlack.withOpacity(0.15 * progress)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width / 2, centerY),
      4 * progress,
      pulsePaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant RefinedWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}