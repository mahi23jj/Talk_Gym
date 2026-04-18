import 'dart:async';

import 'package:talk_gym/feature/analysis_results/data/model/analysis_result.dart';
import 'package:talk_gym/feature/analysis_results/data/repository/analysis_results_repository.dart';

class MockAnalysisResultsRepository implements AnalysisResultsRepository {
  MockAnalysisResultsRepository({this.shouldFail = false});

  final bool shouldFail;

  @override
  Future<AnalysisResult> fetchAnalysisResults() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (shouldFail) {
      throw StateError('Mock analysis request failed.');
    }

    return AnalysisResult.fromJson(<String, dynamic>{
      'overall_score': 78,
      'transcript':
          'In my last role, I owned a support workflow that was slowing down new customer onboarding. We worked hard to fix it. I mapped the bottlenecks, interviewed the team, and rewrote the handoff steps. The team was happy because it went better. To measure progress, I tracked cycle time, escalations, and first-response quality each week. I stayed involved and kept everyone aligned. As a result, onboarding dropped from 12 days to 8 days and escalations fell by 32%. I learned that small process changes can create a large impact when ownership is clear.',
      'transcript_sentences': <String, String>{
        '0':
            'In my last role, I owned a support workflow that was slowing down new customer onboarding.',
        '1': 'We worked hard to fix it.',
        '2':
            'I mapped the bottlenecks, interviewed the team, and rewrote the handoff steps.',
        '3': 'The team was happy because it went better.',
        '4':
            'To measure progress, I tracked cycle time, escalations, and first-response quality each week.',
        '5': 'I stayed involved and kept everyone aligned.',
        '6':
            'As a result, onboarding dropped from 12 days to 8 days and escalations fell by 32%.',
        '7':
            'I learned that small process changes can create a large impact when ownership is clear.',
      },
      'content_metrics': <String, dynamic>{
        'relevance': 84,
        'clarity': 77,
        'structure_star': 71,
        'specificity': 79,
      },
      'behavioral_metrics': <String, dynamic>{
        'ownership': 86,
        'initiative': 74,
        'impact': 73,
      },
      'flags': <String>[
        'A few sentences stay vague and should be rewritten for stronger ownership.',
        'The middle of the story can be tighter and more specific.',
      ],
      'sentence_feedback': <Map<String, dynamic>>[
        <String, dynamic>{
          'idx': 0,
          'sentence_index': 1,
          'sentence': 'We worked hard to fix it.',
          'indexed_sentence': '1. We worked hard to fix it.',
          'issue':
              'This sentence is vague and uses we instead of I, which weakens ownership.',
          'improvement_type': 'ownership',
          'improved_example':
              'I identified the root cause, aligned the team on next steps, and owned the fix through rollout.',
        },
        <String, dynamic>{
          'idx': 1,
          'sentence_index': 3,
          'sentence': 'The team was happy because it went better.',
          'indexed_sentence': '3. The team was happy because it went better.',
          'issue':
              'This sentence describes a feeling, but not the concrete result.',
          'improvement_type': 'specificity',
          'improved_example':
              'The revised process reduced delays, cut rework, and made onboarding noticeably smoother for new customers.',
        },
        <String, dynamic>{
          'idx': 2,
          'sentence_index': 5,
          'sentence': 'I stayed involved and kept everyone aligned.',
          'indexed_sentence': '5. I stayed involved and kept everyone aligned.',
          'issue':
              'This sentence explains effort, but not the measurable impact of that effort.',
          'improvement_type': 'impact',
          'improved_example':
              'I kept stakeholders aligned through weekly check-ins, which reduced blockers and helped us deliver two weeks sooner.',
        },
      ],
      'primary_training_mode': 'Behavioral coaching with STAR reinforcement',
      'short_feedback':
          'Strong ownership and measurable impact. Tighten the vague middle sentences so the story lands with more precision.',
    });
  }
}
