import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/feature/analysis_results/data/model/analysis_result.dart';
import 'package:talk_gym/feature/behavioral_training/bloc/training_bloc.dart';
import 'package:talk_gym/feature/behavioral_training/bloc/training_event.dart';
import 'package:talk_gym/feature/behavioral_training/bloc/training_state.dart';
import 'package:talk_gym/feature/behavioral_training/data/model/behavioral_training_result.dart';
import 'package:talk_gym/feature/behavioral_training/data/repository/http_behavioral_training_repository.dart';
import 'package:talk_gym/feature/question/data/model/interview_mode.dart';
import 'package:talk_gym/feature/question/data/model/question_item.dart';
import 'package:talk_gym/feature/question/view/question_detail_page.dart';

class TrainingEditorScreen extends StatelessWidget {
  const TrainingEditorScreen({
    required this.analysisResult,
    this.finalAttemptId,
    super.key,
  });

  final AnalysisResult analysisResult;
  final int? finalAttemptId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TrainingBloc>(
      create: (_) => TrainingBloc(
        repository: HttpBehavioralTrainingRepository(),
      )..add(
          LoadBehavioralTrainingEvent(
            analysisResult: analysisResult,
            attemptId: finalAttemptId ?? 0,
          ),
        ),
      child: _TrainingEditorView(finalAttemptId: finalAttemptId),
    );
  }
}

class _TrainingEditorView extends StatefulWidget {
  const _TrainingEditorView({required this.finalAttemptId});

  final int? finalAttemptId;

  @override
  State<_TrainingEditorView> createState() => _TrainingEditorViewState();
}

class _TrainingEditorViewState extends State<_TrainingEditorView> {
  final Map<int, TextEditingController> _controllers = <int, TextEditingController>{};
  int _lastFinalInterviewRequestId = 0;
  final Map<int, GlobalKey> _feedbackKeys = {};

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  TextEditingController _controllerFor(int index, String text) {
    final TextEditingController existing = _controllers[index] ?? TextEditingController(text: text);
    if (_controllers[index] == null) {
      _controllers[index] = existing;
    }
    if (existing.text != text) {
      existing.value = existing.value.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
        composing: TextRange.empty,
      );
    }
    return existing;
  }

  void _syncControllers(TrainingState state) {
    final Set<int> activeIndices = state.orderedSentenceIndices.toSet();

    for (final int index in activeIndices) {
      _controllerFor(index, state.sentenceTextFor(index));
      _feedbackKeys.putIfAbsent(index, () => GlobalKey());
    }

    final List<int> removed = _controllers.keys.where((int key) => !activeIndices.contains(key)).toList(growable: false);
    for (final int index in removed) {
      _controllers[index]?.dispose();
      _controllers.remove(index);
      _feedbackKeys.remove(index);
    }
  }

  void _showErrorPopup(BuildContext context, SentenceFeedback feedback) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFE53935)),
              const SizedBox(width: 8),
              const Text('Error & Improvement'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Issue Detected:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(feedback.issue, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 12),
                    const Text(
                      'Recommendation:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feedback.improvedExample,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openFinalInterview(TrainingState state) async {
    final int attemptId = widget.finalAttemptId ?? state.attemptId;
    if (attemptId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing attempt id for final interview.')),
      );
      return;
    }

    final AnalysisResult? analysis = state.analysisResult;
    final String questionText = analysis?.behavioralQuestions.isNotEmpty == true
        ? analysis!.behavioralQuestions.first.question
        : 'Tell me about a time you showed ownership.';

    final QuestionItem item = QuestionItem(
      id: analysis?.behavioralQuestions.isNotEmpty == true
          ? questionText.hashCode
          : -999,
      title: questionText,
      description: 'Deliver your final behavioral answer in interview conditions.',
      tags: const <String>['Behavioral', 'Final Interview'],
      dayUnlock: 1,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuestionDetailPage(
          item: item,
          mode: InterviewMode.finalInterview,
          finalAttemptId: attemptId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavioral Training'),
        actions: <Widget>[
          BlocBuilder<TrainingBloc, TrainingState>(
            builder: (BuildContext context, TrainingState state) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Attempt ${(state.attemptsUsed + 1).clamp(1, state.maxAttempts)}/${state.maxAttempts}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<TrainingBloc, TrainingState>(
          listener: (BuildContext context, TrainingState state) {
            _syncControllers(state);

            if (state.systemMessage != null && state.systemMessage!.trim().isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.systemMessage!)),
              );
              context.read<TrainingBloc>().add(const ClearSystemMessageEvent());
            }

            if (state.errorMessage != null && state.errorMessage!.trim().isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
              context.read<TrainingBloc>().add(const ClearSystemMessageEvent());
            }

            if (state.finalInterviewRequestId != _lastFinalInterviewRequestId) {
              _lastFinalInterviewRequestId = state.finalInterviewRequestId;
              unawaited(_openFinalInterview(state));
            }
          },
          builder: (BuildContext context, TrainingState state) {
            _syncControllers(state);
            final TrainingBloc bloc = context.read<TrainingBloc>();

            if (state.isLoading || !state.hasLoadedAnalysis) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final AnalysisResult analysis = state.analysisResult!;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SummaryCard(
                    analysis: analysis,
                    attemptsUsed: state.attemptsUsed,
                    maxAttempts: state.maxAttempts,
                    canTakeFinalInterview: state.canTakeFinalInterview,
                    hasPassed: state.hasPassed,
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: 'Behavioral coaching prompts',
                    subtitle: 'Improve your answer using the prompts below:',
                  ),
                  const SizedBox(height: 10),
                  if (state.coachingQuestions.isEmpty)
                    const _EmptyCard(
                      text: 'No behavioral prompts were returned by the backend.',
                    )
                  else
                    ...state.coachingQuestions.map(
                      (BehavioralQuestions question) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PromptCard(question: question),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _SectionHeader(
                    title: 'Editable transcript',
                    subtitle: 'Tap on any highlighted sentence to see errors and recommendations.',
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...state.orderedSentenceIndices.map(
                          (int index) {
                            final SentenceFeedback? feedback = state.feedbackFor(index);
                            final TextEditingController controller =
                                _controllerFor(index, state.sentenceTextFor(index));
                            final bool hasError = feedback != null;
                            
                            return GestureDetector(
                              key: _feedbackKeys[index],
                              onTap: hasError
                                  ? () => _showErrorPopup(context, feedback!)
                                  : null,
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: hasError 
                                      ? const Color(0x1AE53935)  // Light red tint
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: TextField(
                                  controller: controller,
                                  onChanged: (String value) {
                                    bloc.add(
                                      UpdateTranscriptSentenceEvent(
                                        sentenceIndex: index,
                                        text: value,
                                      ),
                                    );
                                  },
                                  maxLines: null,
                                  minLines: 1,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: AppColors.textPrimary,
                                    backgroundColor: hasError 
                                        ? const Color(0x1AE53935)
                                        : Colors.transparent,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                    hintText: 'Edit sentence here...',
                                    hintStyle: TextStyle(color: AppColors.textTertiary),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.hasEvaluation) ...<Widget>[
                    _EvaluationCard(result: state.evaluationResult!),
                    const SizedBox(height: 16),
                  ],
                  if (state.attemptLimitReached && !state.hasPassed)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _LockedMessage(
                        text: 'You reached the maximum number of evaluation attempts.',
                      ),
                    ),
                  // Behavioral coaching improvement text field below each question
                  const SizedBox(height: 8),
                  _SectionHeader(
                    title: 'Your improvement notes',
                    subtitle: 'Write down how you plan to improve your answer:',
                  ),
                  const SizedBox(height: 10),
                  ...state.coachingQuestions.map(
                    (BehavioralQuestions question) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ImprovementTextField(
                        question: question.question,
                        onChanged: (String value) {
                          // Store improvement notes if needed (optional extension)
                          // This maintains the requested UI without affecting data/repository
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: state.canSubmitEvaluation
                            ? () => bloc.add(const SubmitEvaluationEvent())
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF222222),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(170, 48),
                        ),
                        child: Text(
                          state.isSubmitting
                              ? 'Submitting...'
                              : state.isPolling
                                  ? 'Processing...'
                                  : state.hasPassed
                                      ? 'Evaluation Passed'
                                      : state.attemptLimitReached
                                          ? 'Attempts Exhausted'
                                          : 'Evaluate Answer',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: state.canTakeFinalInterview
                            ? () => bloc.add(const StartFinalInterviewEvent())
                            : null,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(180, 48),
                        ),
                        child: const Text('Take Final Interview'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    state.hasPassed
                        ? 'Pass condition met. Final interview is unlocked.'
                        : state.attemptLimitReached
                            ? 'You can continue to the final interview after using both attempts.'
                            : 'Edit your transcript freely. Tap red sentences to see improvement tips. When ready, submit for evaluation.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ImprovementTextField extends StatelessWidget {
  const _ImprovementTextField({
    required this.question,
    required this.onChanged,
  });

  final String question;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'For: $question',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: onChanged,
            maxLines: 3,
            minLines: 2,
            decoration: const InputDecoration(
              hintText: 'Write your improvement plan here...',
              hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.textSecondary),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.analysis,
    required this.attemptsUsed,
    required this.maxAttempts,
    required this.canTakeFinalInterview,
    required this.hasPassed,
  });

  final AnalysisResult analysis;
  final int attemptsUsed;
  final int maxAttempts;
  final bool canTakeFinalInterview;
  final bool hasPassed;

  @override
  Widget build(BuildContext context) {
    final double score = analysis.behavioralMetrics.impact
        .clamp(0, 100)
        .toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Behavioral training review',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      analysis.shortFeedback,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 8,
                      backgroundColor: const Color(0xFFE9ECEF),
                      color: hasPassed ? const Color(0xFF2E7D32) : const Color(0xFF222222),
                    ),
                    Center(
                      child: Text(
                        '${analysis.overallScore}/100',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _MetricChip(label: 'Ownership', value: analysis.behavioralMetrics.ownership),
              _MetricChip(label: 'Initiative', value: analysis.behavioralMetrics.initiative),
              _MetricChip(label: 'Impact', value: analysis.behavioralMetrics.impact),
              _MetricChip(label: 'Attempts', value: attemptsUsed, total: maxAttempts),
              if (canTakeFinalInterview)
                const _MetricChip(label: 'Final interview', value: 1, total: 1, unlocked: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    this.total,
    this.unlocked = false,
  });

  final String label;
  final int value;
  final int? total;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final Color background = unlocked ? const Color(0xFFE8F5E9) : const Color(0xFFF8F9FA);
    final Color textColor = unlocked ? const Color(0xFF2E7D32) : AppColors.textSecondary;
    final String suffix = total == null ? '' : '/$total';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value$suffix',
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.question});

  final BehavioralQuestions question;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Target: ${question.target}',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            'Example: ${question.example}',
            style: const TextStyle(color: AppColors.textTertiary, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({required this.result});

  final BehavioralTrainingAttemptResult result;

  @override
  Widget build(BuildContext context) {
    final BehavioralTrainingEvaluationAnalysis? analysis = result.analysis;
    if (analysis == null) {
      return const _EmptyCard(text: 'Evaluation result is missing analysis details.');
    }

    final Color accent = analysis.passed ? const Color(0xFF2E7D32) : const Color(0xFFB36A00);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  analysis.passed ? 'Evaluation passed' : 'Evaluation feedback',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: analysis.passed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  analysis.passed ? 'Passed' : 'Needs work',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CircularProgressIndicator(
                      value: analysis.score / 100,
                      strokeWidth: 8,
                      backgroundColor: const Color(0xFFE9ECEF),
                      color: accent,
                    ),
                    Center(
                      child: Text(
                        '${analysis.score}/100',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  analysis.feedback,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LockedMessage extends StatelessWidget {
  const _LockedMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}