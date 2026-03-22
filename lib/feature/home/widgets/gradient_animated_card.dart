// lib/home/widgets/gradient_animated_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talk_gym/core/Appcolor.dart';
import 'package:talk_gym/core/Theme/theme_provider.dart';

class GradientAnimatedCard extends StatefulWidget {
  const GradientAnimatedCard({
    required this.child,
    super.key,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<GradientAnimatedCard> createState() => _GradientAnimatedCardState();
}

class _GradientAnimatedCardState extends State<GradientAnimatedCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    
    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  if (_glowAnimation.value > 0)
                    BoxShadow(
                      color: (isDark 
                          ? AppColors.darkPrimary 
                          : AppColors.lightPrimary).withOpacity(0.3 * _glowAnimation.value),
                      blurRadius: 20 * _glowAnimation.value,
                      spreadRadius: 4 * _glowAnimation.value,
                    ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}