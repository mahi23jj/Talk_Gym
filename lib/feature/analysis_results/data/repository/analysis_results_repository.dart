import 'package:talk_gym/feature/analysis_results/data/model/analysis_result.dart';

abstract class AnalysisResultsRepository {
  Future<AnalysisResult> fetchAnalysisResults();
}