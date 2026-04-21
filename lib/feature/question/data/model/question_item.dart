class QuestionItem {
  const QuestionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.dayUnlock,
    this.createdAt,
  });

  final int id;
  final String title;
  final String description;
  final List<String> tags;
  final int dayUnlock;
  final DateTime? createdAt;

  factory QuestionItem.fromSearchJson(Map<String, dynamic> json) {
    return QuestionItem(
      id: _parseInt(json['id']),
      title: (json['title'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      tags: _parseTags(json['tags']),
      dayUnlock: 1,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  factory QuestionItem.fromFilterJson(Map<String, dynamic> json) {
    final dynamic source = json['question'] ?? json;
    if (source is! Map<String, dynamic>) {
      throw const FormatException('Invalid question payload.');
    }

    return QuestionItem(
      id: _parseInt(source['id']),
      title: (source['title'] as String? ?? '').trim(),
      description: (source['description'] as String? ?? '').trim(),
      tags: _parseTags(source['tags']),
      dayUnlock: 1,
      createdAt: _parseDateTime(source['created_at']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static List<String> _parseTags(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .whereType<String>()
        .map((String tag) => tag.trim())
        .where((String tag) => tag.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
