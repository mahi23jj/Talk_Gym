import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/feature/analysis_results/data/model/analysis_result.dart';
import 'package:talk_gym/feature/question/data/model/question_item.dart';
import 'package:talk_gym/feature/star_training/data/model/star_training_models.dart';
import 'package:talk_gym/feature/star_training/data/repository/mock_star_training_repository.dart';
import 'package:talk_gym/feature/star_training/view/countdown_page.dart';
import 'package:talk_gym/feature/star_training/view/review_page.dart';
import 'package:talk_gym/feature/star_training/view/star_flow_page.dart';
import 'package:talk_gym/feature/star_training/view/success_page.dart';
import 'package:talk_gym/feature/star_training/view/welcome_page.dart';
import 'package:talk_gym/feature/star_training/viewmodel/star_training_bloc.dart';

class StarTrainingPage extends StatelessWidget {
  const StarTrainingPage({required this.question,required this.starmetrics ,super.key});

  final QuestionItem question;
  final StarMetrics starmetrics;



  @override
  Widget build(BuildContext context) {
    return BlocProvider<StarTrainingBloc>(
      create: (_) =>
          StarTrainingBloc(repository: MockStarTrainingRepository())
            ..load(question, starmetrics),
      child: const _StarTrainingViewHost(),
    );
  }
}

class _StarTrainingViewHost extends StatelessWidget {
  const _StarTrainingViewHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<StarTrainingBloc, StarTrainingState>(
          builder: (BuildContext context, StarTrainingState state) {
            if (state.status == StarTrainingStatus.loading ||
                state.status == StarTrainingStatus.initial) {
              return const _LoadingState();
            }

            if (state.status == StarTrainingStatus.failure) {
              return _ErrorState(
                message:
                    state.errorMessage ??
                    'Failed to load question. Please try again.',
                onRetry: () {
                  final StarTrainingSession? session = state.session;
                  final QuestionItem target =
                      session?.question ??
                      const QuestionItem(
                        id: -2,
                        title:
                            'Tell me about a time you faced a conflict at work',
                        description: 'Practice with STAR.',
                        tags: <String>['Conflict', 'Leadership'],
                        dayUnlock: 1,
                      );

                      final StarMetrics metrics = const StarMetrics(
                        situation: 'N/A',
                        task: 'N/A',
                        action: 'N/A',
                        result: 'N/A',
                      );
                  context.read<StarTrainingBloc>().load(target , metrics);
                },
              );
            }

            final Widget page = switch (state.stage) {
              StarTrainingStage.welcome => const WelcomePage(),
              StarTrainingStage.countdown => const CountdownPage(),
              StarTrainingStage.flow => const StarFlowPage(),
              StarTrainingStage.review => const StarReviewPage(),
              StarTrainingStage.success => const StarSuccessPage(),
            };

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey<StarTrainingStage>(state.stage),
                child: page,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    Widget line({required double width, required double height}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 40),
          line(width: 280, height: 36),
          const SizedBox(height: 12),
          line(width: 220, height: 16),
          const SizedBox(height: 24),
          line(width: double.infinity, height: 120),
          const SizedBox(height: 16),
          line(width: double.infinity, height: 90),
          const Spacer(),
          line(width: double.infinity, height: 50),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.textSecondary,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
