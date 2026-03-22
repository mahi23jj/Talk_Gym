import '../model/journey_models.dart';

abstract class ExerciseRepository {
  Future<JourneyData> fetchJourney();
}
