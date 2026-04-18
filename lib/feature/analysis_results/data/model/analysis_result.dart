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

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'overall_score': overallScore,
      'transcript': transcript,
      'transcript_sentences': transcriptSentences.map(
        (int key, String value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      ),
      'content_metrics': contentMetrics.toJson(),
      'behavioral_metrics': behavioralMetrics.toJson(),
      'flags': flags,
      'sentence_feedback': sentenceFeedback
          .map((SentenceFeedback feedback) => feedback.toJson())
          .toList(),
      'primary_training_mode': primaryTrainingMode,
      'short_feedback': shortFeedback,
    };
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
