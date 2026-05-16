import 'package:talk_gym/feature/behavioral_training/data/model/behavioral_training_result.dart';

abstract class BehavioralTrainingRepository {
  Future<BehavioralTrainingSubmissionResult> submitTrainingAttempt({
    required int attemptId,
    required String transcript,
    required String trainingType,
  });

  Future<BehavioralTrainingAttemptResult> fetchTrainingAttemptResult({
    required int trainingAttemptId,
    required int jobId,
  });

  Future<BehavioralTrainingAttemptResult> pollTrainingAttemptResultUntilDone({
    required int trainingAttemptId,
    required int jobId,
    Duration pollInterval,
    Duration timeout,
  });
}
