import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/feature/behavioral_training/models/evaluation_result.dart';

class EvaluationCard extends StatefulWidget {
  const EvaluationCard({
    required this.result,
    required this.aiCallsRemaining,
    required this.onApplySuggestions,
    required this.onEditManually,
    required this.onRequestFinalPolish,
    super.key,
  });

  final EvaluationResult result;
  final int aiCallsRemaining;
  final VoidCallback onApplySuggestions;
  final VoidCallback onEditManually;
  final VoidCallback onRequestFinalPolish;

  @override
  State<EvaluationCard> createState() => _EvaluationCardState();
}

class _EvaluationCardState extends State<EvaluationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _expandRewrite = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant EvaluationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result.score != widget.result.score) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildScoreCircle() {
    return SizedBox(
      width: 104,
      height: 104,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          final double value = _controller.value * (widget.result.score / 100);
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                backgroundColor: const Color(0xFFE9ECEF),
                color: const Color(0xFF333333),
              ),
              Center(
                child: Text(
                  '${widget.result.score}/100',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStarRow(String label, int value) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: value / 10,
              backgroundColor: const Color(0xFFE9ECEF),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF444444)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$value/10',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, int> score = widget.result.starMethodScore;

    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              blurRadius: 16,
              offset: Offset(0, 8),
              color: Color(0x12000000),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'AI Evaluation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Center(child: _buildScoreCircle()),
            const SizedBox(height: 18),
            _buildStarRow('Situation', score['Situation'] ?? 0),
            const SizedBox(height: 8),
            _buildStarRow('Task', score['Task'] ?? 0),
            const SizedBox(height: 8),
            _buildStarRow('Action', score['Action'] ?? 0),
            const SizedBox(height: 8),
            _buildStarRow('Result', score['Result'] ?? 0),
            const SizedBox(height: 16),
            Text(
              widget.result.overallFeedback,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Specific Suggestions',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.result.specificSuggestions.map(
              (String item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.check_box_outline_blank_rounded, size: 18, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Strengths',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ...widget.result.strengths.map(
              (String item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '✓ $item',
                  style: const TextStyle(color: Color(0xFF2E7D32)),
                ),
              ),
            ),
            if (widget.result.improvedVersion != null) ...<Widget>[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => setState(() => _expandRewrite = !_expandRewrite),
                child: Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'AI Suggested Rewrite',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      _expandRewrite ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                crossFadeState: _expandRewrite ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
                firstChild: const SizedBox(height: 0),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.result.improvedVersion!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ElevatedButton(
                  onPressed: widget.onApplySuggestions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF222222),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply Suggestions'),
                ),
                OutlinedButton(
                  onPressed: widget.onEditManually,
                  child: const Text('Edit Manually'),
                ),
                if (widget.aiCallsRemaining > 0)
                  OutlinedButton(
                    onPressed: widget.onRequestFinalPolish,
                    child: Text('Request Final Polish (${math.min(widget.aiCallsRemaining, 1)} call left)'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
