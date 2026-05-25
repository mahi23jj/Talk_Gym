// lib/screens/smart_loading_screen.dart (Updated with MVVM)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:talk_gym/core/constants/app_color.dart';
import 'package:talk_gym/feature/auth/view/login_page.dart';
import 'package:talk_gym/feature/onbording/loading/screens/widget/IntelligenceInitAnimation.dart';
import 'package:talk_gym/feature/onbording/loading/screens/widget/complete_animation.dart';
import 'package:talk_gym/feature/onbording/loading/viewmodels/smart_loading_viewmodel.dart';


class SmartLoadingScreen extends StatefulWidget {
  const SmartLoadingScreen({super.key});

  @override
  State<SmartLoadingScreen> createState() => _SmartLoadingScreenState();
}

class _SmartLoadingScreenState extends State<SmartLoadingScreen> {
  late SmartLoadingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SmartLoadingViewModel();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.startLoadingSequence();
  }

  void _onViewModelChanged() {
    if (_viewModel.currentState == LoadingState.completed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const LoginPage(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.pureWhite,
              AppTheme.softWhite,
              AppTheme.offWhite,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Status indicator (subtle)
              if (_viewModel.healthCheckAttempts > 0 && !_viewModel.isBackendHealthy)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Establishing secure connection...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Error state
              if (_viewModel.currentState == LoadingState.error)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _viewModel.getStateDescription(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () {
                              _viewModel.dispose();
                              _viewModel = SmartLoadingViewModel();
                              _viewModel.addListener(_onViewModelChanged);
                              _viewModel.startLoadingSequence();
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.pureBlack,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Retry Connection'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Loading content
              if (_viewModel.currentState != LoadingState.error)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animation based on current state
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: _getAnimationForState(),
                        ),
                      ),
                      
                      // Text content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: Text(
                                _viewModel.getStateTitle(),
                                key: ValueKey(_viewModel.currentState),
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.pureBlack,
                                  letterSpacing: -0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: Text(
                                _viewModel.getStateSubtitle(),
                                key: ValueKey('subtitle_${_viewModel.currentState}'),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.pureBlack.withOpacity(0.8),
                                  letterSpacing: -0.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: Text(
                                _viewModel.getStateDescription(),
                                key: ValueKey('desc_${_viewModel.currentState}'),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.grayMedium,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getAnimationForState() {
    switch (_viewModel.currentState) {
      case LoadingState.initializing:
        return const IntelligenceInitAnimation();
      case LoadingState.calibrating:
        return const VoiceCalibrationAnimation();
      case LoadingState.personalizing:
        return const PersonalizingAnimation();
      case LoadingState.ready:
        return const ReadyAnimation();
      case LoadingState.completed:
        return const CompletedAnimation();
      case LoadingState.error:
        return const ErrorAnimation();
    }
  }
}