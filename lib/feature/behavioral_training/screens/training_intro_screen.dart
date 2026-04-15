import 'package:flutter/material.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/feature/behavioral_training/screens/training_editor_screen.dart';

class BehavioralTrainingIntroScreen extends StatelessWidget {
  const BehavioralTrainingIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (canPop)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'Rewrite & Improve Your Answers',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Transform vague stories into interview-winning responses',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              const _ValueCards(),
              const SizedBox(height: 20),
              const _HowItWorks(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Text(
                  'Most candidates write answers that are too vague. I worked hard or I led a team does not impress interviewers. They want specifics: what you did and what happened because of you. This training teaches you exactly what is missing.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TrainingEditorScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
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
              const SizedBox(height: 10),
              const Text(
                'You have 2 AI evaluations per answer. Use them wisely.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
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

class _ValueCards extends StatelessWidget {
  const _ValueCards();

  @override
  Widget build(BuildContext context) {
    final List<(IconData, String, String)> cards = <(IconData, String, String)>[
      (Icons.search_rounded, 'Identify Weak Spots', 'AI highlights generic sentences holding you back'),
      (Icons.edit_note_rounded, 'Learn Why', 'Click any highlight to get specific coaching tips'),
      (Icons.flash_on_rounded, 'Improve Fast', 'Edit, get AI feedback, polish (2 AI calls per answer)'),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isNarrow = constraints.maxWidth < 540;
        if (isNarrow) {
          return Column(
            children: cards
                .map(((IconData, String, String) item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ValueCard(item: item),
                    ))
                .toList(),
          );
        }

        return Row(
          children: cards
              .map(((IconData, String, String) item) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _ValueCard(item: item),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.item});

  final (IconData, String, String) item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(item.$1, color: const Color(0xFF222222)),
          const SizedBox(height: 8),
          Text(
            item.$2,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.$3,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    const List<String> steps = <String>[
      'Choose a behavioral question from our library',
      'Paste or write your answer (or start from our example)',
      'AI highlights problematic sentences in red',
      'Click any red text and see how to improve with examples',
      'Edit your answer directly in the box',
      'Submit for AI evaluation to get score and actionable feedback',
      'Improve again (you have 2 AI calls total)',
      'Take the final interview simulation',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'How This Training Works',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map(
                (MapEntry<int, String> entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF222222),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
