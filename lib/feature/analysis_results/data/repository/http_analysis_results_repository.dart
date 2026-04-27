import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:talk_gym/core/auth_token_storage.dart';
import 'package:talk_gym/feature/analysis_results/data/model/analysis_result.dart';
import 'package:talk_gym/feature/analysis_results/data/repository/analysis_results_repository.dart';

class HttpAnalysisResultsRepository implements AnalysisResultsRepository {
  HttpAnalysisResultsRepository({
    required this.attemptId,
    http.Client? client,
    Uri? baseUri,
  })  : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _baseUri = baseUri ?? Uri.parse('https://f2da-102-212-68-34.ngrok-free.app');

  final String attemptId;
  final http.Client _client;
  final bool _ownsClient;
  final Uri _baseUri;

  @override
  Future<AnalysisResult> fetchAnalysisResults() async {
    final String bearerToken = await _resolveBearerToken();
    final Uri endpoint = _baseUri.replace(
      path: '/api/v1/attempt/analysis/$attemptId',
    );

    final http.Response response = await _client.get(
      endpoint,
      headers: <String, String>{
        'Authorization': 'Bearer $bearerToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Failed to fetch analysis result. HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Invalid analysis response format.');
    }

    // The API returns the analysis object at the top level (fields like
    // `score` and `raw_analysis_json`). The `AnalysisResult.fromJson`
    // implementation expects a wrapper map with key `analysis` containing
    // that object. Wrap the decoded response so the model can parse it.
    final Map<String, dynamic> wrapper = <String, dynamic>{
      'analysis': Map<String, dynamic>.from(decoded),
    };

    return AnalysisResult.fromJson(wrapper);
  }

  Future<String> _resolveBearerToken() async {
    final String token = (await AuthTokenStorage.getToken() ?? '').trim();
    if (token.isEmpty) {
      throw StateError(
        'Missing authentication token. Please login/signin first.',
      );
    }
    return token;
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}