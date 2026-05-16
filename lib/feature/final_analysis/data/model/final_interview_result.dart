class FinalInterviewResult {
  const FinalInterviewResult({
    required this.status,
    this.message,
    this.interview = const <String, dynamic>{},
    this.performanceSummary = const PerformanceSummary(),
    this.categoryScores = const CategoryScores(),
    this.finalAnalysis = const FinalAnalysis(),
    this.improvementAnalysis = const ImprovementAnalysis(),
    this.visualizationReady = const VisualizationReady(),
    this.coaching = const CoachingBlock(),
    this.starRewriteExample = const StarRewriteExample(),
    this.sentenceFeedback = const <dynamic>[],
  });

  factory FinalInterviewResult.fromJson(Map<String, dynamic> json) {
    return FinalInterviewResult(
      status: (json['status'] as String? ?? 'processing').trim().toLowerCase(),
      message: _asString(json['message']),
      interview: _asMap(json['interview']),
      performanceSummary: PerformanceSummary.fromJson(
        _asMap(json['performance_summary']),
      ),
      categoryScores: CategoryScores.fromJson(_asMap(json['category_scores'])),
      finalAnalysis: FinalAnalysis.fromJson(_asMap(json['final_analysis'])),
      improvementAnalysis: ImprovementAnalysis.fromJson(
        _asMap(json['improvement_analysis']),
      ),
      visualizationReady: VisualizationReady.fromJson(
        _asMap(json['visualization_ready']),
      ),
      coaching: CoachingBlock.fromJson(_asMap(json['coaching'])),
      starRewriteExample: StarRewriteExample.fromJson(
        _asMap(json['star_rewrite_example']),
      ),
      sentenceFeedback: _asList(json['sentence_feedback']),
    );
  }

  final String status;
  final String? message;
  final Map<String, dynamic> interview;
  final PerformanceSummary performanceSummary;
  final CategoryScores categoryScores;
  final FinalAnalysis finalAnalysis;
  final ImprovementAnalysis improvementAnalysis;
  final VisualizationReady visualizationReady;
  final CoachingBlock coaching;
  final StarRewriteExample starRewriteExample;
  final List<dynamic> sentenceFeedback;
}

class OverallScore {
  const OverallScore({
    this.initial = 0,
    this.finalScore = 0,
    this.change = 0,
    this.changePercent = 0,
    this.trend = '',
  });

  factory OverallScore.fromJson(Map<String, dynamic> json) {
    return OverallScore(
      initial: _asDouble(json['initial']) ?? 0,
      finalScore: _asDouble(json['final']) ?? 0,
      change: _asDouble(json['change']) ?? 0,
      changePercent: _asDouble(json['change_percent']) ?? 0,
      trend: (_asString(json['trend']) ?? '').trim(),
    );
  }

  final double initial;
  final double finalScore;
  final double change;
  final double changePercent;
  final String trend;
}

class PerformanceSummary {
  const PerformanceSummary({
    this.overallScore = const OverallScore(),
    this.performanceLevel = '',
    this.primaryStrength = '',
    this.primaryImprovementArea = '',
  });

  factory PerformanceSummary.fromJson(Map<String, dynamic> json) {
    return PerformanceSummary(
      overallScore: OverallScore.fromJson(_asMap(json['overall_score'])),
      performanceLevel: _asString(json['performance_level']) ?? '',
      primaryStrength: _asString(json['primary_strength']) ?? '',
      primaryImprovementArea: _asString(json['primary_improvement_area']) ?? '',
    );
  }

  final OverallScore overallScore;
  final String performanceLevel;
  final String primaryStrength;
  final String primaryImprovementArea;

  double get improvementPercentage => overallScore.changePercent;

  double get overallDelta => overallScore.change;
}

class ScoreComparison {
  const ScoreComparison({
    this.initial = 0,
    this.finalScore = 0,
    this.change = 0,
    this.trend = '',
  });

  factory ScoreComparison.fromJson(Map<String, dynamic> json) {
    return ScoreComparison(
      initial: _asDouble(json['initial']) ?? 0,
      finalScore: _asDouble(json['final']) ?? 0,
      change: _asDouble(json['change']) ?? 0,
      trend: (_asString(json['trend']) ?? '').trim(),
    );
  }

  final double initial;
  final double finalScore;
  final double change;
  final String trend;

  double get delta => change != 0 ? change : (finalScore - initial);
}

class CategoryScores {
  const CategoryScores({
    this.clarity = const ScoreComparison(),
    this.structureStar = const ScoreComparison(),
    this.specificity = const ScoreComparison(),
    this.ownership = const ScoreComparison(),
    this.initiative = const ScoreComparison(),
    this.impact = const ScoreComparison(),
  });

  factory CategoryScores.fromJson(Map<String, dynamic> json) {
    return CategoryScores(
      clarity: ScoreComparison.fromJson(_asMap(json['clarity'])),
      structureStar: ScoreComparison.fromJson(_asMap(json['structure_star'])),
      specificity: ScoreComparison.fromJson(_asMap(json['specificity'])),
      ownership: ScoreComparison.fromJson(_asMap(json['ownership'])),
      initiative: ScoreComparison.fromJson(_asMap(json['initiative'])),
      impact: ScoreComparison.fromJson(_asMap(json['impact'])),
    );
  }

  final ScoreComparison clarity;
  final ScoreComparison structureStar;
  final ScoreComparison specificity;
  final ScoreComparison ownership;
  final ScoreComparison initiative;
  final ScoreComparison impact;

  Map<String, ScoreComparison> asMap() => <String, ScoreComparison>{
    'Clarity': clarity,
    'Structure STAR': structureStar,
    'Specificity': specificity,
    'Ownership': ownership,
    'Initiative': initiative,
    'Impact': impact,
  };
}

class AnalysisItem {
  const AnalysisItem({
    this.title = '',
    this.description = '',
  });

  factory AnalysisItem.fromJson(Map<String, dynamic> json) {
    return AnalysisItem(
      title: _asString(json['title']) ?? '',
      description: _asString(json['description']) ?? '',
    );
  }

  final String title;
  final String description;
}

class FinalAnalysis {
  const FinalAnalysis({
    this.summary = '',
    this.strengths = const <AnalysisItem>[],
    this.weaknesses = const <AnalysisItem>[],
    this.flags = const <String>[],
  });

  factory FinalAnalysis.fromJson(Map<String, dynamic> json) {
    return FinalAnalysis(
      summary: _asString(json['summary']) ?? '',
      strengths: _asList(json['strengths'])
          .map((dynamic item) => AnalysisItem.fromJson(_asMap(item)))
          .toList(),
      weaknesses: _asList(json['weaknesses'])
          .map((dynamic item) => AnalysisItem.fromJson(_asMap(item)))
          .toList(),
      flags: _asList(json['flags'])
          .map((dynamic item) => (item as String? ?? '').trim())
          .where((String item) => item.isNotEmpty)
          .toList(),
    );
  }

  final String summary;
  final List<AnalysisItem> strengths;
  final List<AnalysisItem> weaknesses;
  final List<String> flags;
}

class SkillChangeItem {
  const SkillChangeItem({
    required this.skill,
    this.change = 0,
    this.trend = '',
  });

  factory SkillChangeItem.fromJson(Map<String, dynamic> json) {
    return SkillChangeItem(
      skill: _asString(json['skill']) ?? '',
      change: _asDouble(json['change']) ?? 0,
      trend: (_asString(json['trend']) ?? '').trim(),
    );
  }

  final String skill;
  final double change;
  final String trend;
}

class ImprovementAnalysis {
  const ImprovementAnalysis({
    this.improvedAreaLabels = const <String>[],
    this.improvedSkills = const <SkillChangeItem>[],
    this.unchangedSkills = const <SkillChangeItem>[],
    this.regressedSkills = const <SkillChangeItem>[],
  });

  factory ImprovementAnalysis.fromJson(Map<String, dynamic> json) {
    return ImprovementAnalysis(
      improvedAreaLabels: _parseMixedSkillLabels(json['improved_areas']),
      improvedSkills: _parseSkillItems(json['improved_areas']),
      unchangedSkills: _parseSkillItems(json['unchanged_areas']),
      regressedSkills: _parseSkillItems(json['regressed_areas']),
    );
  }

  final List<String> improvedAreaLabels;
  final List<SkillChangeItem> improvedSkills;
  final List<SkillChangeItem> unchangedSkills;
  final List<SkillChangeItem> regressedSkills;
}

class VisualizationReady {
  const VisualizationReady({
    this.radarScoresInitial = const <String, double>{},
    this.radarScoresFinal = const <String, double>{},
  });

  factory VisualizationReady.fromJson(Map<String, dynamic> json) {
    return VisualizationReady(
      radarScoresInitial: _parseScoreMap(json['radar_scores_initial']),
      radarScoresFinal: _parseScoreMap(json['radar_scores_final']),
    );
  }

  final Map<String, double> radarScoresInitial;
  final Map<String, double> radarScoresFinal;

  static const List<String> _kPreferredOrder = <String>[
    'clarity',
    'structure_star',
    'specificity',
    'ownership',
    'initiative',
    'impact',
  ];

  List<String> get radarLabels {
    final Set<String> keys = <String>{
      ...radarScoresInitial.keys,
      ...radarScoresFinal.keys,
    };
    final List<String> ordered = <String>[];
    for (final String k in _kPreferredOrder) {
      if (keys.contains(k)) {
        ordered.add(k);
      }
    }
    for (final String k in keys) {
      if (!ordered.contains(k)) {
        ordered.add(k);
      }
    }
    return ordered;
  }

  List<double> scoresFor(Map<String, double> source, List<String> labels) {
    return labels
        .map((String k) => source[k] ?? 0)
        .toList(growable: false);
  }

  List<double> get initialScores => scoresFor(radarScoresInitial, radarLabels);

  List<double> get finalScores => scoresFor(radarScoresFinal, radarLabels);
}

class FollowupQuestion {
  const FollowupQuestion({this.question = '', this.targetSkill = ''});

  factory FollowupQuestion.fromJson(Map<String, dynamic> json) {
    return FollowupQuestion(
      question: _asString(json['question']) ?? '',
      targetSkill: _asString(json['target_skill']) ?? '',
    );
  }

  final String question;
  final String targetSkill;
}

class CoachingBlock {
  const CoachingBlock({
    this.recommendedTrainingMode = '',
    this.nextFocusSkill = '',
    this.coachMessage = '',
    this.followupQuestions = const <FollowupQuestion>[],
  });

  factory CoachingBlock.fromJson(Map<String, dynamic> json) {
    return CoachingBlock(
      recommendedTrainingMode:
          _asString(json['recommended_training_mode']) ?? '',
      nextFocusSkill: _asString(json['next_focus_skill']) ?? '',
      coachMessage: _asString(json['coach_message']) ?? '',
      followupQuestions: _asList(json['followup_questions'])
          .map((dynamic e) => FollowupQuestion.fromJson(_asMap(e)))
          .toList(),
    );
  }

  final String recommendedTrainingMode;
  final String nextFocusSkill;
  final String coachMessage;
  final List<FollowupQuestion> followupQuestions;

  bool get isEmpty =>
      recommendedTrainingMode.isEmpty &&
      nextFocusSkill.isEmpty &&
      coachMessage.isEmpty &&
      followupQuestions.isEmpty;
}

class StarRewriteExample {
  const StarRewriteExample({
    this.situation = '',
    this.task = '',
    this.action = '',
    this.result = '',
  });

  factory StarRewriteExample.fromJson(Map<String, dynamic> json) {
    return StarRewriteExample(
      situation: _asString(json['situation']) ?? '',
      task: _asString(json['task']) ?? '',
      action: _asString(json['action']) ?? '',
      result: _asString(json['result']) ?? '',
    );
  }

  final String situation;
  final String task;
  final String action;
  final String result;

  bool get isEmpty =>
      situation.isEmpty && task.isEmpty && action.isEmpty && result.isEmpty;
}

Map<String, double> _parseScoreMap(dynamic value) {
  final Map<String, dynamic> map = _asMap(value);
  final Map<String, double> out = <String, double>{};
  for (final MapEntry<String, dynamic> e in map.entries) {
    final double? v = _asDouble(e.value);
    if (v != null) {
      out[e.key] = v;
    }
  }
  return out;
}

List<String> _parseMixedSkillLabels(dynamic value) {
  final List<dynamic> list = _asList(value);
  final List<String> out = <String>[];
  for (final dynamic item in list) {
    if (item is String) {
      final String s = item.trim();
      if (s.isNotEmpty) {
        out.add(s);
      }
    } else if (item is Map) {
      final Map<String, dynamic> m = Map<String, dynamic>.from(item);
      final String? skill = _asString(m['skill']);
      if (skill != null && skill.isNotEmpty) {
        out.add(skill);
      }
    }
  }
  return out;
}

List<SkillChangeItem> _parseSkillItems(dynamic value) {
  final List<dynamic> list = _asList(value);
  return list
      .map((dynamic item) {
        if (item is Map) {
          return SkillChangeItem.fromJson(Map<String, dynamic>.from(item));
        }
        return const SkillChangeItem(skill: '');
      })
      .where((SkillChangeItem e) => e.skill.isNotEmpty)
      .toList();
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) {
    return value;
  }
  return <dynamic>[];
}

String? _asString(dynamic value) {
  if (value is String) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return null;
}

double? _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}
