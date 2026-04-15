import 'dart:async';

import 'package:talk_gym/feature/question/data/model/question_item.dart';
import 'package:talk_gym/feature/star_training/data/model/star_training_models.dart';
import 'package:talk_gym/feature/star_training/data/repository/star_training_repository.dart';

class MockStarTrainingRepository implements StarTrainingRepository {
  @override
  Future<StarTrainingSession> fetchSession(QuestionItem question) async {
    await Future<void>.delayed(const Duration(milliseconds: 750));

    return StarTrainingSession(
      question: question,
      socialProof: 'Top candidates practice this exact structure before interviews.',
      feedback:
          'Your answer structure looks solid. The Result section could be stronger with measurable impact.',
      steps: const <StarStepContent>[
        StarStepContent(
          part: StarPart.situation,
          icon: '🏢',
          prompt: 'Describe the situation in 1-2 sentences. Keep it short.',
          example:
              'Example: During my internship, our API response time was slower than expected under high traffic.',
        ),
        StarStepContent(
          part: StarPart.task,
          icon: '✅',
          prompt: 'What were you responsible for in that moment?',
          example:
              'Example: I was responsible for identifying the bottleneck and proposing a fix to my team lead.',
        ),
        StarStepContent(
          part: StarPart.action,
          icon: '🙋',
          prompt: 'Focus on your actions. What did YOU do?',
          example:
              'Example: I profiled key endpoints, added indexes, and introduced response caching with clear rollout steps.',
        ),
        StarStepContent(
          part: StarPart.result,
          icon: '📈',
          prompt: 'What was the outcome and what changed?',
          example:
              'Example: Response time improved by 42 percent, and support tickets about slowness dropped the same week.',
        ),
      ],
    );
  }
}
