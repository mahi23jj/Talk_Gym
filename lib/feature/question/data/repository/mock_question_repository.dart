import 'dart:async';

import 'package:talk_gym/feature/question/data/model/question_item.dart';
import 'package:talk_gym/feature/question/data/repository/question_repository.dart';

class MockQuestionRepository implements QuestionRepository {
  MockQuestionRepository();

  static const List<String> _tagPool = <String>[
    'Leadership',
    'Conflict',
    'Teamwork',
    'Failure',
    'Success',
    'Adaptability',
  ];

  final List<QuestionItem> _allItems = List<QuestionItem>.generate(48, (int i) {
    final int index = i + 1;
    final String firstTag = _tagPool[i % _tagPool.length];
    final String secondTag = _tagPool[(i + 2) % _tagPool.length];
    final String thirdTag = _tagPool[(i + 4) % _tagPool.length];

    return QuestionItem(
      id: 'q_$index',
      title: 'Tell me about a time you showed $firstTag under pressure',
      description:
          'Share a structured STAR response with context, action, and measurable impact for scenario $index.',
      tags: <String>[firstTag, secondTag, thirdTag],
      dayUnlock: (i % 12) + 1,
    );
  });

  @override
  Future<QuestionPageResult> fetchQuestions({
    required int page,
    required int pageSize,
    required String searchQuery,
    required String activeFilter,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final String normalizedSearch = searchQuery.trim().toLowerCase();

    final List<QuestionItem> filtered = _allItems.where((QuestionItem item) {
      final bool matchesFilter =
          activeFilter == 'All' || item.tags.contains(activeFilter);

      if (!matchesFilter) {
        return false;
      }

      if (normalizedSearch.isEmpty) {
        return true;
      }

      return item.title.toLowerCase().contains(normalizedSearch) ||
          item.description.toLowerCase().contains(normalizedSearch) ||
          item.tags.any((String tag) =>
              tag.toLowerCase().contains(normalizedSearch));
    }).toList();

    final int start = page * pageSize;
    if (start >= filtered.length) {
      return const QuestionPageResult(items: <QuestionItem>[], hasMore: false);
    }

    final int end = (start + pageSize).clamp(0, filtered.length);
    final List<QuestionItem> pageItems = filtered.sublist(start, end);

    return QuestionPageResult(
      items: pageItems,
      hasMore: end < filtered.length,
    );
  }
}
