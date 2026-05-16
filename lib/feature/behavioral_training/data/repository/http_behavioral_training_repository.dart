import 'package:talk_gym/feature/behavioral_training/data/model/behavioral_training_result.dart';
import 'package:talk_gym/feature/behavioral_training/data/repository/behavioral_training_repository.dart';
import 'package:talk_gym/feature/behavioral_training/data/service/behavioral_training_submission_service.dart';

class HttpBehavioralTrainingRepository implements BehavioralTrainingRepository {
  HttpBehavioralTrainingRepository({BehavioralTrainingSubmissionService? service})
    : _service = service ?? BehavioralTrainingSubmissionService();

  final BehavioralTrainingSubmissionService _service;

  @override
  Future<BehavioralTrainingSubmissionResult> submitTrainingAttempt({
    required int attemptId,
    required String transcript,
    required String trainingType,
  }) {
    return _service.submitTrainingAttempt(
      attemptId: attemptId,
      transcript: transcript,
      trainingType: trainingType,
    );
  }

  @override
  Future<BehavioralTrainingAttemptResult> fetchTrainingAttemptResult({
    required int trainingAttemptId,
    required int jobId,
  }) {
    return _service.fetchTrainingAttemptResult(
      trainingAttemptId: trainingAttemptId,
      jobId: jobId,
    );
  }

  @override
  Future<BehavioralTrainingAttemptResult> pollTrainingAttemptResultUntilDone({
    required int trainingAttemptId,
    required int jobId,
    Duration pollInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 3),
  }) {
    return _service.pollTrainingAttemptResultUntilDone(
      trainingAttemptId: trainingAttemptId,
      jobId: jobId,
      pollInterval: pollInterval,
      timeout: timeout,
    );
  }
}
