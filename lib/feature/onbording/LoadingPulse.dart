// lib/widgets/loading_pulse.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class LoadingPulse extends StatefulWidget {
  const LoadingPulse({super.key});

  @override
  State<LoadingPulse> createState() => _LoadingPulseState();
}

class _LoadingPulseState extends State<LoadingPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1 * (1 - _pulseAnimation.value)),
                    blurRadius: 10 * (1 + _pulseAnimation.value),
                    spreadRadius: 2 * _pulseAnimation.value,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: LoadingPulsePainter(
                  progress: _pulseAnimation.value,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preparing your journey',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.4),
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
      },
    );
  }
}

class LoadingPulsePainter extends CustomPainter {
  final double progress;
  
  LoadingPulsePainter({required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.3 + progress * 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final double dashProgress = progress;
    final double startAngle = -90 * (3.14159 / 180);
    final double sweepAngle = 360 * (3.14159 / 180) * dashProgress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
    
    // Draw dots
    final Paint dotPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 3; i++) {
      final double angle = startAngle + sweepAngle * (i / 2);
      final double dotX = center.dx + (radius - 6) * math.cos(angle);
      final double dotY = center.dy + (radius - 6) * math.sin(angle);
      canvas.drawCircle(Offset(dotX, dotY), 2, dotPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant LoadingPulsePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}