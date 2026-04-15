import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/feature/star_training/data/model/star_training_models.dart';
import 'package:talk_gym/feature/star_training/viewmodel/star_training_bloc.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StarTrainingBloc, StarTrainingState>(
      builder: (BuildContext context, StarTrainingState state) {
        final StarTrainingSession session = state.session!;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _HeroVisual(socialProof: session.socialProof),
              const SizedBox(height: 22),
              const Text(
                'Learn how to answer interview questions like a pro',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 320),
                  child: Text(
                    'Top candidates do not just answer. They structure their story clearly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _StarGrid(),
              const SizedBox(height: 14),
              _ExampleCard(
                expanded: state.isExampleExpanded,
                onTap: () => context.read<StarTrainingBloc>().toggleExample(),
              ),
              const SizedBox(height: 22),
              const Text(
                'You will now practice step-by-step like a real interview',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () =>
                      context.read<StarTrainingBloc>().openCountdown(),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF222222),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Start Training',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

class _HeroVisual extends StatefulWidget {
  const _HeroVisual({required this.socialProof});

  final String socialProof;

  @override
  State<_HeroVisual> createState() => _HeroVisualState();
}

class _HeroVisualState extends State<_HeroVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 86,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(7, (int index) {
                  final double factor =
                      ((_controller.value + (index * 0.1)) % 1.0) * 12;
                  final double size = 8 + (factor % 9);
                  return Container(
                    width: size,
                    height: size,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.socialProof,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _StarGrid extends StatelessWidget {
  const _StarGrid();

  @override
  Widget build(BuildContext context) {
    const List<(String, String)> rows = <(String, String)>[
      ('S', 'Situation: What was happening?'),
      ('T', 'Task: What was your responsibility?'),
      ('A', 'Action: What did YOU do?'),
      ('R', 'Result: What changed because of you?'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (BuildContext context, int index) {
        final (String letter, String text) = rows[index];
        final int delay = index * 100;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 340 + delay),
          curve: Curves.easeOut,
          builder: (BuildContext context, double value, Widget? child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
          color: AppColors.background,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Example - See STAR in action',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            if (expanded) ...<Widget>[
              const SizedBox(height: 8),
              const Text(
                'Bad: Our server was slow.',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  decoration: TextDecoration.lineThrough,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Good: During peak traffic, I owned API latency improvements by adding caching and indexes; response time dropped by 42 percent.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
