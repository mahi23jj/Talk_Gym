import 'package:talk_gym/feature/question/data/model/question_item.dart';
import 'package:talk_gym/feature/star_training/data/model/star_training_models.dart';

abstract class StarTrainingRepository {
  Future<StarTrainingSession> fetchSession(QuestionItem question);
}
