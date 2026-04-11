class QuestionItem {
  const QuestionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.dayUnlock,
  });

  final String id;
  final String title;
  final String description;
  final List<String> tags;
  final int dayUnlock;
}
