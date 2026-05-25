// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talk_gym/core/constants/app_color.dart';
import 'package:talk_gym/feature/onbording/OnboardingPage.dart';
import 'package:talk_gym/feature/onbording/loading/screens/smart_loading_screen.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'We Understand How You Speak',
      description:
          'Talk naturally. TalkGym captures structure, intent, and clarity beneath every response.',
      animationAsset: 'assets/onboarding1.png', // Replace with Lottie asset
    ),
    OnboardingData(
      title: 'Train With Intelligent Feedback',
      description:
          'Your responses are refined through guided practice and instant coaching.',
      animationAsset: 'assets/onboarding2.png', // Replace with your animation asset
    ),
    OnboardingData(
      title: 'Build Interview Confidence',
      description:
          'Practice deliberately until speaking clearly becomes second nature.',
      animationAsset: 'assets/onboarding3.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              HapticFeedback.lightImpact();
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return OnboardingPage(
                data: _pages[index],
                isLastPage: index == _pages.length - 1,
              );
            },
          ),
          
          // Page indicator
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: _currentPage == index ? 24 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.pureBlack
                        : AppTheme.grayLight,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          
          // Skip/Next button
          Positioned(
            bottom: 40,
            right: 24,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (_currentPage == _pages.length - 1) {
                  // Navigate to home screen
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SmartLoadingScreen()));
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.pureBlack,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.pureBlack.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        color: AppTheme.pureWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_currentPage != _pages.length - 1) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppTheme.pureWhite,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String animationAsset;
  
  OnboardingData({
    required this.title,
    required this.description,
    required this.animationAsset,
  });
}