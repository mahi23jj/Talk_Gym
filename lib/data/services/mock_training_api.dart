import 'dart:async';

import 'package:talk_gym/feature/behavioral_training/models/behavioral_question.dart';

class MockTrainingApi {
  Future<List<BehavioralQuestion>> fetchQuestions() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return const <BehavioralQuestion>[
      BehavioralQuestion(
        id: 'q1',
        text: 'Tell me about a time you faced a conflict at work',
        category: 'Conflict',
      ),
      BehavioralQuestion(
        id: 'q2',
        text: 'Describe a situation where you showed leadership',
        category: 'Leadership',
      ),
      BehavioralQuestion(
        id: 'q3',
        text: 'Give me an example of a failure and how you handled it',
        category: 'Failure',
      ),
      BehavioralQuestion(
        id: 'q4',
        text: 'Tell me about a time you had to learn something quickly',
        category: 'Learning',
      ),
      BehavioralQuestion(
        id: 'q5',
        text: 'Describe when you went above and beyond for a customer',
        category: 'Customer Focus',
      ),
    ];
  }

  Future<String> fetchOriginalContent(String questionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    const Map<String, String> answers = <String, String>{
      'q1': 'I had a conflict with a coworker about a project. We disagreed on the approach. I talked to them and we figured it out. In the end, the project was successful and everyone was happy.',
      'q2': 'I led a team during a deadline crunch. We worked hard and did our best. It went well and the manager was happy.',
      'q3': 'I failed to deliver a report on time once. I tried to recover and basically fixed it later. Everyone was okay with it.',
      'q4': 'I had to learn a new framework really quickly. I worked hard and got it done. It went well.',
      'q5': 'A customer needed urgent help and we did our best. I tried to solve the issue and everyone was happy in the end.',
    };

    return answers[questionId] ??
        'I worked hard on a project and my team was happy. I led the team to success. We improved things a lot.';
  }
}
