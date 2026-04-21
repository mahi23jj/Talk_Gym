import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/core/widget/recording.dart';
import 'package:talk_gym/feature/star_training/data/model/star_training_models.dart';
import 'package:talk_gym/feature/star_training/viewmodel/star_training_bloc.dart';

class StarFlowPage extends StatelessWidget {
  const StarFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StarTrainingBloc, StarTrainingState>(
      builder: (BuildContext context, StarTrainingState state) {
        final StarStepContent step = state.activeStep!;

        return SafeArea(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ProgressHeader(
                  steps: state.session!.steps,
                  currentStep: state.currentStep,
                  completedSteps: state.completedSteps,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'STEP ${state.currentStep + 1} OF 4',
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 1,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          Text(
                            step.part.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(step.icon, style: const TextStyle(fontSize: 22)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          step.prompt,
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          step.example,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      VoiceRecorderWidget(
                        key: ValueKey<StarPart>(step.part),
                        filePrefix: 'star_${step.part.name}',
                        showTextToggle: true,
                        textMode: state.isTextMode,
                        initialText: state.answerFor(step.part).text,
                        initialPath: state.answerFor(step.part).audioPath,
                        initialDuration:
                            state.answerFor(step.part).durationSeconds ?? 0,
                        initialWaveform: state.answerFor(step.part).waveform,
                        onTextModeToggle: () =>
                            context.read<StarTrainingBloc>().toggleTextMode(),
                        onTextChanged: (String value) => context
                            .read<StarTrainingBloc>()
                            .setTextAnswer(step.part, value),
                        onFinished:
                            (String path, int seconds, List<double> waveform) {
                              context.read<StarTrainingBloc>().saveVoiceAnswer(
                                part: step.part,
                                audioPath: path,
                                durationSeconds: seconds,
                                waveform: waveform,
                              );
                            },
                        onCleared: () => context
                            .read<StarTrainingBloc>()
                            .clearAnswer(step.part),
                      ),
                      if (state.durationWarning != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            border: Border(
                              left: BorderSide(
                                color: AppColors.textTertiary,
                                width: 3,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            state.durationWarning!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context
                            .read<StarTrainingBloc>()
                            .clearAnswer(step.part),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF222222),
                          side: const BorderSide(color: Color(0xFF222222)),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text('Re-record'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: state.canGoNext
                            ? () {
                                HapticFeedback.selectionClick();
                                context.read<StarTrainingBloc>().nextStep();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF222222),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text('Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.steps,
    required this.currentStep,
    required this.completedSteps,
  });

  final List<StarStepContent> steps;
  final int currentStep;
  final Set<int> completedSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: List<Widget>.generate(steps.length, (int index) {
            final bool active = index <= currentStep;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: index == steps.length - 1 ? 0 : 8,
                ),
                height: 4,
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          children: List<Widget>.generate(steps.length, (int index) {
            final bool active = index == currentStep;
            final bool canTap = completedSteps.contains(index) || active;
            return Expanded(
              child: InkWell(
                onTap: canTap
                    ? () => context.read<StarTrainingBloc>().jumpToStep(index)
                    : null,
                child: Text(
                  steps[index].part.shortLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: active ? AppColors.accent : AppColors.textTertiary,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
