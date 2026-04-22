import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/feature/analysis_results/data/model/analysis_result.dart';
import 'package:talk_gym/feature/analysis_results/data/repository/analysis_results_repository.dart';
import 'package:talk_gym/feature/analysis_results/data/repository/mock_analysis_results_repository.dart';
import 'package:talk_gym/feature/analysis_results/viewmodel/analysis_results_bloc.dart';
import 'package:talk_gym/feature/question/data/model/question_item.dart';
import 'package:talk_gym/feature/star_training/view/star_training_page.dart';

class AnalysisResultsPage extends StatelessWidget {
  const AnalysisResultsPage({this.repository, super.key});

  final AnalysisResultsRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AnalysisResultsBloc>(
      create: (_) => AnalysisResultsBloc(
        repository: repository ?? MockAnalysisResultsRepository(),
      )..add(const AnalysisResultsStarted()),
      child: const _AnalysisResultsView(),
    );
  }
}

class _AnalysisResultsView extends StatefulWidget {
  const _AnalysisResultsView();

  @override
  State<_AnalysisResultsView> createState() => _AnalysisResultsViewState();
}

class _AnalysisResultsViewState extends State<_AnalysisResultsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scoreController;
  late final Animation<double> _scoreAnimation;
  int _lastLoadToken = -1;
  int _lastPopupRequestId = 0;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scoreAnimation = CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _openSentenceSheet(
    BuildContext context,
    SentenceFeedback feedback,
  ) async {
    final TextEditingController manualController = TextEditingController(
      text: feedback.improvedExample,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: _SentenceFeedbackSheet(
            feedback: feedback,
            controller: manualController,
            onApply: (String replacement) {
              final String updated = replacement.trim().isEmpty
                  ? feedback.improvedExample
                  : replacement.trim();

              if (updated.isEmpty) {
                return;
              }

              HapticFeedback.lightImpact();
              context.read<AnalysisResultsBloc>().add(
                AnalysisSentenceImprovementApplied(
                  sentenceIndex: feedback.sentenceIndex,
                  replacement: updated,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Sentence improved and saved.'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.darkCardBackground,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              Navigator.of(bottomSheetContext).pop();
            },
          ),
        );
      },
    );

    manualController.dispose();
    if (!context.mounted) {
      return;
    }
    context.read<AnalysisResultsBloc>().add(const AnalysisPopupClosed());
  }

  Future<void> _openEditSheet(
    BuildContext context,
    AnalysisResultsState state,
    int sentenceIndex,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: state.sentenceTextFor(sentenceIndex),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: _ManualEditSheet(
            originalSentence: state.sentenceTextFor(sentenceIndex),
            controller: controller,
            onApply: (String replacement) {
              final String updated = replacement.trim();
              if (updated.isEmpty) {
                return;
              }

              HapticFeedback.lightImpact();
              context.read<AnalysisResultsBloc>().add(
                AnalysisSentenceImprovementApplied(
                  sentenceIndex: sentenceIndex,
                  replacement: updated,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Manual edit applied.'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.darkCardBackground,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              Navigator.of(bottomSheetContext).pop();
            },
          ),
        );
      },
    );

    controller.dispose();
  }

  void _startScoreAnimation() {
    _scoreController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analysis'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh analysis',
            onPressed: () {
              HapticFeedback.selectionClick();
              context.read<AnalysisResultsBloc>().add(
                const AnalysisResultsRefreshed(),
              );
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<AnalysisResultsBloc, AnalysisResultsState>(
          listener: (BuildContext context, AnalysisResultsState state) {
            if (state.status == AnalysisResultsStatus.success &&
                state.analysis != null &&
                state.loadToken != _lastLoadToken) {
              _lastLoadToken = state.loadToken;
              _startScoreAnimation();
            }

            if (state.popupRequestId != _lastPopupRequestId &&
                state.selectedFeedback != null) {
              _lastPopupRequestId = state.popupRequestId;
              HapticFeedback.selectionClick();
              unawaited(_openSentenceSheet(context, state.selectedFeedback!));
            }
          },
          builder: (BuildContext context, AnalysisResultsState state) {
            switch (state.status) {
              case AnalysisResultsStatus.initial:
              case AnalysisResultsStatus.loading:
                return _AnalysisSkeleton(
                  onRetry: () {
                    context.read<AnalysisResultsBloc>().add(
                      const AnalysisResultsRefreshed(),
                    );
                  },
                );
              case AnalysisResultsStatus.failure:
                return _AnalysisErrorState(
                  message: state.errorMessage ?? 'Unable to load AI analysis.',
                  onRetry: () {
                    context.read<AnalysisResultsBloc>().add(
                      const AnalysisResultsRetryRequested(),
                    );
                  },
                );
              case AnalysisResultsStatus.success:
                final AnalysisResult analysis = state.analysis!;

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<AnalysisResultsBloc>().add(
                      const AnalysisResultsRefreshed(),
                    );
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: <Widget>[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _HeaderRow(
                                trainingMode: analysis.primaryTrainingMode,
                                onRefresh: () => context
                                    .read<AnalysisResultsBloc>()
                                    .add(const AnalysisResultsRefreshed()),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: _ScoreRing(
                                  score: analysis.overallScore,
                                  animation: _scoreAnimation,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _SectionLabel(
                                title: 'Content metrics',
                                subtitle:
                                    'Relevance, clarity, structure, and specificity.',
                              ),
                              const SizedBox(height: 12),
                              _MetricBar(
                                label: 'Relevance',
                                score: analysis.contentMetrics.relevance,
                              ),
                              const SizedBox(height: 10),
                              _MetricBar(
                                label: 'Clarity',
                                score: analysis.contentMetrics.clarity,
                              ),
                              const SizedBox(height: 10),
                              _MetricBar(
                                label: 'Structure / STAR',
                                score: analysis.contentMetrics.structureStar,
                              ),
                              const SizedBox(height: 10),
                              _MetricBar(
                                label: 'Specificity',
                                score: analysis.contentMetrics.specificity,
                              ),
                              const SizedBox(height: 18),
                              _SectionLabel(
                                title: 'Behavioral metrics',
                                subtitle:
                                    'How this answer reflects ownership, initiative, and impact.',
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 168,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  children: <Widget>[
                                    _BehaviorMetricCard(
                                      label: 'Ownership',
                                      score:
                                          analysis.behavioralMetrics.ownership,
                                      description:
                                          'Shows clear accountability and personal responsibility.',
                                    ),
                                    const SizedBox(width: 12),
                                    _BehaviorMetricCard(
                                      label: 'Initiative',
                                      score:
                                          analysis.behavioralMetrics.initiative,
                                      description:
                                          'Shows proactive action without waiting to be asked.',
                                    ),
                                    const SizedBox(width: 12),
                                    _BehaviorMetricCard(
                                      label: 'Impact',
                                      score: analysis.behavioralMetrics.impact,
                                      description:
                                          'Shows measurable outcomes and business value.',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              _SectionLabel(
                                title: 'Flags',
                                subtitle:
                                    'Patterns that should be tightened before the next interview step.',
                              ),
                              const SizedBox(height: 10),
                              if (analysis.flags.isEmpty)
                                const _EmptyPill(
                                  text: 'No major flags detected.',
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: analysis.flags
                                      .map(
                                        (String flag) => _FlagChip(text: flag),
                                      )
                                      .toList(),
                                ),
                              const SizedBox(height: 18),
                              _SubtleInfoCard(text: analysis.shortFeedback),
                              const SizedBox(height: 18),
                              _SectionLabel(
                                title: 'Transcript',
                                subtitle:
                                    'Tap highlighted sentences for coaching tips. Double tap or long press any sentence to edit it.',
                              ),
                              const SizedBox(height: 12),
                              _TranscriptCard(
                                state: state,
                                onSentenceTap: (int index) {
                                  final SentenceFeedback? feedback = state
                                      .feedbackFor(index);
                                  if (feedback != null) {
                                    context.read<AnalysisResultsBloc>().add(
                                      AnalysisSentenceTapped(index),
                                    );
                                  }
                                },
                                onSentenceEdit: (int index) {
                                  HapticFeedback.mediumImpact();
                                  context.read<AnalysisResultsBloc>().add(
                                    const AnalysisReviewed(),
                                  );
                                  unawaited(
                                    _openEditSheet(context, state, index),
                                  );
                                },
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: <Widget>[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final QuestionItem
                                        question = QuestionItem(
                                          id: -1,
                                          title: analysis.primaryTrainingMode,
                                          description:
                                              'Practice the improved transcript in STAR training mode.',
                                          tags: const <String>[
                                            'STAR',
                                            'Behavioral',
                                          ],
                                          dayUnlock: 1,
                                        );

                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => StarTrainingPage(
                                              question: question,
                                            ),
                                          ),
                                        );
                                      },

                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(50),
                                        backgroundColor: AppColors.textPrimary,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Continue to Training'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                state.hasReviewedAnalysis
                                    ? 'Review complete. Your edited transcript is ready for the next step.'
                                    : 'Save or edit a sentence first to unlock the final interview step.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textTertiary),
                              ),
                              const SizedBox(height: 22),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.trainingMode, required this.onRefresh});

  final String trainingMode;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'AI Analysis',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(trainingMode, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh analysis',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.animation});

  final int score;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final Color progressColor = score > 70
        ? AppColors.successDark
        : AppColors.textSecondary;

    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double value = (score * animation.value).clamp(0.0, 100.0);
        return Semantics(
          label: 'Overall score $score out of 100',
          child: SizedBox(
            width: 168,
            height: 168,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox(
                  width: 168,
                  height: 168,
                  child: CircularProgressIndicator(
                    value: value / 100,
                    strokeWidth: 12,
                    backgroundColor: AppColors.cardBackground,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      value.round().toString(),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: progressColor,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Overall score',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$score',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: score / 100,
            backgroundColor: AppColors.cardBackground,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _BehaviorMetricCard extends StatelessWidget {
  const _BehaviorMetricCard({
    required this.label,
    required this.score,
    required this.description,
  });

  final String label;
  final int score;
  final String description;

  @override
  Widget build(BuildContext context) {
    final Color scoreColor = score > 70
        ? AppColors.successDark
        : AppColors.textPrimary;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
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
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '$score',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scoreColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 64,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPill extends StatelessWidget {
  const _EmptyPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _SubtleInfoCard extends StatelessWidget {
  const _SubtleInfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          height: 1.45,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({
    required this.state,
    required this.onSentenceTap,
    required this.onSentenceEdit,
  });

  final AnalysisResultsState state;
  final ValueChanged<int> onSentenceTap;
  final ValueChanged<int> onSentenceEdit;

  @override
  Widget build(BuildContext context) {
    final List<int> indices = state.orderedSentenceIndices;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: indices
              .map(
                (int index) => _SentenceTile(
                  key: ValueKey<String>(
                    'sentence-$index-${state.sentenceVersionFor(index)}',
                  ),
                  index: index,
                  sentence: state.sentenceTextFor(index),
                  feedback: state.feedbackFor(index),
                  version: state.sentenceVersionFor(index),
                  onTap: () => onSentenceTap(index),
                  onEdit: () => onSentenceEdit(index),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _SentenceTile extends StatefulWidget {
  const _SentenceTile({
    super.key,
    required this.index,
    required this.sentence,
    required this.feedback,
    required this.version,
    required this.onTap,
    required this.onEdit,
  });

  final int index;
  final String sentence;
  final SentenceFeedback? feedback;
  final int version;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  State<_SentenceTile> createState() => _SentenceTileState();
}

class _SentenceTileState extends State<_SentenceTile> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 50 + (widget.index * 70)), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = widget.feedback != null;
    final Color backgroundColor = isHighlighted
        ? const Color(0xFFFFEBEE)
        : AppColors.background;
    final Color textColor = isHighlighted ? Colors.red : AppColors.textPrimary;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 260),
      opacity: _visible ? 1 : 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHighlighted ? Colors.red.shade100 : AppColors.cardBorder,
          ),
        ),
        child: Semantics(
          button: true,
          label: isHighlighted
              ? 'Highlighted sentence needs improvement. Double tap for coaching tips. ${widget.sentence}'
              : widget.sentence,
          hint: isHighlighted
              ? 'Double tap for coaching tips. Long press to edit.'
              : 'Double tap or long press to edit.',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isHighlighted ? widget.onTap : null,
            onDoubleTap: widget.onEdit,
            onLongPress: widget.onEdit,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    widget.sentence,
                    key: ValueKey<String>(
                      'sentence-text-${widget.index}-${widget.version}',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SentenceFeedbackSheet extends StatelessWidget {
  const _SentenceFeedbackSheet({
    required this.feedback,
    required this.controller,
    required this.onApply,
  });

  final SentenceFeedback feedback;
  final TextEditingController controller;
  final ValueChanged<String> onApply;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, Offset offset, Widget? child) {
        return Transform.translate(
          offset: Offset(0, offset.dy * MediaQuery.of(context).size.height),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Coaching tips',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      feedback.sentence,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    feedback.issue,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        feedback.improvementType,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Suggested rewrite',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      feedback.improvedExample,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Manual edit',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Write your own improved version',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => onApply(controller.text),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply Improvement'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualEditSheet extends StatelessWidget {
  const _ManualEditSheet({
    required this.originalSentence,
    required this.controller,
    required this.onApply,
  });

  final String originalSentence;
  final TextEditingController controller;
  final ValueChanged<String> onApply;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, Offset offset, Widget? child) {
        return Transform.translate(
          offset: Offset(0, offset.dy * MediaQuery.of(context).size.height),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Edit sentence',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      originalSentence,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Write your edit here',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => onApply(controller.text),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply Edit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalysisSkeleton extends StatefulWidget {
  const _AnalysisSkeleton({required this.onRetry});

  final VoidCallback onRetry;

  @override
  State<_AnalysisSkeleton> createState() => _AnalysisSkeletonState();
}

class _AnalysisSkeletonState extends State<_AnalysisSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    double radius = 12,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + (_controller.value * 2), -0.3),
              end: Alignment(1.0 + (_controller.value * 2), 0.3),
              colors: const <Color>[
                Color(0xFFF0F0F0),
                Color(0xFFE5E5E5),
                Color(0xFFF0F0F0),
              ],
              stops: const <double>[0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _shimmerBox(width: 160, height: 28),
              const Spacer(),
              IconButton(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(child: _shimmerBox(width: 168, height: 168, radius: 84)),
          const SizedBox(height: 20),
          _shimmerBox(width: 140, height: 18),
          const SizedBox(height: 12),
          _shimmerBox(width: double.infinity, height: 10),
          const SizedBox(height: 10),
          _shimmerBox(width: double.infinity, height: 10),
          const SizedBox(height: 10),
          _shimmerBox(width: double.infinity, height: 10),
          const SizedBox(height: 10),
          _shimmerBox(width: double.infinity, height: 10),
          const SizedBox(height: 18),
          _shimmerBox(width: 150, height: 18),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, __) => _shimmerBox(width: 220, height: 160),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: 3,
            ),
          ),
          const SizedBox(height: 18),
          _shimmerBox(width: 120, height: 18),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(
              3,
              (int index) => _shimmerBox(
                width: 110 + (index * 30),
                height: 36,
                radius: 999,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _shimmerBox(width: double.infinity, height: 72),
          const SizedBox(height: 18),
          _shimmerBox(width: 140, height: 18),
          const SizedBox(height: 12),
          _shimmerBox(width: double.infinity, height: 220),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(child: _shimmerBox(width: double.infinity, height: 50)),
              const SizedBox(width: 12),
              Expanded(child: _shimmerBox(width: double.infinity, height: 50)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalysisErrorState extends StatelessWidget {
  const _AnalysisErrorState({required this.message, required this.onRetry});

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
              size: 38,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(140, 48),
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
