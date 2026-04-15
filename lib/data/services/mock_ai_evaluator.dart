import 'dart:async';

import 'package:talk_gym/feature/behavioral_training/models/evaluation_result.dart';
import 'package:talk_gym/feature/behavioral_training/models/highlight_info.dart';

class MockAiEvaluator {
  Future<Map<String, HighlightInfo>> highlightWeakSentences(String answer) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    final Map<String, HighlightInfo> highlights = <String, HighlightInfo>{};
    final Iterable<RegExpMatch> matches = RegExp(r'[^.!?]+[.!?]?').allMatches(answer);

    for (final RegExpMatch match in matches) {
      final String rawSentence = match.group(0) ?? '';
      final String sentence = rawSentence.trim();
      if (sentence.isEmpty) {
        continue;
      }

      final String normalized = sentence.toLowerCase();
      final HighlightIssueType? issueType = _detectIssueType(normalized);
      if (issueType == null) {
        continue;
      }

      highlights[sentence] = HighlightInfo(
        sentence: sentence,
        issueType: issueType,
        suggestion: _suggestionForIssue(issueType),
        example: _exampleForIssue(issueType),
        startIndex: match.start,
        endIndex: match.end,
      );
    }

    return highlights;
  }

  Future<EvaluationResult> evaluateAnswer({
    required String answer,
    required bool isFinalPolish,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final String normalized = answer.toLowerCase();
    final int situation = _scoreSituation(normalized);
    final int task = _scoreTask(normalized);
    final int action = _scoreAction(normalized);
    final int result = _scoreResult(normalized);

    int score = ((situation + task + action + result) / 4 * 10).round();
    if (isFinalPolish) {
      score = (score + 8).clamp(0, 100);
    }

    final List<String> suggestions = <String>[];
    if (!_hasMetric(normalized)) {
      suggestions.add('Add a metric to your Result (for example, improved by 30% or saved 12 hours monthly).');
    }
    if (normalized.contains(' we ')) {
      suggestions.add('Replace we with I to make your personal contribution explicit.');
    }
    if (!_mentionsStakes(normalized)) {
      suggestions.add('Make the Situation more specific by stating what was at risk.');
    }
    if (suggestions.isEmpty) {
      suggestions.add('Tighten wording and remove filler phrases to improve delivery confidence.');
    }

    final List<String> strengths = <String>[];
    if (action >= 7) {
      strengths.add('Clear Action sequence');
    }
    if (situation >= 7) {
      strengths.add('Strong context setting for the interview question');
    }
    if (strengths.isEmpty) {
      strengths.add('You have a clear narrative foundation to build on');
    }

    final Map<String, int> star = <String, int>{
      'Situation': situation,
      'Task': task,
      'Action': action,
      'Result': result,
    };

    return EvaluationResult(
      score: score,
      starMethodScore: star,
      overallFeedback:
          'Your Action section is stronger than your Result section. Interviewers want concrete impact. Add one or two measurable outcomes and be explicit about what you personally drove.',
      specificSuggestions: suggestions,
      strengths: strengths,
      improvedVersion: _buildImprovedVersion(answer, includeMetric: result < 8),
    );
  }

  HighlightIssueType? _detectIssueType(String normalizedSentence) {
    if (normalizedSentence.contains('worked hard') ||
        normalizedSentence.contains('did my best') ||
        normalizedSentence.contains('tried to')) {
      return HighlightIssueType.tooVague;
    }

    if (normalizedSentence.contains('everyone was happy') ||
        normalizedSentence.contains('it went well') ||
        normalizedSentence.contains('basically') ||
        normalizedSentence.contains('really') ||
        normalizedSentence.contains('very')) {
      return HighlightIssueType.cliche;
    }

    if (normalizedSentence.contains(' we ')) {
      return HighlightIssueType.passiveVoice;
    }

    if (!_hasActionVerb(normalizedSentence)) {
      return HighlightIssueType.noAction;
    }

    if (!_hasMetric(normalizedSentence)) {
      return HighlightIssueType.noMetric;
    }

    if (!_containsStarSignal(normalizedSentence)) {
      return HighlightIssueType.missingSTAR;
    }

    return null;
  }

  String _suggestionForIssue(HighlightIssueType issueType) {
    switch (issueType) {
      case HighlightIssueType.tooVague:
        return 'Replace vague effort language with concrete actions and decisions you made.';
      case HighlightIssueType.missingSTAR:
        return 'Add one STAR element that is missing: context, responsibility, action, or measurable result.';
      case HighlightIssueType.noMetric:
        return 'Include a number, percentage, timeline, or volume to make the impact measurable.';
      case HighlightIssueType.noAction:
        return 'Use action verbs that show what you directly executed.';
      case HighlightIssueType.passiveVoice:
        return 'Shift ownership from we to I where appropriate so your contribution is clear.';
      case HighlightIssueType.cliche:
        return 'Remove filler words and replace them with specific evidence and outcomes.';
    }
  }

  String _exampleForIssue(HighlightIssueType issueType) {
    switch (issueType) {
      case HighlightIssueType.tooVague:
        return 'I mapped three process bottlenecks, introduced an approval checklist, and cut cycle time by 28%.';
      case HighlightIssueType.missingSTAR:
        return 'The release was blocked by repeated QA failures (Situation). I owned the fix plan (Task). I automated regression tests and aligned stakeholders daily (Action). We shipped two weeks early (Result).';
      case HighlightIssueType.noMetric:
        return 'I redesigned the onboarding flow and reduced drop-off from 42% to 27% in six weeks.';
      case HighlightIssueType.noAction:
        return 'I negotiated priorities with engineering and implemented a phased rollout plan.';
      case HighlightIssueType.passiveVoice:
        return 'I facilitated the decision meeting, presented the tradeoffs, and secured alignment on the migration path.';
      case HighlightIssueType.cliche:
        return 'I resolved 14 escalations in one month and raised customer satisfaction from 3.9 to 4.6.';
    }
  }

  bool _hasMetric(String text) {
    return RegExp(r'(\d+\s?%|\d+\s?(hours|days|weeks|months)|\$\d+|\d+)').hasMatch(text);
  }

  bool _hasActionVerb(String text) {
    const List<String> verbs = <String>[
      'implemented',
      'designed',
      'built',
      'created',
      'led',
      'resolved',
      'scheduled',
      'planned',
      'automated',
      'improved',
      'analyzed',
      'delivered',
    ];
    return verbs.any(text.contains);
  }

  bool _containsStarSignal(String text) {
    return text.contains('situation') ||
        text.contains('responsibility') ||
        text.contains('result') ||
        text.contains('because') ||
        text.contains('therefore') ||
        text.contains('so that');
  }

  bool _mentionsStakes(String text) {
    return text.contains('deadline') ||
        text.contains('risk') ||
        text.contains('blocked') ||
        text.contains('impact') ||
        text.contains('at stake');
  }

  int _scoreSituation(String text) {
    int score = 4;
    if (_mentionsStakes(text)) {
      score += 3;
    }
    if (text.length > 80) {
      score += 1;
    }
    if (_hasMetric(text)) {
      score += 1;
    }
    return score.clamp(1, 10);
  }

  int _scoreTask(String text) {
    int score = 4;
    if (text.contains('responsible') || text.contains('owned') || text.contains('my role')) {
      score += 3;
    }
    if (text.contains('i ')) {
      score += 1;
    }
    if (text.contains('deadline') || text.contains('goal')) {
      score += 1;
    }
    return score.clamp(1, 10);
  }

  int _scoreAction(String text) {
    int score = 5;
    if (_hasActionVerb(text)) {
      score += 3;
    }
    if (text.contains('scheduled') || text.contains('implemented') || text.contains('analyzed')) {
      score += 1;
    }
    return score.clamp(1, 10);
  }

  int _scoreResult(String text) {
    int score = 3;
    if (_hasMetric(text)) {
      score += 4;
    }
    if (text.contains('launched') || text.contains('reduced') || text.contains('increased')) {
      score += 2;
    }
    return score.clamp(1, 10);
  }

  String _buildImprovedVersion(String answer, {required bool includeMetric}) {
    String rewritten = answer
        .replaceAll('worked hard', 'identified priority bottlenecks and executed a focused plan')
        .replaceAll('did my best', 'coordinated stakeholders and delivered concrete actions')
        .replaceAll('we figured it out', 'I facilitated alignment and documented an execution plan')
        .replaceAll('everyone was happy', 'stakeholder confidence improved based on delivery quality');

    if (includeMetric && !rewritten.contains('%')) {
      rewritten = '$rewritten I also tracked outcomes weekly and reduced turnaround time by 30% over six weeks.';
    }

    return rewritten;
  }
}
