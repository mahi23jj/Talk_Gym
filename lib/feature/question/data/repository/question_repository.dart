import 'package:talk_gym/feature/question/data/model/question_item.dart';

class QuestionPageResult {
  const QuestionPageResult({
    required this.items,
    required this.hasMore,
  });

  final List<QuestionItem> items;
  final bool hasMore;
}

abstract class QuestionRepository {
  Future<QuestionPageResult> fetchQuestions({
    required int page,
    required int pageSize,
    required String searchQuery,
    required String activeFilter,
  });
}
