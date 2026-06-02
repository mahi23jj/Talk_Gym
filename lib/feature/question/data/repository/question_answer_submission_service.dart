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

  Future<Map<String, dynamic>> submitFinalAnswer({
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
    final int? sessionId = _asInt(json['session_id']);
    final int? jobId = _asInt(json['job_id']);
    if (sessionId == null) {
      throw const FormatException('Final submit response missing session_id.');
    }

    if (jobId == null) {
      throw const FormatException('Final submit response missing job_id.');
    }
    return {
      'session_id': sessionId,
      'job_id': jobId,
    };
  }

  Future<FinalInterviewResult> fetchFinalResult({
    required int sessionId,
    required int jobId,
    String? bearerToken,
  }) async {
    final String resolvedBearerToken = await _resolveBearerToken(bearerToken);
    final Uri uri = _baseUri.replace(
      path:'/api/v1/attempt/result/${jobId}/final/${sessionId}',
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
    final Map<String, dynamic> analysis = _asMap(json['analysis']);
    final Map<String, dynamic> analysisPayload = analysis.isNotEmpty ? analysis : json;
    final Map<String, dynamic> rawAnalysis = _asMap(
      analysisPayload['raw_analysis_json'] ?? json['raw_analysis_json'],
    );
    final Map<String, dynamic> content = _asMap(rawAnalysis['content']);
    final Map<String, dynamic> behavioral = _asMap(rawAnalysis['behavioral']);
    final Map<String, dynamic> voiceMetrics = _asMap(
      rawAnalysis['voice_metrics'] ?? analysisPayload['voice_metrics'],
    );
    final String status =
        (_asString(
                  analysisPayload['status'] ??
                      json['status'] ??
                      analysisPayload['analysis_status'],
                ) ??
                'processing')
            .toLowerCase();
    final double overallScore =
        _asDouble(rawAnalysis['overall_score']) ??
        _asDouble(analysisPayload['score']) ??
        _asDouble(json['score']) ??
        0;
    final Map<String, dynamic> scoreMap = <String, dynamic>{
      'clarity': content['clarity'],
      'structure_star': content['structure_star'],
      'specificity': content['specificity'],
      'ownership': behavioral['ownership'],
      'initiative': behavioral['initiative'],
      'impact': behavioral['impact'],
    };
    final List<Map<String, dynamic>> rankedScores = _rankedScoreItems(scoreMap);

    final Map<String, dynamic> mappedJson = {
      'status': status,
      'message': _asString(analysisPayload['feedback'] ?? json['message']),
      'interview': {},
      'performance_summary': {
        'overall_score': {
          'initial': 0,
          'final': overallScore,
          'change': overallScore,
          'change_percent': 0,
          'trend': status == 'failed' || status == 'error' ? 'regressed' : 'reviewed',
        },
        'performance_level': _asString(analysisPayload['performance_level']) ?? 'reviewed',
        'primary_strength': _labelForScoreItem(
          rankedScores.isNotEmpty ? rankedScores.first : null,
        ),
        'primary_improvement_area': _labelForScoreItem(
          rankedScores.isNotEmpty ? rankedScores.last : null,
        ),
      },
      'category_scores': {
        'clarity': _buildScoreComparison(content['clarity']),
        'structure_star': _buildScoreComparison(content['structure_star']),
        'specificity': _buildScoreComparison(content['specificity']),
        'ownership': _buildScoreComparison(behavioral['ownership']),
        'initiative': _buildScoreComparison(behavioral['initiative']),
        'impact': _buildScoreComparison(behavioral['impact']),
      },
      'final_analysis': {
        'summary': _asString(
              rawAnalysis['short_feedback'] ??
                  voiceMetrics['summary'] ??
                  analysisPayload['feedback'],
            ) ??
            '',
        'strengths': _analysisItemsFromScores(
          rankedScores.take(2).toList(growable: false),
          'Strength',
        ),
        'weaknesses': _analysisItemsFromScores(
          rankedScores.reversed.take(2).toList(growable: false),
          'Improve',
        ),
        'flags': rawAnalysis['flags'] ?? const <String>[],
      },
      'improvement_analysis': {
        'improved_areas': rankedScores
            .take(2)
            .map((Map<String, dynamic> item) => item['label'])
            .toList(growable: false),
        'unchanged_areas': const <dynamic>[],
        'regressed_areas': rankedScores
            .reversed
            .take(2)
            .map((Map<String, dynamic> item) => <String, dynamic>{
                  'skill': item['label'],
                  'change': item['score'],
                  'trend': 'low',
                })
            .toList(growable: false),
      },
      'visualization_ready': {
        'radar_scores_initial': <String, dynamic>{
          'clarity': 0,
          'structure_star': 0,
          'specificity': 0,
          'ownership': 0,
          'initiative': 0,
          'impact': 0,
        },
        'radar_scores_final': scoreMap,
      },
      'coaching': {
        'recommended_training_mode':
            _asString(rawAnalysis['primary_training_mode']) ?? 'behavioral_training',
        'next_focus_skill': _labelForScoreItem(
          rankedScores.isNotEmpty ? rankedScores.last : null,
        ),
        'coach_message': _asString(
              rawAnalysis['short_feedback'] ?? voiceMetrics['summary'],
            ) ??
            '',
        'followup_questions': rawAnalysis['behavioral_questions'] ?? const <dynamic>[],
      },
      'star_rewrite_example': _starRewriteFromRaw(rawAnalysis['star_example']),
      'sentence_feedback': rawAnalysis['sentence_feedback'] ?? [],
    };

    return FinalInterviewResult.fromJson(mappedJson);
  }

  Map<String, dynamic> _buildScoreComparison(dynamic score) {
    final double value = _asDouble(score) ?? 0;
    return {
      'initial': 0,
      'final': value,
      'change': value,
      'trend': value > 0 ? 'reviewed' : 'stable',
    };
  }

  List<Map<String, dynamic>> _rankedScoreItems(Map<String, dynamic> scoreMap) {
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[
      <String, dynamic>{'label': 'Clarity', 'score': _asDouble(scoreMap['clarity']) ?? 0},
      <String, dynamic>{'label': 'Structure STAR', 'score': _asDouble(scoreMap['structure_star']) ?? 0},
      <String, dynamic>{'label': 'Specificity', 'score': _asDouble(scoreMap['specificity']) ?? 0},
      <String, dynamic>{'label': 'Ownership', 'score': _asDouble(scoreMap['ownership']) ?? 0},
      <String, dynamic>{'label': 'Initiative', 'score': _asDouble(scoreMap['initiative']) ?? 0},
      <String, dynamic>{'label': 'Impact', 'score': _asDouble(scoreMap['impact']) ?? 0},
    ];
    items.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final int compare = (b['score'] as double).compareTo(a['score'] as double);
      if (compare != 0) {
        return compare;
      }
      return (a['label'] as String).compareTo(b['label'] as String);
    });
    return items;
  }

  String _labelForScoreItem(Map<String, dynamic>? item) {
    if (item == null) {
      return '';
    }
    final String label = (item['label'] as String? ?? '').trim();
    final double score = (item['score'] as double?) ?? 0;
    if (label.isEmpty) {
      return '';
    }
    return '$label (${score.toStringAsFixed(1)}/10)';
  }

  List<Map<String, dynamic>> _analysisItemsFromScores(
    List<Map<String, dynamic>> items,
    String prefix,
  ) {
    return items
        .map((Map<String, dynamic> item) => <String, dynamic>{
              'title': item['label'],
              'description': '$prefix score: ${(item['score'] as double).toStringAsFixed(1)}/10',
            })
        .toList(growable: false);
  }

  Map<String, dynamic> _starRewriteFromRaw(dynamic value) {
    final Map<String, dynamic> star = _asMap(value);
    return <String, dynamic>{
      'situation': _asString(star['s']) ?? _asString(star['situation']) ?? '',
      'task': _asString(star['t']) ?? _asString(star['task']) ?? '',
      'action': _asString(star['a']) ?? _asString(star['action']) ?? '',
      'result': _asString(star['r']) ?? _asString(star['result']) ?? '',
    };
  }

  Future<FinalInterviewResult> pollFinalResultUntilCompleted({
    required int sessionId,
    required int jobId,
    String? bearerToken,
    Duration pollInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final DateTime startedAt = DateTime.now();

    while (DateTime.now().difference(startedAt) < timeout) {
      final FinalInterviewResult result = await fetchFinalResult(
        sessionId: sessionId,
        jobId: jobId,
        bearerToken: bearerToken,
      );
      final String status = result.status.toLowerCase();

      if (status == 'done' || status == 'completed') {
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

    print('Analysis completed for jobId=$jobId');

    return jobId;
  }


  // summit and wait for final result (for final interview question)
  Future<FinalInterviewResult> submitFinalAndAwaitResult({  
    required int attemptId,
    required int durationSeconds,
    String? bearerToken,
    required String voiceFilePath,
  }) async {
    final Map<String, dynamic> submissionResult = await submitFinalAnswer(
      attemptId: attemptId,
      durationSeconds: durationSeconds,
      bearerToken: bearerToken,
      voiceFilePath: voiceFilePath,
    );

    final int sessionId = submissionResult['session_id'];
    final int jobId = submissionResult['job_id'];

    print('Submitted final answer: sessionId=$sessionId, jobId=$jobId');

    final FinalInterviewResult result = await pollFinalResultUntilCompleted(
      sessionId: sessionId,
      jobId: jobId,
      bearerToken: bearerToken,
    );

    print('Final analysis completed for sessionId=$sessionId, jobId=$jobId');

    return result;
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
