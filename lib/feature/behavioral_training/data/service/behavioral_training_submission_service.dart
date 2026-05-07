import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:talk_gym/core/auth_token_storage.dart';
import 'package:talk_gym/feature/behavioral_training/data/model/behavioral_training_result.dart';

class BehavioralTrainingSubmissionService {
  BehavioralTrainingSubmissionService({http.Client? client, Uri? baseUri})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _baseUri = baseUri ?? Uri.parse('https://f2da-102-212-68-34.ngrok-free.app');

  final http.Client _client;
  final bool _ownsClient;
  final Uri _baseUri;

  Future<BehavioralTrainingSubmissionResult> submitTrainingAttempt({
    required String attemptId,
    required String transcript,
    required String trainingType,
    String? bearerToken,
  }) async {
    final String resolvedBearerToken = await _resolveBearerToken(bearerToken);
    final Uri endpoint = _baseUri.replace(path: '/api/v1/training/submit');

    final http.Response response = await _client.post(
      endpoint,
      headers: <String, String>{
        'Authorization': 'Bearer $resolvedBearerToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'attempt_id': attemptId,
        'training_type': trainingType,
        'transcript': transcript,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Failed to submit behavioral training. HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Invalid behavioral training submit response format.');
    }

    return BehavioralTrainingSubmissionResult.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  Future<BehavioralTrainingAttemptResult> fetchTrainingAttemptResult({
    required int trainingAttemptId,
    required int jobId,
    String? bearerToken,
  }) async {
    final String resolvedBearerToken = await _resolveBearerToken(bearerToken);
    final Uri endpoint = _baseUri.replace(
      path: '/api/v1/training/$trainingAttemptId/results/$jobId',
    );

    final http.Response response = await _client.get(
      endpoint,
      headers: <String, String>{
        'Authorization': 'Bearer $resolvedBearerToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Failed to fetch behavioral training result. HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Invalid behavioral training result format.');
    }

    return BehavioralTrainingAttemptResult.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  Future<BehavioralTrainingAttemptResult> pollTrainingAttemptResultUntilDone({
    required int trainingAttemptId,
    required int jobId,
    String? bearerToken,
    Duration pollInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final DateTime startedAt = DateTime.now();

    while (DateTime.now().difference(startedAt) < timeout) {
      final BehavioralTrainingAttemptResult result = await fetchTrainingAttemptResult(
        trainingAttemptId: trainingAttemptId,
        jobId: jobId,
        bearerToken: bearerToken,
      );

      if (result.isDone) {
        return result;
      }
      if (result.isFailed) {
        throw StateError(result.message ?? 'Behavioral training processing failed.');
      }

      await Future<void>.delayed(pollInterval);
    }

    throw TimeoutException('Timed out while waiting for behavioral training analysis.');
  }

  Future<String> _resolveBearerToken(String? bearerToken) async {
    final String token = (bearerToken ?? await AuthTokenStorage.getToken() ?? '').trim();
    if (token.isEmpty) {
      throw StateError('Missing authentication token. Please login/signin first.');
    }
    return token;
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
