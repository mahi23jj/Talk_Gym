import 'package:talk_gym/feature/question/data/model/question_item.dart';

enum StarPart { situation, task, action, result }

extension StarPartX on StarPart {
  String get shortLabel {
    switch (this) {
      case StarPart.situation:
        return 'S';
      case StarPart.task:
        return 'T';
      case StarPart.action:
        return 'A';
      case StarPart.result:
        return 'R';
    }
  }

  String get title {
    switch (this) {
      case StarPart.situation:
        return 'SITUATION';
      case StarPart.task:
        return 'TASK';
      case StarPart.action:
        return 'ACTION';
      case StarPart.result:
        return 'RESULT';
    }
  }

  String get helper {
    switch (this) {
      case StarPart.situation:
        return 'What was happening?';
      case StarPart.task:
        return 'What was your responsibility?';
      case StarPart.action:
        return 'What did YOU do?';
      case StarPart.result:
        return 'What changed because of you?';
    }
  }
}

class StarStepContent {
  const StarStepContent({
    required this.part,
    required this.prompt,
    required this.example,
    required this.icon,
  });

  final StarPart part;
  final String prompt;
  final String example;
  final String icon;
}

class StarAnswer {
  const StarAnswer({
    this.audioPath,
    this.durationSeconds,
    this.waveform = const <double>[],
    this.text = '',
  });

  final String? audioPath;
  final int? durationSeconds;
  final List<double> waveform;
  final String text;

  bool get hasVoice => audioPath != null && durationSeconds != null;
  bool get hasText => text.trim().isNotEmpty;
  bool get hasAny => hasVoice || hasText;

  StarAnswer copyWith({
    String? audioPath,
    int? durationSeconds,
    List<double>? waveform,
    String? text,
    bool clearAudio = false,
  }) {
    return StarAnswer(
      audioPath: clearAudio ? null : (audioPath ?? this.audioPath),
      durationSeconds: clearAudio ? null : (durationSeconds ?? this.durationSeconds),
      waveform: waveform ?? this.waveform,
      text: text ?? this.text,
    );
  }
}

class StarTrainingSession {
  const StarTrainingSession({
    required this.question,
    required this.steps,
    required this.socialProof,
    required this.feedback,
  });

  final QuestionItem question;
  final List<StarStepContent> steps;
  final String socialProof;
  final String feedback;
}
