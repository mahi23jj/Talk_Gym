import 'package:flutter/foundation.dart';

@immutable
class BehavioralQuestion {
  const BehavioralQuestion({
    required this.id,
    required this.text,
    required this.category,
  });

  final String id;
  final String text;
  final String category;
}
