import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/feature/star_training/data/model/star_training_models.dart';
import 'package:talk_gym/feature/star_training/viewmodel/star_training_bloc.dart';

class StarReviewPage extends StatefulWidget {
  const StarReviewPage({super.key});

  @override
  State<StarReviewPage> createState() => _StarReviewPageState();
}

class _StarReviewPageState extends State<StarReviewPage> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playIfAvailable(String? path) async {
    if (path == null) {
      return;
    }
    await _player.setFilePath(path);
    await _player.play();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StarTrainingBloc, StarTrainingState>(
      builder: (BuildContext context, StarTrainingState state) {
        final StarTrainingSession session = state.session!;

        return Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Your Complete STAR Answer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            context.read<StarTrainingBloc>().backToEdit(),
                        child: const Text('Edit All'),
                      ),
                    ),
                    ...session.steps.map((StarStepContent step) {
                      final StarAnswer answer = state.answerFor(step.part);
                      return _ReviewCard(
                        step: step,
                        answer: answer,
                        onPlay: () => _playIfAvailable(answer.audioPath),
                        onEdit: () {
                          final int idx = session.steps.indexOf(step);
                          context.read<StarTrainingBloc>().jumpToStep(idx);
                          context.read<StarTrainingBloc>().backToEdit();
                        },
                      );
                    }),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        session.feedback,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          context.read<StarTrainingBloc>().backToEdit(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: const Color(0xFF222222),
                        side: const BorderSide(color: Color(0xFF222222)),
                      ),
                      child: const Text('Back to Edit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: state.status == StarTrainingStatus.submitting
                          ? null
                          : () =>
                                context.read<StarTrainingBloc>().submitFinal(),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: const Color(0xFF222222),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Submit Final Answer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.step,
    required this.answer,
    required this.onPlay,
    required this.onEdit,
  });

  final StarStepContent step;
  final StarAnswer answer;
  final VoidCallback onPlay;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final String duration = answer.durationSeconds == null
        ? '--:--'
        : '${answer.durationSeconds! ~/ 60}:${(answer.durationSeconds! % 60).toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: Text(
          '${step.part.shortLabel} - ${step.part.title}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          answer.hasVoice ? 'Voice recording saved' : 'No voice recording yet',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.graphic_eq_rounded,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                duration,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const Spacer(),
              IconButton(
                onPressed: answer.hasVoice ? onPlay : null,
                icon: const Icon(Icons.play_arrow_rounded),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            answer.hasText ? answer.text : 'Voice recording saved',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
