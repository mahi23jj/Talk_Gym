import 'package:flutter/material.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/feature/behavioral_training/models/highlight_info.dart';

class ImprovementPopupDialog extends StatefulWidget {
  const ImprovementPopupDialog({
    required this.highlight,
    required this.onApply,
    super.key,
  });

  final HighlightInfo highlight;
  final ValueChanged<String> onApply;

  @override
  State<ImprovementPopupDialog> createState() => _ImprovementPopupDialogState();
}

class _ImprovementPopupDialogState extends State<ImprovementPopupDialog> {
  late final TextEditingController _manualController;

  @override
  void initState() {
    super.initState();
    _manualController = TextEditingController(text: widget.highlight.sentence);
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  String _quickFixSpecific(HighlightInfo info) {
    return '${info.sentence} I measured the impact and improved outcomes by 25% over six weeks.';
  }

  String _quickFixStar(HighlightInfo info) {
    return 'Situation: ${info.sentence} Task: I owned the decision. Action: I aligned stakeholders and executed a plan. Result: delivery improved by 20%.';
  }

  String _quickFixExample(HighlightInfo info) {
    return info.example;
  }

  @override
  Widget build(BuildContext context) {
    final HighlightInfo info = widget.highlight;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Improve This Sentence',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  info.sentence,
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      info.issueType.label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                info.suggestion,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Text(
                'How to Fix',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Replace vague verbs with action words. Add what you did, how you did it, and why it mattered.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bad: I worked hard on the project',
                style: TextStyle(color: AppColors.textTertiary, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 4),
              Text(
                'Good: ${info.example}',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: () => widget.onApply(_quickFixSpecific(info)),
                    child: const Text('Make more specific'),
                  ),
                  OutlinedButton(
                    onPressed: () => widget.onApply(_quickFixStar(info)),
                    child: const Text('Add STAR element'),
                  ),
                  OutlinedButton(
                    onPressed: () => widget.onApply(_quickFixExample(info)),
                    child: const Text('Show me an example'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Manual Edit',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _manualController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Edit sentence manually',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onApply(_manualController.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF222222),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Edit'),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Good answers are specific, measurable, and action-oriented. Show what you did, not what the team did.',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
