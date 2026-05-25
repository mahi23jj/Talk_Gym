// // lib/screens/smart_loading_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'dart:ui';
// import 'dart:async';
// import 'package:talk_gym/core/constants/app_color.dart';
// import 'package:talk_gym/core/navigation/app_routes.dart';
// import 'package:talk_gym/feature/onbording/loading/screens/widget/IntelligenceInitAnimation.dart';


// class SmartLoadingScreen extends StatefulWidget {
//   const SmartLoadingScreen({super.key});

//   @override
//   State<SmartLoadingScreen> createState() => _SmartLoadingScreenState();
// }

// class _SmartLoadingScreenState extends State<SmartLoadingScreen>
//     with TickerProviderStateMixin {
//   late PageController _pageController;
//   int _currentStep = 0;
//   Timer? _stepTimer;
  
//   final List<LoadingStep> _steps = [
//     LoadingStep(
//       title: 'Initializing Intelligence',
//       subtitle: 'Preparing your training environment',
//       description: 'Setting the foundation for focused interview practice.',
//       animationBuilder: (animation) => const IntelligenceInitAnimation(),
//     ),
//     LoadingStep(
//       title: 'Calibrating Voice Analysis',
//       subtitle: 'Calibrating communication signals',
//       description: 'Aligning for precision feedback.',
//       animationBuilder: (animation) => const VoiceCalibrationAnimation(),
//     ),
//     LoadingStep(
//       title: 'Personalizing Coaching',
//       subtitle: 'Adapting to your practice style',
//       description: 'Creating your personalized coaching flow.',
//       animationBuilder: (animation) => const PersonalizingAnimation(),
//     ),
//     LoadingStep(
//       title: 'Ready',
//       subtitle: 'Your coach is ready',
//       description: 'Let\'s train your next breakthrough.',
//       animationBuilder: (animation) => const ReadyAnimation(),
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController();
//     _startLoadingSequence();
    
//     // Simulate API health check in background
//     _simulateBackendWarmup();
//   }

//   void _startLoadingSequence() {
//     _stepTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
//       if (_currentStep < _steps.length - 1) {
//         setState(() {
//           _currentStep++;
//         });
//         _pageController.animateToPage(
//           _currentStep,
//           duration: const Duration(milliseconds: 600),
//           curve: Curves.easeInOutCubic,
//         );
//         HapticFeedback.lightImpact();
//       } else {
//         timer.cancel();
//         // Navigate to home screen after completion
//         Future.delayed(const Duration(milliseconds: 500), () {
//           if (mounted) {
//             Navigator.of(context).pushReplacementNamed(AppRoutes.home);
//           }
//         });
//       }
//     });
//   }

//   void _simulateBackendWarmup() {
//     // Simulate API health check without showing technical details
//     Future.delayed(const Duration(milliseconds: 500), () {
//       // This runs in background - user doesn't see "connecting to database"
//       debugPrint('Backend warming up silently...');
//     });
//   }

//   @override
//   void dispose() {
//     _stepTimer?.cancel();
//     _pageController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppTheme.pureWhite,
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               AppTheme.pureWhite,
//               AppTheme.softWhite,
//               AppTheme.offWhite,
//             ],
//             stops: const [0.0, 0.6, 1.0],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // Progress indicator
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: List.generate(
//                     _steps.length,
//                     (index) => AnimatedContainer(
//                       duration: const Duration(milliseconds: 400),
//                       margin: const EdgeInsets.symmetric(horizontal: 6),
//                       width: _currentStep >= index ? 32 : 6,
//                       height: 6,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(3),
//                         color: _currentStep >= index
//                             ? AppTheme.pureBlack
//                             : AppTheme.grayLight,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
              
//               // PageView for loading steps
//               Expanded(
//                 child: PageView.builder(
//                   controller: _pageController,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: _steps.length,
//                   itemBuilder: (context, index) {
//                     return LoadingStepWidget(
//                       step: _steps[index],
//                       isActive: index == _currentStep,
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class LoadingStep {
//   final String title;
//   final String subtitle;
//   final String description;
//   final Widget Function(Animation<double>) animationBuilder;
  
//   LoadingStep({
//     required this.title,
//     required this.subtitle,
//     required this.description,
//     required this.animationBuilder,
//   });
// }

// class LoadingStepWidget extends StatefulWidget {
//   final LoadingStep step;
//   final bool isActive;
  
//   const LoadingStepWidget({
//     super.key,
//     required this.step,
//     required this.isActive,
//   });

//   @override
//   State<LoadingStepWidget> createState() => _LoadingStepWidgetState();
// }

// class _LoadingStepWidgetState extends State<LoadingStepWidget>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _fadeController;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _fadeController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
    
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
//     );
    
//     _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
//       CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
//     );
    
//     if (widget.isActive) {
//       _fadeController.forward();
//     }
//   }

//   @override
//   void didUpdateWidget(LoadingStepWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.isActive && !oldWidget.isActive) {
//       _fadeController.reset();
//       _fadeController.forward();
//     }
//   }

//   @override
//   void dispose() {
//     _fadeController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 32),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Animation
//           Expanded(
//             flex: 3,
//             child: Center(
//               child: FadeTransition(
//                 opacity: _fadeAnimation,
//                 child: widget.step.animationBuilder(_fadeAnimation),
//               ),
//             ),
//           ),
          
//           // Text content
//           FadeTransition(
//             opacity: _fadeAnimation,
//             child: SlideTransition(
//               position: Tween<Offset>(
//                 begin: const Offset(0, 0.1),
//                 end: Offset.zero,
//               ).animate(CurvedAnimation(
//                 parent: _fadeController,
//                 curve: Curves.easeOutCubic,
//               )),
//               child: Column(
//                 children: [
//                   Text(
//                     widget.step.title,
//                     style: const TextStyle(
//                       fontSize: 34,
//                       fontWeight: FontWeight.w700,
//                       color: AppTheme.pureBlack,
//                       letterSpacing: -0.3,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     widget.step.subtitle,
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w500,
//                       color: AppTheme.pureBlack.withOpacity(0.8),
//                       letterSpacing: -0.2,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     widget.step.description,
//                     style: TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w400,
//                       color: AppTheme.grayMedium,
//                       height: 1.4,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//           ),
          
//           const Spacer(flex: 1),
//         ],
//       ),
//     );
//   }
// }