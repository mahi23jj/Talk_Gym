// lib/widgets/onboarding_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:talk_gym/core/constants/app_color.dart';
import 'package:talk_gym/feature/onbording/OnboardingScreen.dart';


class OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final bool isLastPage;
  
  const OnboardingPage({
    super.key,
    required this.data,
    required this.isLastPage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation/Illustration space
          Expanded(
            flex: 3,
            child: Center(
              child: Container(
                width: double.infinity,
                height: 400,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.pureBlack.withOpacity(0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.softWhite,
                            AppTheme.pureWhite,
                          ],
                        ),
                      ),
                      child: Image.asset(
                        data.animationAsset,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.waves,
                            size: 120,
                            color: AppTheme.pureBlack.withOpacity(0.15),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Title
          SlideTransition(
            position: const AlwaysStoppedAnimation(Offset.zero),
            child: FadeTransition(
              opacity: const AlwaysStoppedAnimation(1.0),
              child: Text(
                data.title,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.pureBlack,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            data.description,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: AppTheme.grayDark,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}