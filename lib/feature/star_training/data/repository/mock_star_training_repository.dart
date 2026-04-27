import 'dart:async';

import 'package:talk_gym/feature/analysis_results/data/model/analysis_result.dart';
import 'package:talk_gym/feature/question/data/model/question_item.dart';
import 'package:talk_gym/feature/star_training/data/model/star_training_models.dart';
import 'package:talk_gym/feature/star_training/data/repository/star_training_repository.dart';

class MockStarTrainingRepository implements StarTrainingRepository {
  @override
  Future<StarTrainingSession> fetchSession(QuestionItem question , StarMetrics analysisResult) async {
    await Future<void>.delayed(const Duration(milliseconds: 750));

    return StarTrainingSession(
      question: question,
      socialProof: 'Top candidates practice this exact structure before interviews.',
      feedback:
          'Your answer structure looks solid. The Result section could be stronger with measurable impact.',
      steps:  <StarStepContent>[
        StarStepContent(
          part: StarPart.situation,
          icon: '🏢',
          prompt: 'Describe the situation in 1-2 sentences. Keep it short.',
          example:
              analysisResult.situation,
        ),
        StarStepContent(
          part: StarPart.task,
          icon: '✅',
          prompt: 'What were you responsible for in that moment?',
          example:
              analysisResult.task,
        ),
        StarStepContent(
          part: StarPart.action,
          icon: '🙋',
          prompt: 'Focus on your actions. What did YOU do?',
          example:
                      analysisResult.action,
        ),
        StarStepContent(
          part: StarPart.result,
          icon: '📈',
          prompt: 'What was the outcome and what changed?',
          example:
                analysisResult.result,
        ),
      ],
    );
  }
}
