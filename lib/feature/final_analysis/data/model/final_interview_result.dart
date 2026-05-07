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
}

class PerformanceSummary {
  const PerformanceSummary({
    this.performanceLevel = '',
    this.primaryStrength = '',
    this.primaryImprovementArea = '',
    this.improvementPercentage = 0,
    this.overallDelta = 0,
  });

  factory PerformanceSummary.fromJson(Map<String, dynamic> json) {
    return PerformanceSummary(
      performanceLevel: _asString(json['performance_level']) ?? '',
      primaryStrength: _asString(json['primary_strength']) ?? '',
      primaryImprovementArea: _asString(json['primary_improvement_area']) ?? '',
      improvementPercentage: _asDouble(json['improvement_percentage']) ?? 0,
      overallDelta: _asDouble(json['overall_delta']) ?? 0,
    );
  }

  final String performanceLevel;
  final String primaryStrength;
  final String primaryImprovementArea;
  final double improvementPercentage;
  final double overallDelta;
}

class ScoreComparison {
  const ScoreComparison({
    this.initial = 0,
    this.finalScore = 0,
  });

  factory ScoreComparison.fromJson(Map<String, dynamic> json) {
    return ScoreComparison(
      initial: _asDouble(json['initial']) ?? 0,
      finalScore: _asDouble(json['final']) ?? 0,
    );
  }

  final double initial;
  final double finalScore;

  double get delta => finalScore - initial;
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
    this.strengths = const <AnalysisItem>[],
    this.weaknesses = const <AnalysisItem>[],
    this.flags = const <String>[],
  });

  factory FinalAnalysis.fromJson(Map<String, dynamic> json) {
    return FinalAnalysis(
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

  final List<AnalysisItem> strengths;
  final List<AnalysisItem> weaknesses;
  final List<String> flags;
}

class ImprovementAnalysis {
  const ImprovementAnalysis({
    this.improvedAreas = const <String>[],
    this.unchangedAreas = const <String>[],
    this.regressedAreas = const <String>[],
  });

  factory ImprovementAnalysis.fromJson(Map<String, dynamic> json) {
    List<String> parseList(String key) {
      return _asList(json[key])
          .map((dynamic item) => (item as String? ?? '').trim())
          .where((String item) => item.isNotEmpty)
          .toList();
    }

    return ImprovementAnalysis(
      improvedAreas: parseList('improved_areas'),
      unchangedAreas: parseList('unchanged_areas'),
      regressedAreas: parseList('regressed_areas'),
    );
  }

  final List<String> improvedAreas;
  final List<String> unchangedAreas;
  final List<String> regressedAreas;
}

class VisualizationReady {
  const VisualizationReady({
    this.radarLabels = const <String>[],
    this.initialScores = const <double>[],
    this.finalScores = const <double>[],
  });

  factory VisualizationReady.fromJson(Map<String, dynamic> json) {
    List<double> parseNumList(String key) {
      return _asList(json[key])
          .map((dynamic item) => _asDouble(item) ?? 0)
          .toList();
    }

    return VisualizationReady(
      radarLabels: _asList(json['radar_labels'])
          .map((dynamic item) => (item as String? ?? '').trim())
          .where((String item) => item.isNotEmpty)
          .toList(),
      initialScores: parseNumList('initial_scores'),
      finalScores: parseNumList('final_scores'),
    );
  }

  final List<String> radarLabels;
  final List<double> initialScores;
  final List<double> finalScores;
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
