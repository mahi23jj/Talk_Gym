import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/feature/final_analysis/data/model/final_interview_result.dart';
import 'package:talk_gym/feature/final_analysis/data/repository/http_final_analysis_repository.dart';
import 'package:talk_gym/feature/final_analysis/presentation/viewmodel/final_analysis_cubit.dart';

class FinalAnalysisPage extends StatelessWidget {
  const FinalAnalysisPage({required this.sessionId, super.key});
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FinalAnalysisCubit>(
      create: (_) => FinalAnalysisCubit(
        repository: HttpFinalAnalysisRepository(),
        sessionId: sessionId,
      )..load(),
      child: const _FinalAnalysisView(),
    );
  }
}

class _FinalAnalysisView extends StatelessWidget {
  const _FinalAnalysisView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Final Analysis')),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<FinalAnalysisCubit, FinalAnalysisState>(
          builder: (BuildContext context, FinalAnalysisState state) {
            if (state.status == FinalAnalysisStatus.loading ||
                state.status == FinalAnalysisStatus.processing) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Processing final interview analysis...'),
                  ],
                ),
              );
            }

            if (state.status == FinalAnalysisStatus.failure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.error_outline_rounded, size: 34),
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage ?? 'Unable to load final analysis.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () =>
                            context.read<FinalAnalysisCubit>().retry(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final FinalInterviewResult result = state.result!;
            final Map<String, ScoreComparison> categories =
                result.categoryScores.asMap();

            return RefreshIndicator(
              onRefresh: () => context.read<FinalAnalysisCubit>().retry(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                children: <Widget>[
                  _HeaderSummary(summary: result.performanceSummary),
                  const SizedBox(height: 12),
                  _PerformanceCard(summary: result.performanceSummary),
                  const SizedBox(height: 12),
                  const _SectionTitle('Skill Comparison'),
                  const SizedBox(height: 8),
                  ...categories.entries.map(
                    (MapEntry<String, ScoreComparison> entry) =>
                        _SkillComparisonTile(
                          label: entry.key,
                          score: entry.value,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _ImprovementAreaCard(data: result.improvementAnalysis),
                  const SizedBox(height: 12),
                  _StrengthWeaknessCard(
                    title: 'Strengths',
                    items: result.finalAnalysis.strengths,
                    icon: Icons.thumb_up_alt_outlined,
                  ),
                  const SizedBox(height: 10),
                  _StrengthWeaknessCard(
                    title: 'Weaknesses',
                    items: result.finalAnalysis.weaknesses,
                    icon: Icons.trending_down_rounded,
                  ),
                  const SizedBox(height: 12),
                  _FlagsCard(flags: result.finalAnalysis.flags),
                  const SizedBox(height: 12),
                  _RadarCard(
                    labels: result.visualizationReady.radarLabels.isNotEmpty
                        ? result.visualizationReady.radarLabels
                        : categories.keys.toList(),
                    initialScores: result.visualizationReady.initialScores
                            .isNotEmpty
                        ? result.visualizationReady.initialScores
                        : categories.values.map((ScoreComparison e) => e.initial).toList(),
                    finalScores: result.visualizationReady.finalScores.isNotEmpty
                        ? result.visualizationReady.finalScores
                        : categories.values.map((ScoreComparison e) => e.finalScore).toList(),
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

class _HeaderSummary extends StatelessWidget {
  const _HeaderSummary({required this.summary});
  final PerformanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final bool improved = summary.overallDelta >= 0;
    final Color color = improved ? AppColors.successDark : Colors.redAccent;
    final String trend = improved ? 'Improved' : 'Regressed';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${improved ? '+' : ''}${summary.overallDelta.toStringAsFixed(1)} overall change',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(trend, style: TextStyle(color: color)),
              ),
              const SizedBox(width: 8),
              Text('${summary.improvementPercentage.toStringAsFixed(1)}% improved'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.summary});
  final PerformanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionTitle('Performance Summary'),
          const SizedBox(height: 8),
          Text('Level: ${summary.performanceLevel}'),
          Text('Primary strength: ${summary.primaryStrength}'),
          Text('Primary improvement area: ${summary.primaryImprovementArea}'),
        ],
      ),
    );
  }
}

class _SkillComparisonTile extends StatelessWidget {
  const _SkillComparisonTile({required this.label, required this.score});
  final String label;
  final ScoreComparison score;

  @override
  Widget build(BuildContext context) {
    final double maxScore = max(score.initial, score.finalScore).clamp(1, 100);
    final double progress = (score.finalScore / maxScore).clamp(0, 1);
    final double delta = score.delta;
    final Color deltaColor = delta >= 0 ? AppColors.successDark : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Text(
                '${score.initial.toStringAsFixed(1)} -> ${score.finalScore.toStringAsFixed(1)}',
              ),
              const SizedBox(width: 6),
              Text(
                '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                style: TextStyle(color: deltaColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    );
  }
}

class _ImprovementAreaCard extends StatelessWidget {
  const _ImprovementAreaCard({required this.data});
  final ImprovementAnalysis data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionTitle('Improvement Analysis'),
          const SizedBox(height: 10),
          _ChipWrap(label: 'Improved', items: data.improvedAreas, color: Colors.green),
          _ChipWrap(label: 'Unchanged', items: data.unchangedAreas, color: Colors.blueGrey),
          _ChipWrap(label: 'Regressed', items: data.regressedAreas, color: Colors.red),
        ],
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.label, required this.items, required this.color});
  final String label;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.isEmpty
                ? <Widget>[const Chip(label: Text('None'))]
                : items
                      .map((String e) => Chip(label: Text(e), backgroundColor: color.withValues(alpha: 0.1)))
                      .toList(),
          ),
        ],
      ),
    );
  }
}

class _StrengthWeaknessCard extends StatelessWidget {
  const _StrengthWeaknessCard({
    required this.title,
    required this.items,
    required this.icon,
  });

  final String title;
  final List<AnalysisItem> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('No items provided.')
          else
            ...items.map(
              (AnalysisItem item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(item.description, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FlagsCard extends StatelessWidget {
  const _FlagsCard({required this.flags});
  final List<String> flags;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionTitle('Flags'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: flags.isEmpty
                ? <Widget>[const Chip(label: Text('No major flags'))]
                : flags
                      .map(
                        (String flag) => Chip(
                          avatar: const Icon(Icons.warning_amber_rounded, size: 16),
                          label: Text(flag),
                        ),
                      )
                      .toList(),
          ),
        ],
      ),
    );
  }
}

class _RadarCard extends StatelessWidget {
  const _RadarCard({
    required this.labels,
    required this.initialScores,
    required this.finalScores,
  });

  final List<String> labels;
  final List<double> initialScores;
  final List<double> finalScores;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionTitle('Radar Comparison'),
          const SizedBox(height: 10),
          SizedBox(
            height: 240,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, double value, __) {
                return CustomPaint(
                  painter: _RadarPainter(
                    labels: labels,
                    initialScores: initialScores,
                    finalScores: finalScores,
                    progress: value,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.labels,
    required this.initialScores,
    required this.finalScores,
    required this.progress,
  });

  final List<String> labels;
  final List<double> initialScores;
  final List<double> finalScores;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final int count = labels.length.clamp(3, 12);
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) * 0.33;
    final Paint axisPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke;
    final Paint initialPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final Paint finalPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    for (int layer = 1; layer <= 4; layer += 1) {
      final double layerRadius = radius * (layer / 4);
      final Path ring = Path();
      for (int i = 0; i < count; i += 1) {
        final double angle = (-pi / 2) + ((2 * pi * i) / count);
        final Offset p = Offset(
          center.dx + cos(angle) * layerRadius,
          center.dy + sin(angle) * layerRadius,
        );
        if (i == 0) {
          ring.moveTo(p.dx, p.dy);
        } else {
          ring.lineTo(p.dx, p.dy);
        }
      }
      ring.close();
      canvas.drawPath(ring, axisPaint);
    }

    Path shapeFor(List<double> rawScores) {
      final Path path = Path();
      for (int i = 0; i < count; i += 1) {
        final double score = i < rawScores.length ? rawScores[i].clamp(0, 100) : 0;
        final double scaled = (score / 100) * radius * progress;
        final double angle = (-pi / 2) + ((2 * pi * i) / count);
        final Offset p = Offset(
          center.dx + cos(angle) * scaled,
          center.dy + sin(angle) * scaled,
        );
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      return path;
    }

    canvas.drawPath(shapeFor(initialScores), initialPaint);
    canvas.drawPath(shapeFor(finalScores), finalPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.labels != labels ||
        oldDelegate.initialScores != initialScores ||
        oldDelegate.finalScores != finalScores;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800));
  }
}
