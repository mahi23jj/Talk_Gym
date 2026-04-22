import 'package:talk_gym/feature/analysis_results/data/model/analysis_result.dart';
import 'package:talk_gym/feature/analysis_results/data/repository/analysis_results_repository.dart';

class StaticAnalysisResultsRepository implements AnalysisResultsRepository {
  const StaticAnalysisResultsRepository(this.analysisResult);

  final AnalysisResult analysisResult;

  @override
  Future<AnalysisResult> fetchAnalysisResults() async {
    return analysisResult;
  }
}
