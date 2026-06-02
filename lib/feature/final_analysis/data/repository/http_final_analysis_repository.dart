import 'package:talk_gym/feature/final_analysis/data/model/final_interview_result.dart';
import 'package:talk_gym/feature/final_analysis/domain/repository/final_analysis_repository.dart';
import 'package:talk_gym/feature/question/data/repository/question_answer_submission_service.dart';

class HttpFinalAnalysisRepository implements FinalAnalysisRepository {
  HttpFinalAnalysisRepository({QuestionAnswerSubmissionService? service})
    : _service = service ?? QuestionAnswerSubmissionService();

  final QuestionAnswerSubmissionService _service;

  @override
  Future<FinalInterviewResult> getFinalResult( int sessionId,  int jobId) {
    return _service.pollFinalResultUntilCompleted(sessionId: sessionId, jobId: jobId);
  }
}
