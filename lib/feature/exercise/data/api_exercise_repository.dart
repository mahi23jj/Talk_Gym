import '../model/journey_models.dart';
import 'exercise_repository.dart';

class ApiExerciseRepository implements ExerciseRepository {
  const ApiExerciseRepository();

  @override
  Future<JourneyData> fetchJourney() {
    // TODO: Replace with real API call and mapping.
    throw UnimplementedError('Exercise API repository is not implemented yet.');
  }
}
