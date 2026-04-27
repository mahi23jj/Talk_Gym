import 'package:talk_gym/feature/analysis_results/data/model/analysis_result.dart';
import 'package:talk_gym/feature/question/data/model/question_item.dart';
import 'package:talk_gym/feature/star_training/data/model/star_training_models.dart';

abstract class StarTrainingRepository {
  Future<StarTrainingSession> fetchSession(QuestionItem question , StarMetrics analysisResult);
}
