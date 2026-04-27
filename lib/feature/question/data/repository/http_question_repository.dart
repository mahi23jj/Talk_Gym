import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:talk_gym/feature/question/data/model/question_item.dart';
import 'package:talk_gym/feature/question/data/repository/question_repository.dart';

class HttpQuestionRepository implements QuestionRepository {
  HttpQuestionRepository({http.Client? client, Uri? baseUri})
      : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _baseUri = baseUri ?? Uri.parse('https://f2da-102-212-68-34.ngrok-free.app');

  final http.Client _client;
  final bool _ownsClient;
  final Uri _baseUri;

  @override
  Future<QuestionPageResult> fetchQuestions({
    required int page,
    required int pageSize,
    required String searchQuery,
    required String activeFilter,
  }) async {
    final filters = await _fetchFilters();

    final normalizedFilter = activeFilter.trim();
    final normalizedSearch = searchQuery.trim();

    List<QuestionItem> allItems = [];

    if (normalizedSearch.isNotEmpty) {
      allItems = await _searchQuestions(normalizedSearch);
    } else {
      allItems = await _fetchQuestionsByTag(
        normalizedFilter == 'All' ? null : normalizedFilter,
      );
    }

    debugPrint("Fetched items BEFORE filter: ${allItems.length}");

    // 🔥 safer filtering (fix: case + trimming issues)
    if (normalizedFilter != 'All') {
      final filterNeedle = normalizedFilter.toLowerCase();

      allItems = allItems.where((item) {
        return item.tags.any((tag) {
          return tag.toLowerCase().trim() == filterNeedle;
        });
      }).toList();

      debugPrint("After filter: ${allItems.length}");
    }

    // sort newest first
    allItems.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    final start = page * pageSize;
    if (start >= allItems.length) {
      return QuestionPageResult(
        items: [],
        hasMore: false,
        availableFilters: filters,
      );
    }

    final end = (start + pageSize).clamp(0, allItems.length);

    final pageItems = allItems.sublist(start, end);

    debugPrint("Returning page items: ${pageItems.length}");

    return QuestionPageResult(
      items: pageItems,
      hasMore: end < allItems.length,
      availableFilters: filters,
    );
  }

  // ---------------- SEARCH ----------------

  Future<List<QuestionItem>> _searchQuestions(String keyword) async {
    final uri = _buildUri('/api/v1/questions/search', {
      'keyword': keyword,
    });

    final data = await _getJson(uri);

    final list = _extractList(data, 'search');

    return list.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return QuestionItem.fromSearchJson(map);
    }).toList();
  }

  // ---------------- FILTER ----------------

  Future<List<QuestionItem>> _fetchQuestionsByTag(String? tag) async {
    final uri = _buildUri(
      '/api/v1/questions/by-tags/filter',
      tag == null || tag.isEmpty ? null : {'tags': tag},
    );

    final data = await _getJson(uri);
    final list = _extractList(data, 'questions');

    return list.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return QuestionItem.fromFilterJson(map);
    }).toList();
  }

  // ---------------- FILTER LIST ----------------

  Future<List<String>> _fetchFilters() async {
    final uri = _buildUri('/api/v1/questions/tags/list');

    try {
      final data = await _getJson(uri);
      final list = _extractList(data, 'tags');

      final Set<String> result = {'All'};

      for (final item in list) {
        if (item is! Map) continue;

        final tag = item['tag'];
        if (tag is! Map) continue;

        final name = (tag['name'] ?? '').toString().trim();
        if (name.isNotEmpty) {
          result.add(name);
        }
      }

      return result.toList();
    } catch (e) {
      debugPrint("Filter error: $e");
      return ['All'];
    }
  }

  // ---------------- HTTP ----------------

  Future<dynamic> _getJson(Uri uri) async {
    try {
      final response = await _client.get(uri, headers: _headers);

      debugPrint("GET ${uri.toString()} => ${response.statusCode}");

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.body}',
        );
      }

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("HTTP ERROR: $e");
      rethrow;
    }
  }

  List<dynamic> _extractList(dynamic body, String context) {
    if (body is List) return body;

    if (body is Map) {
      final map = Map<String, dynamic>.from(body);

      final keys = ['data', 'items', 'questions', 'results'];

      for (final key in keys) {
        final value = map[key];

        if (value is List) {
          return value;
        }

        // 🔥 FIX: nested data support (VERY COMMON BUG FIX)
        if (value is Map && value['items'] is List) {
          return value['items'];
        }
      }
    }

    debugPrint("RAW RESPONSE ($context): $body");

    throw FormatException('Invalid $context response format');
  }

  Uri _buildUri(String path, [Map<String, String>? query]) {
    return _baseUri.replace(
      path: path,
      queryParameters: query,
    );
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
      };

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
