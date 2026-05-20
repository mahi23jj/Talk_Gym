import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:talk_gym/core/auth_token_storage.dart';
import 'package:talk_gym/core/constants/api_constants.dart';
import 'package:talk_gym/feature/final_analysis/data/model/final_interview_result.dart';

class QuestionAnswerSubmissionService {
  QuestionAnswerSubmissionService({http.Client? client, Uri? baseUri})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _baseUri =
          baseUri ?? Uri.parse('${ApiConstants.baseUrl}');

  final http.Client _client;
  final bool _ownsClient;
  final Uri _baseUri;

  Future<({String url, int sizeBytes})> uploadAudio(String path) async {
    final File file = File(path);
    if (!file.existsSync()) {
      throw StateError('Audio file not found: $path');
    }

    final Uri endpoint = _baseUri.replace(path: '/api/v1/upload/audio');
    final http.MultipartRequest request = http.MultipartRequest('POST', endpoint);
    request.files.add(await http.MultipartFile.fromPath('audio', path));

    final http.StreamedResponse response = await request.send();
    final String responseBody = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Failed to upload audio. HTTP ${response.statusCode}: $responseBody',
      );
    }

    final dynamic decoded = jsonDecode(responseBody);
    if (decoded is! Map) {
      throw const FormatException('Invalid audio upload response format.');
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(decoded);
    final String url = (json['url'] as String? ?? '').trim();
    final int? sizeBytes = _asInt(json['size'] ?? json['size_bytes']);

    if (url.isEmpty) {
      throw const FormatException('Audio upload response missing url.');
    }

    return (url: url, sizeBytes: sizeBytes ?? 0);
  }

  Future<int> submitAnswer({
    required String questionId,
    required int durationSeconds,
    String? bearerToken,
    required String voiceFilePath,
  }) async {
    final String resolvedBearerToken = await _resolveBearerToken(bearerToken);
    final ({String url, int sizeBytes}) uploaded = await uploadAudio(
      voiceFilePath,
    );

    print(
      'Uploaded to Cloudinary: url=${uploaded.url}, sizeBytes=${uploaded.sizeBytes}',
    );

    final Uri endpoint = _baseUri.replace(
      path: '/api/v1/attempt/submit/$questionId',
    );

    final String body = jsonEncode(<String, dynamic>{
      'audio_url': uploaded.url,
      'size_bytes': uploaded.sizeBytes,
      'duration_seconds': durationSeconds,
    });

    final http.Response response = await _client.post(
      endpoint,
      headers: <String, String>{
        'Authorization': 'Bearer $resolvedBearerToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Failed to submit answer. HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
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

  Future<String> submitFinalAnswer({
    required int attemptId,
    required int durationSeconds,
    String? bearerToken,
    required String voiceFilePath,
  }) async {
    final String resolvedBearerToken = await _resolveBearerToken(bearerToken);
    final ({String url, int sizeBytes}) uploaded = await uploadAudio(
      voiceFilePath,
    );

    final Uri endpoint = _baseUri.replace(
      path: '/api/v1/attempt/submit/final/$attemptId',
    );

    final String body = jsonEncode(<String, dynamic>{
      'audio_url': uploaded.url,
      'size_bytes': uploaded.sizeBytes,
      'duration_seconds': durationSeconds,
    });

    final http.Response response = await _client.post(
      endpoint,
      headers: <String, String>{
        'Authorization': 'Bearer $resolvedBearerToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Failed to submit final interview. HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Invalid final submit response format.');
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(decoded);
    final String sessionId = _coerceSessionId(json['session_id']);
    if (sessionId.isEmpty) {
      throw const FormatException('Final submit response missing session_id.');
    }
    return sessionId;
  }

  Future<FinalInterviewResult> fetchFinalResult({
    required String sessionId,
    String? bearerToken,
  }) async {
    final String resolvedBearerToken = await _resolveBearerToken(bearerToken);
    final Uri uri = _baseUri.replace(
      path: '/api/v1/attempt/analysis/$sessionId',
    );

    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $resolvedBearerToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Failed to fetch final interview result. HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Invalid final result response format.');
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(decoded);
    
    // Map backend response to FinalInterviewResult format
    final Map<String, dynamic> rawAnalysis = 
        _asMap(json['raw_analysis_json'] ?? {});
    
    // Build the expected nested structure from backend flat response
    final Map<String, dynamic> mappedJson = {
      'status': 'completed',
      'message': _asString(json['feedback']),
      'interview': {},
      'performance_summary': {
        'overall_score': {
          'initial': 0,
          'final': _asDouble(json['score']) ?? 0,
          'change': 0,
          'change_percent': 0,
          'trend': 'stable',
        },
        'performance_level': 'reviewed',
        'primary_strength': '',
        'primary_improvement_area': '',
      },
      'category_scores': {
        'clarity': _buildScoreComparison(rawAnalysis['content']?['clarity']),
        'structure_star': _buildScoreComparison(rawAnalysis['content']?['structure_star']),
        'specificity': _buildScoreComparison(rawAnalysis['content']?['specificity']),
        'ownership': _buildScoreComparison(rawAnalysis['behavioral']?['ownership']),
        'initiative': _buildScoreComparison(rawAnalysis['behavioral']?['initiative']),
        'impact': _buildScoreComparison(rawAnalysis['behavioral']?['impact']),
      },
      'final_analysis': {},
      'improvement_analysis': {},
      'visualization_ready': {},
      'coaching': {
        'behavioral_questions': rawAnalysis['behavioral_questions'] ?? [],
      },
      'star_rewrite_example': rawAnalysis['star_example'] ?? {},
      'sentence_feedback': rawAnalysis['sentence_feedback'] ?? [],
    };

    return FinalInterviewResult.fromJson(mappedJson);
  }

  Map<String, dynamic> _buildScoreComparison(dynamic score) {
    return {
      'initial': 0,
      'final': _asDouble(score) ?? 0,
      'change': 0,
      'trend': 'stable',
    };
  }

  Future<FinalInterviewResult> pollFinalResultUntilCompleted({
    required String sessionId,
    String? bearerToken,
    Duration pollInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final DateTime startedAt = DateTime.now();

    while (DateTime.now().difference(startedAt) < timeout) {
      final FinalInterviewResult result = await fetchFinalResult(
        sessionId: sessionId,
        bearerToken: bearerToken,
      );
      final String status = result.status.toLowerCase();

      if (status == 'completed') {
        return result;
      }
      if (status == 'failed' || status == 'error') {
        throw StateError(
          result.message ?? 'Final interview processing failed.',
        );
      }

      await Future<void>.delayed(pollInterval);
    }
    throw TimeoutException(
      'Timed out while waiting for final interview analysis.',
    );
  }

  Future<void> pollResultUntilDone({
    required int jobId,
    String? bearerToken,
    Duration pollInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final String resolvedBearerToken = await _resolveBearerToken(bearerToken);
    final DateTime startedAt = DateTime.now();

    while (DateTime.now().difference(startedAt) < timeout) {
      final Uri resultUri = _baseUri.replace(
        path: '/api/v1/attempt/result/$jobId',
      );

      final http.Response response = await _client.get(
        resultUri,
        headers: <String, String>{
          'Authorization': 'Bearer $resolvedBearerToken',
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

      if (status == 'done' || status == 'completed') {
        return;
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

  Future<int> submitAndAwaitResult({
    required String questionId,
    required int durationSeconds,
    String? bearerToken,
    required String voiceFilePath,
  }) async {
    final int jobId = await submitAnswer(
      questionId: questionId,
      durationSeconds: durationSeconds,
      bearerToken: bearerToken,
      voiceFilePath: voiceFilePath,
    );

    await pollResultUntilDone(jobId: jobId, bearerToken: bearerToken);

    return jobId;
  }

  Future<String> _resolveBearerToken(String? bearerToken) async {
    final String token =
        (bearerToken ?? await AuthTokenStorage.getToken() ?? '').trim();
    if (token.isEmpty) {
      throw StateError(
        'Missing authentication token. Please login/signin first.',
      );
    }
    return token;
  }

  static String _coerceSessionId(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is int || value is num) {
      return value.toString();
    }
    if (value is String) {
      return value.trim();
    }
    return value.toString().trim();
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

  static String? _asString(dynamic value) {
    if (value is String) {
      return value.trim();
    }
    if (value != null) {
      return value.toString().trim();
    }
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
