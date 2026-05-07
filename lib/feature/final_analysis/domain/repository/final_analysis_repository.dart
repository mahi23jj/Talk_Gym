import 'package:talk_gym/feature/final_analysis/data/model/final_interview_result.dart';

abstract class FinalAnalysisRepository {
  Future<FinalInterviewResult> getFinalResult(String sessionId);
}
