import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:talk_gym/core/appcolor.dart';

enum _SimulationStage {
  countdown,
  idle,
  recording,
  review,
  submitted,
}

class FinalInterviewSimulationScreen extends StatefulWidget {
  const FinalInterviewSimulationScreen({
    required this.questionText,
    required this.preparedAnswer,
    super.key,
  });

  final String questionText;
  final String preparedAnswer;

  @override
  State<FinalInterviewSimulationScreen> createState() =>
      _FinalInterviewSimulationScreenState();
}

class _FinalInterviewSimulationScreenState
    extends State<FinalInterviewSimulationScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();

  _SimulationStage _stage = _SimulationStage.countdown;
  Timer? _countdownTimer;
  Timer? _recordingTimer;
  int _countdown = 3;
  int _recordingSeconds = 0;
  String? _audioPath;
  bool _isPlaying = false;
  List<double> _wave = List<double>.filled(20, 0.18);

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _player.playerStateStream.listen((PlayerState state) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlaying = state.playing;
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdown = 3;
    _stage = _SimulationStage.countdown;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        return;
      }

      if (_countdown == 1) {
        timer.cancel();
        setState(() {
          _countdown = 0;
          _stage = _SimulationStage.idle;
        });
        return;
      }

      setState(() {
        _countdown -= 1;
      });
    });
  }

  Future<bool> _ensurePermission() async {
    final PermissionStatus status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    final bool granted = await _ensurePermission();
    if (!granted) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required for simulation.')),
      );
      return;
    }

    final Directory dir = await getTemporaryDirectory();
    final String path = '${dir.path}/simulation_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: path);
    HapticFeedback.mediumImpact();

    _recordingTimer?.cancel();
    setState(() {
      _audioPath = null;
      _recordingSeconds = 0;
      _stage = _SimulationStage.recording;
      _wave = List<double>.filled(20, 0.18);
    });

    _recordingTimer = Timer.periodic(const Duration(milliseconds: 220), (Timer timer) {
      if (!mounted) {
        return;
      }

      final bool shouldIncrementSecond = timer.tick % 5 == 0;
      setState(() {
        _wave = List<double>.generate(20, (_) => 0.12 + _random.nextDouble() * 0.88);
        if (shouldIncrementSecond) {
          _recordingSeconds += 1;
        }
      });

      if (_recordingSeconds >= 120) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    final String? path = await _recorder.stop();

    setState(() {
      _audioPath = path;
      _stage = _SimulationStage.review;
      _wave = List<double>.filled(20, 0.26);
    });
    HapticFeedback.heavyImpact();
  }

  Future<void> _togglePlayback() async {
    if (_audioPath == null || !File(_audioPath!).existsSync()) {
      return;
    }

    if (_isPlaying) {
      await _player.pause();
      return;
    }

    await _player.setFilePath(_audioPath!);
    await _player.play();
  }

  String get _timerLabel {
    final int m = _recordingSeconds ~/ 60;
    final int s = _recordingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Final Interview Simulation')),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Final Interview Simulation - Question: ${widget.questionText}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.preparedAnswer,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: _buildStage(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case _SimulationStage.countdown:
        return Center(
          key: const ValueKey<String>('countdown'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$_countdown',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You will deliver your answer aloud. The interviewer is listening.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      case _SimulationStage.idle:
        return Center(
          key: const ValueKey<String>('idle'),
          child: SizedBox(
            height: 52,
            width: 220,
            child: ElevatedButton.icon(
              onPressed: _startRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF222222),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Start Recording'),
            ),
          ),
        );
      case _SimulationStage.recording:
        return Column(
          key: const ValueKey<String>('recording'),
          children: <Widget>[
            const SizedBox(height: 12),
            const Text(
              'Recording in progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Timer: $_timerLabel / 02:00',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            _Waveform(values: _wave),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _stopRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF222222),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Stop Recording'),
              ),
            ),
          ],
        );
      case _SimulationStage.review:
        return Column(
          key: const ValueKey<String>('review'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 6),
            const Text(
              'Playback & Review',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _Waveform(values: _wave),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _togglePlayback,
                    icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: Text(_isPlaying ? 'Pause' : 'Play'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _startRecording,
                    child: const Text('Re-record'),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _stage = _SimulationStage.submitted;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF222222),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Submit'),
              ),
            ),
          ],
        );
      case _SimulationStage.submitted:
        return Center(
          key: const ValueKey<String>('submitted'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.check_circle_rounded, size: 60, color: Color(0xFF2E7D32)),
              const SizedBox(height: 12),
              const Text(
                'Great job! Your answer has been saved.',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Practice makes perfect. Try another question.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF222222),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to Training'),
              ),
            ],
          ),
        );
    }
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values
            .map(
              (double level) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    height: 10 + (86 * level),
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
