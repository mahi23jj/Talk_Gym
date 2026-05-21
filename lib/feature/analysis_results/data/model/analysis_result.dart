import 'package:flutter/foundation.dart';

@immutable
class ContentMetrics {
  const ContentMetrics({
    required this.relevance,
    required this.clarity,
    required this.structureStar,
    required this.specificity,
  });

  final int relevance;
  final int clarity;
  final int structureStar;
  final int specificity;

  factory ContentMetrics.fromJson(Map<String, dynamic> json) {
    return ContentMetrics(
      relevance: _asInt(json['relevance']),
      clarity: _asInt(json['clarity']),
      structureStar: _asInt(json['structure_star']),
      specificity: _asInt(json['specificity']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'relevance': relevance,
      'clarity': clarity,
      'structure_star': structureStar,
      'specificity': specificity,
    };
  }
}

@immutable
class StarMetrics {
  const StarMetrics({
    required this.situation,
    required this.task,
    required this.action,
    required this.result,
  });

  final String situation;
  final String task;
  final String action;
  final String result;

  factory StarMetrics.fromJson(Map<String, dynamic> json) {
    return StarMetrics(
      situation: _asString(json['s']),
      task: _asString(json['t']),
      action: _asString(json['a']),
      result: _asString(json['r']),
    );
  }

  // Map<String, dynamic> toJson() {
  //   return <String, dynamic>{
  //     'relevance': relevance,
  //     'clarity': clarity,
  //     'structure_star': structureStar,
  //     'specificity': specificity,
  //   };
  // }
}

@immutable
class BehavioralMetrics {
  const BehavioralMetrics({
    required this.ownership,
    required this.initiative,
    required this.impact,
  });

  final int ownership;
  final int initiative;
  final int impact;

  factory BehavioralMetrics.fromJson(Map<String, dynamic> json) {
    return BehavioralMetrics(
      ownership: _asInt(json['ownership']),
      initiative: _asInt(json['initiative']),
      impact: _asInt(json['impact']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ownership': ownership,
      'initiative': initiative,
      'impact': impact,
    };
  }
}

@immutable
class BehavioralQuestions {
  const BehavioralQuestions({
    required this.question,
    required this.target,
    required this.example,
  });

  final String question;
  final String target;
  final String example;

  factory BehavioralQuestions.fromJson(Map<String, dynamic> json) {
    return BehavioralQuestions(
      question: _asString(json['question']),
      target: _asString(json['target_improvement'] ?? json['target']),
      example: _asString(json['strong_answer_example'] ?? json['example']),
    );
  }

 
}

@immutable
class SentenceFeedback {
  const SentenceFeedback({
    required this.idx,
    required this.sentenceIndex,
    required this.sentence,
    required this.indexedSentence,
    required this.issue,
    required this.improvementType,
    required this.improvedExample,
  });

  final int idx;
  final int sentenceIndex;
  final String sentence;
  final String indexedSentence;
  final String issue;
  final String improvementType;
  final String improvedExample;

  factory SentenceFeedback.fromJson(Map<String, dynamic> json) {
    return SentenceFeedback(
      idx: _asInt(json['idx']),
      sentenceIndex: _asInt(json['sentence_index']),
      sentence: _asString(json['sentence']),
      indexedSentence: _asString(json['indexed_sentence']),
      issue: _asString(json['issue']),
      improvementType: _asString(json['improvement_type']),
      improvedExample: _asString(json['improved_example']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'idx': idx,
      'sentence_index': sentenceIndex,
      'sentence': sentence,
      'indexed_sentence': indexedSentence,
      'issue': issue,
      'improvement_type': improvementType,
      'improved_example': improvedExample,
    };
  }
}

@immutable
class AnalysisResult {
  const AnalysisResult({
    required this.overallScore,
    required this.transcript,
    required this.transcriptSentences,
    required this.contentMetrics,
    required this.behavioralMetrics,
    required this.flags,
    required this.sentenceFeedback,
    required this.primaryTrainingMode,
    required this.shortFeedback,
    required this.starExample,
    required this.behavioralQuestions,
  });

  final int overallScore;
  final String transcript;
  final Map<int, String> transcriptSentences;
  final ContentMetrics contentMetrics;
  final BehavioralMetrics behavioralMetrics;
  final List<String> flags;
  final List<SentenceFeedback> sentenceFeedback;
  final String primaryTrainingMode;
  final String shortFeedback;
  final StarMetrics starExample;
  final List<BehavioralQuestions> behavioralQuestions;

  bool get isBehavioralTraining => primaryTrainingMode == 'behavioral_training';

  List<BehavioralQuestions> get behavioral_questions => behavioralQuestions;

  /* factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final Map<int, String> transcriptSentences = <int, String>{};
    final dynamic rawTranscriptSentences = json['transcript_sentences'];
    if (rawTranscriptSentences is Map) {
      rawTranscriptSentences.forEach((dynamic key, dynamic value) {
        final int? index = int.tryParse('$key');
        if (index != null) {
          transcriptSentences[index] = value.toString();
        }
      });
    }

    final List<SentenceFeedback> sentenceFeedback = <SentenceFeedback>[];
    final dynamic rawFeedback = json['sentence_feedback'];
    if (rawFeedback is List) {
      for (final dynamic item in rawFeedback) {
        if (item is Map<String, dynamic>) {
          sentenceFeedback.add(SentenceFeedback.fromJson(item));
        } else if (item is Map) {
          sentenceFeedback.add(
            SentenceFeedback.fromJson(item.cast<String, dynamic>()),
          );
        }
      }
    }

    final List<String> flags = <String>[];
    final dynamic rawFlags = json['flags'];
    if (rawFlags is List) {
      flags.addAll(rawFlags.map((dynamic value) => value.toString()));
    }

    return AnalysisResult(
      overallScore: _asInt(json['overall_score']),
      transcript: _asString(json['transcript']),
      transcriptSentences: transcriptSentences,
      contentMetrics: ContentMetrics.fromJson(
        (json['content_metrics'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
      behavioralMetrics: BehavioralMetrics.fromJson(
        (json['behavioral_metrics'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
      flags: flags,
      sentenceFeedback: sentenceFeedback,
      primaryTrainingMode: _asString(json['primary_training_mode']),
      shortFeedback: _asString(json['short_feedback']),
    );
  }
 */
  List<int> get orderedSentenceIndices {
    final List<int> indices = transcriptSentences.keys.toList()..sort();
    return indices;
  }

  List<MapEntry<int, String>> get orderedSentences {
    return orderedSentenceIndices
        .map(
          (int index) =>
              MapEntry<int, String>(index, transcriptSentences[index] ?? ''),
        )
        .toList(growable: false);
  }


  factory AnalysisResult.fromJson(Map<String, dynamic> jsons) {
    final Map<String, dynamic> analysis =
        Map<String, dynamic>.from(jsons['analysis'] ?? jsons);

    final Map<String, dynamic> payload = Map<String, dynamic>.from(
      analysis['analysis'] is Map
          ? Map<String, dynamic>.from(analysis['analysis'] as Map)
          : analysis,
    );

    final Map<String, dynamic> raw = Map<String, dynamic>.from(
      payload['raw_analysis_json'] ?? payload['rawAnalysisJson'] ?? payload,
    );

    final Map<String, dynamic> starExample = Map<String, dynamic>.from(
      payload['star_example'] ?? raw['star_example'] ?? <String, dynamic>{},
    );

    final Map<int, String> transcriptSentences = <int, String>{};
    final dynamic rawTranscriptSentences =
      raw['transcript_sentences'] ?? payload['transcript_sentences'];
    if (rawTranscriptSentences is List) {
      for (final dynamic item in rawTranscriptSentences) {
        if (item is Map) {
          final Map<String, dynamic> sentenceJson =
              Map<String, dynamic>.from(item);
          final int index = _asInt(
            sentenceJson['idx'] ?? sentenceJson['sentence_index'],
          );
          transcriptSentences[index] = _asString(sentenceJson['sentence']);
        }
      }
    } else if (rawTranscriptSentences is Map) {
      rawTranscriptSentences.forEach((dynamic key, dynamic value) {
        final int? index = int.tryParse('$key');
        if (index != null) {
          transcriptSentences[index] = _asString(value);
        }
      });
    }

    final List<SentenceFeedback> sentenceFeedback = <SentenceFeedback>[];
    final dynamic rawFeedback =
      raw['sentence_feedback'] ?? payload['sentence_feedback'];
    if (rawFeedback is List) {
      for (final dynamic item in rawFeedback) {
        if (item is Map) {
          sentenceFeedback.add(
            SentenceFeedback.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final List<BehavioralQuestions> behavioralQuestions = <BehavioralQuestions>[];
    final dynamic rawQuestions =
      raw['behavioral_questions'] ?? payload['behavioral_questions'];
    if (rawQuestions is List) {
      for (final dynamic item in rawQuestions) {
        if (item is Map) {
          behavioralQuestions.add(
            BehavioralQuestions.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final List<String> flags = <String>[];
    final dynamic rawFlags = raw['flags'] ?? payload['flags'];
    if (rawFlags is List) {
      for (final dynamic flag in rawFlags) {
        final String value = _asString(flag).trim();
        if (value.isNotEmpty) {
          flags.add(value);
        }
      }
    }

    return AnalysisResult(
      overallScore: _asInt(payload['score'] ?? raw['overall_score']),
      transcript: _asString(raw['transcript'] ?? payload['transcript']),
      transcriptSentences: transcriptSentences,
      contentMetrics: ContentMetrics.fromJson(
        Map<String, dynamic>.from(
          raw['content'] ?? payload['content'] ?? <String, dynamic>{},
        ),
      ),
      behavioralMetrics: BehavioralMetrics.fromJson(
        Map<String, dynamic>.from(
          raw['behavioral'] ?? payload['behavioral'] ?? <String, dynamic>{},
        ),
      ),
      flags: flags,
      sentenceFeedback: sentenceFeedback,
      primaryTrainingMode: _asString(
        raw['primary_training_mode'] ?? payload['primary_training_mode'],
      ),
      shortFeedback: _asString(raw['short_feedback'] ?? payload['short_feedback']),
      starExample: StarMetrics.fromJson(starExample),
      behavioralQuestions: behavioralQuestions,
    );
  }


}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _asString(dynamic value) => value?.toString() ?? '';
