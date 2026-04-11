// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:talk_gym/main.dart';

void main() {
  testWidgets('Question Listing page renders header', (WidgetTester tester) async {
    await tester.pumpWidget(const TalkGymApp());
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Behavioral Questions'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
  });
}
