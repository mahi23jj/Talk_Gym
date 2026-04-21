import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:record/record.dart';
import 'package:flutter/foundation.dart';

enum VoiceRecorderPhase { idle, recording, paused, review }

class AudioRecorderController extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final Random _random = Random();

  String? _filePath;
  int _seconds = 0;
  Timer? _timer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  VoiceRecorderPhase _phase = VoiceRecorderPhase.idle;
  List<double> _waveLevels = List<double>.filled(12, 0.2);

  String? get filePath => _filePath;
  int get seconds => _seconds;
  bool get isRecording => _phase == VoiceRecorderPhase.recording;
  bool get isPaused => _phase == VoiceRecorderPhase.paused;
  VoiceRecorderPhase get phase => _phase;
  List<double> get waveLevels => _waveLevels;

  Future<void> start(String path) async {
    _timer?.cancel();
    await _amplitudeSubscription?.cancel();

    _filePath = path;
    _seconds = 0;
    _phase = VoiceRecorderPhase.recording;
    _waveLevels = List<double>.filled(12, 0.2);
    notifyListeners();

    await _recorder.start(const RecordConfig(), path: path);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_phase == VoiceRecorderPhase.recording) {
        _seconds += 1;
        notifyListeners();
      }
    });

    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((Amplitude amplitude) {
          if (_phase == VoiceRecorderPhase.paused) {
            return;
          }

          final double normalized = ((amplitude.current + 45) / 45).clamp(
            0.0,
            1.0,
          );

          _waveLevels = List<double>.generate(12, (_) {
            return (0.15 + normalized + (_random.nextDouble() * 0.18)).clamp(
              0.1,
              1.0,
            );
          });
          notifyListeners();
        });
  }

  Future<void> pause() async {
    if (_phase != VoiceRecorderPhase.recording) {
      return;
    }

    await _recorder.pause();
    _phase = VoiceRecorderPhase.paused;
    notifyListeners();
  }

  Future<void> resume() async {
    if (_phase != VoiceRecorderPhase.paused) {
      return;
    }

    await _recorder.resume();
    _phase = VoiceRecorderPhase.recording;
    notifyListeners();
  }

  Future<String?> stop() async {
    _timer?.cancel();
    await _amplitudeSubscription?.cancel();

    final String? stoppedPath = await _recorder.stop();
    _filePath = stoppedPath ?? _filePath;
    _phase = _filePath == null
        ? VoiceRecorderPhase.idle
        : VoiceRecorderPhase.review;
    if (_seconds == 0 && _filePath != null) {
      _seconds = 1;
    }
    notifyListeners();

    return _filePath;
  }

  Future<void> cancel() async {
    _timer?.cancel();
    await _amplitudeSubscription?.cancel();

    final String? path = _filePath;
    await _recorder.stop();

    if (path != null && File(path).existsSync()) {
      await File(path).delete();
    }

    _filePath = null;
    _phase = VoiceRecorderPhase.idle;
    _seconds = 0;
    _waveLevels = List<double>.filled(12, 0.2);
    notifyListeners();
  }

  void hydrateFromSaved({
    required String? path,
    required int seconds,
    required List<double> waveform,
  }) {
    _filePath = path;
    _seconds = seconds;
    _waveLevels = waveform.isEmpty
        ? List<double>.filled(12, 0.2)
        : List<double>.from(waveform);
    _phase = path == null ? VoiceRecorderPhase.idle : VoiceRecorderPhase.review;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSubscription?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
