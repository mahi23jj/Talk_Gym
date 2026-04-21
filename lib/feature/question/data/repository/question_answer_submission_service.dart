import 'dart:io';

import 'package:http/http.dart' as http;

class QuestionAnswerSubmissionService {
  QuestionAnswerSubmissionService({http.Client? client, Uri? endpoint})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      endpoint = endpoint ?? Uri.parse('https://httpbin.org/post');

  final http.Client _client;
  final bool _ownsClient;
  final Uri endpoint;

  Future<void> submitAnswer({
    required String questionId,
    required String questionTitle,
    required String answerText,
    required int durationSeconds,
    String? voiceFilePath,
  }) async {
    final http.MultipartRequest request =
        http.MultipartRequest('POST', endpoint)
          ..fields['question_id'] = questionId
          ..fields['question_title'] = questionTitle
          ..fields['answer_text'] = answerText
          ..fields['duration_seconds'] = durationSeconds.toString();

    if (voiceFilePath != null && File(voiceFilePath).existsSync()) {
      request.files.add(
        await http.MultipartFile.fromPath('voice_file', voiceFilePath),
      );
      request.fields['has_voice'] = 'true';
    } else {
      request.fields['has_voice'] = 'false';
    }

    final http.StreamedResponse response = await _client.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final String body = await response.stream.bytesToString();
      throw StateError(
        'Failed to submit answer. HTTP ${response.statusCode}: $body',
      );
    }
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
