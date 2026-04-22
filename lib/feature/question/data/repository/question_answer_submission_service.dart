import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:talk_gym/feature/analysis_results/data/model/analysis_result.dart';

class QuestionAnswerSubmissionService {
  QuestionAnswerSubmissionService({http.Client? client, Uri? baseUri})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _baseUri = baseUri ?? Uri.parse('http://127.0.0.1:8000');

  final http.Client _client;
  final bool _ownsClient;
  final Uri _baseUri;

  Future<int> submitAnswer({
    required String questionId,
    required int durationSeconds,
    required String bearerToken,
    required String voiceFilePath,
  }) async {
    final Uri endpoint = _baseUri.replace(
      path: '/api/v1/attempt/submit/$questionId',
    );

    final http.MultipartRequest request =
        http.MultipartRequest('POST', endpoint)
          ..headers['Authorization'] = 'Bearer $bearerToken'
          ..headers['Accept'] = 'application/json'
          ..fields['duration_sec'] = durationSeconds.toString();

    if (!File(voiceFilePath).existsSync()) {
      throw StateError('Audio file not found: $voiceFilePath');
    }

    request.files.add(
      await http.MultipartFile.fromPath('audio', voiceFilePath),
    );

    final http.StreamedResponse response = await _client.send(request);
    final String body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Failed to submit answer. HTTP ${response.statusCode}: $body',
      );
    }

    final dynamic decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Invalid submit response format.');
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(decoded);
    final int? jobId = _asInt(json['job_id']);
    if (jobId == null) {
      throw const FormatException('Submit response missing job_id.');
    }

    return jobId;
  }

  Future<AnalysisResult> pollResultUntilDone({
    required int jobId,
    required String bearerToken,
    Duration pollInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final DateTime startedAt = DateTime.now();

    while (DateTime.now().difference(startedAt) < timeout) {
      final Uri resultUri = _baseUri.replace(
        path: '/api/v1/attempt/result/$jobId',
      );

      final http.Response response = await _client.get(
        resultUri,
        headers: <String, String>{
          'Authorization': 'Bearer $bearerToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Failed to fetch attempt result. HTTP ${response.statusCode}: ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Invalid result response format.');
      }

      final Map<String, dynamic> resultPayload = Map<String, dynamic>.from(
        decoded,
      );
      final String status = (resultPayload['status'] as String? ?? '')
          .trim()
          .toLowerCase();

      if (status == 'done') {
        final Map<String, dynamic> analysisJson = _extractAnalysisJson(
          resultPayload,
        );
        return AnalysisResult.fromJson(analysisJson);
      }

      if (status == 'failed' || status == 'error') {
        final String error =
            (resultPayload['message'] as String? ??
                    'Background analysis failed.')
                .trim();
        throw StateError(error);
      }

      await Future<void>.delayed(pollInterval);
    }

    throw TimeoutException('Timed out while waiting for analysis result.');
  }

  Future<AnalysisResult> submitAndAwaitResult({
    required String questionId,
    required int durationSeconds,
    required String bearerToken,
    required String voiceFilePath,
  }) async {
    final int jobId = await submitAnswer(
      questionId: questionId,
      durationSeconds: durationSeconds,
      bearerToken: bearerToken,
      voiceFilePath: voiceFilePath,
    );

    return pollResultUntilDone(jobId: jobId, bearerToken: bearerToken);
  }

  Map<String, dynamic> _extractAnalysisJson(Map<String, dynamic> payload) {
    for (final String key in <String>['result', 'analysis', 'data']) {
      final dynamic value = payload[key];
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }

    return payload;
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
