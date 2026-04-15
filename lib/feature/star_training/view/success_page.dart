import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/feature/star_training/viewmodel/star_training_bloc.dart';

class StarSuccessPage extends StatefulWidget {
  const StarSuccessPage({super.key});

  @override
  State<StarSuccessPage> createState() => _StarSuccessPageState();
}

class _StarSuccessPageState extends State<StarSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOutBack,
              ),
              child: Container(
                width: 78,
                height: 78,
                decoration: const BoxDecoration(
                  color: Color(0xFF222222),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Submitted Successfully',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Great work. Your STAR answer has been saved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((Route<dynamic> route) {
                    return route.isFirst;
                  }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF222222),
                foregroundColor: Colors.white,
              ),
              child: const Text('Back to Questions'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.read<StarTrainingBloc>().backToEdit(),
              child: const Text('Review again'),
            ),
          ],
        ),
      ),
    );
  }
}
