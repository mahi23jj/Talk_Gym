import '../model/journey_models.dart';
import 'exercise_repository.dart';

class MockExerciseRepository implements ExerciseRepository {
  @override
  Future<JourneyData> fetchJourney() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));

    return const JourneyData(
      title: 'Your Journey 🚀',
      subtitle: 'Complete levels to unlock new challenges',
      nodes: <JourneyNode>[
        JourneyNode(
          id: 'simple_explanation',
          title: 'Simple Explanation',
          prompt:
              "Explain how the internet works to someone who's never used a computer",
          centerX: 0.18,
          top: 138,
          state: JourneyNodeState.completed,
          level: 1,
          stars: 3,
        ),
        JourneyNode(
          id: 'persuasive_speech',
          title: 'Persuasive Speech',
          prompt:
              'Convince a friend to build a daily reading habit in two minutes',
          centerX: 0.84,
          top: 302,
          state: JourneyNodeState.completed,
          level: 2,
          stars: 2,
        ),
        JourneyNode(
          id: 'tell_story',
          title: 'Tell a Story',
          prompt: 'Tell a short story about a mistake and what you learned',
          centerX: 0.18,
          top: 470,
          state: JourneyNodeState.current,
          level: 3,
        ),
        JourneyNode(
          id: 'describe_process',
          title: 'Describe a Process',
          prompt: 'Describe how to make tea for someone who has never done it',
          centerX: 0.84,
          top: 640,
          state: JourneyNodeState.locked,
          level: 4,
        ),
      ],
    );
  }
}
