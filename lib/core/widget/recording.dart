import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:talk_gym/core/voice_recording.dart';

typedef VoiceSavedCallback =
    void Function(String path, int durationSeconds, List<double> waveform);

class VoiceRecorderWidget extends StatefulWidget {
  const VoiceRecorderWidget({
    super.key,
    required this.filePrefix,
    required this.onFinished,
    this.onCleared,
    this.onStateChanged,
    this.showTextToggle = false,
    this.textMode = false,
    this.initialText = '',
    this.onTextChanged,
    this.onTextModeToggle,
    this.initialPath,
    this.initialDuration = 0,
    this.initialWaveform = const <double>[],
  });

  final String filePrefix;
  final VoiceSavedCallback onFinished;
  final VoidCallback? onCleared;
  final ValueChanged<VoiceRecorderPhase>? onStateChanged;
  final bool showTextToggle;
  final bool textMode;
  final String initialText;
  final ValueChanged<String>? onTextChanged;
  final VoidCallback? onTextModeToggle;
  final String? initialPath;
  final int initialDuration;
  final List<double> initialWaveform;

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  final AudioRecorderController _controller = AudioRecorderController();
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _textController = TextEditingController();

  bool _permissionDenied = false;
  bool _isPlaying = false;
  double _playProgress = 0;

  Future<void> _start() async {
    final PermissionStatus status = await Permission.microphone.request();
    if (!mounted) {
      return;
    }

    if (!status.isGranted) {
      setState(() {
        _permissionDenied = true;
      });
      return;
    }

    final Directory dir = await getTemporaryDirectory();
    final String path =
        '${dir.path}/${widget.filePrefix}_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _player.stop();
    HapticFeedback.mediumImpact();
    await _controller.start(path);
    setState(() {});
    widget.onStateChanged?.call(_controller.phase);
  }

  Future<void> _pauseOrResume() async {
    if (_controller.phase == VoiceRecorderPhase.recording) {
      await _controller.pause();
      HapticFeedback.selectionClick();
    } else if (_controller.phase == VoiceRecorderPhase.paused) {
      await _controller.resume();
      HapticFeedback.selectionClick();
    }

    setState(() {});
    widget.onStateChanged?.call(_controller.phase);
  }

  Future<void> _stop() async {
    final String? path = await _controller.stop();
    if (path != null) {
      widget.onFinished(path, _controller.seconds, _controller.waveLevels);
    }

    HapticFeedback.heavyImpact();
    setState(() {});
    widget.onStateChanged?.call(_controller.phase);
  }

  Future<void> _clear() async {
    await _player.stop();
    await _controller.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _playProgress = 0;
      _isPlaying = false;
      _permissionDenied = false;
    });

    widget.onCleared?.call();
    widget.onStateChanged?.call(_controller.phase);
  }

  Future<void> _togglePlayback() async {
    final String? path = _controller.filePath;
    if (path == null || !File(path).existsSync()) {
      return;
    }

    if (_isPlaying) {
      await _player.pause();
      return;
    }

    await _player.setFilePath(path);
    await _player.play();
  }

  Future<void> _seekTo(double value) async {
    final Duration? total = _player.duration;
    if (total == null || total.inMilliseconds <= 0) {
      return;
    }

    final Duration to = Duration(
      milliseconds: (total.inMilliseconds * value).round(),
    );

    await _player.seek(to);
    if (!mounted) {
      return;
    }

    setState(() {
      _playProgress = value.clamp(0.0, 1.0);
    });
  }

  String _formatDuration(int value) {
    final int minutes = value ~/ 60;
    final int seconds = value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _controller.hydrateFromSaved(
      path: widget.initialPath,
      seconds: widget.initialDuration,
      waveform: widget.initialWaveform,
    );
    _textController.text = widget.initialText;

    _player.playerStateStream.listen((PlayerState state) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPlaying = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _playProgress = 1;
        }
      });
    });

    _player.positionStream.listen((Duration position) {
      final Duration? duration = _player.duration;
      if (!mounted || duration == null || duration.inMilliseconds <= 0) {
        return;
      }

      setState(() {
        _playProgress = (position.inMilliseconds / duration.inMilliseconds)
            .clamp(0.0, 1.0);
      });
    });
  }

  @override
  void didUpdateWidget(covariant VoiceRecorderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialPath != widget.initialPath ||
        oldWidget.initialDuration != widget.initialDuration ||
        oldWidget.initialWaveform != widget.initialWaveform) {
      _controller.hydrateFromSaved(
        path: widget.initialPath,
        seconds: widget.initialDuration,
        waveform: widget.initialWaveform,
      );
    }

    if (oldWidget.initialText != widget.initialText &&
        _textController.text != widget.initialText) {
      _textController.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _player.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_permissionDenied)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDDDDD)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Microphone permission is required to record voice answers.',
                  style: TextStyle(fontSize: 13),
                ),
                TextButton(
                  onPressed: openAppSettings,
                  child: const Text('Open settings'),
                ),
              ],
            ),
          ),
        if (_controller.phase == VoiceRecorderPhase.idle)
          _buildIdle()
        else if (_controller.phase == VoiceRecorderPhase.recording ||
            _controller.phase == VoiceRecorderPhase.paused)
          _buildRecording()
        else
          _buildReview(),
        if (widget.showTextToggle)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: widget.onTextModeToggle,
              child: Text(
                widget.textMode
                    ? 'Switch to voice input'
                    : 'Switch to text input',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        if (widget.textMode)
          TextField(
            controller: _textController,
            minLines: 4,
            maxLines: 4,
            onChanged: widget.onTextChanged,
            decoration: InputDecoration(
              hintText: 'Type your answer...',
              filled: true,
              fillColor: const Color(0xFFF6F6F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIdle() {
    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: _start,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF222222), width: 1.2),
            ),
            child: const Icon(
              Icons.mic_none_rounded,
              size: 30,
              color: Color(0xFF222222),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap to record',
          style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildRecording() {
    final bool paused = _controller.phase == VoiceRecorderPhase.paused;

    return Column(
      children: <Widget>[
        const SizedBox(height: 6),
        _WaveBars(levels: _controller.waveLevels, active: true),
        const SizedBox(height: 8),
        Text(
          _formatDuration(_controller.seconds),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            OutlinedButton(onPressed: _clear, child: const Text('Cancel')),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: _pauseOrResume,
              child: Text(paused ? 'Resume' : 'Pause'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _stop, child: const Text('Stop')),
          ],
        ),
      ],
    );
  }

  Widget _buildReview() {
    final String? path = _controller.filePath;
    final bool canPlay = path != null && File(path).existsSync();

    return Column(
      children: <Widget>[
        _WaveBars(levels: _controller.waveLevels, active: false),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFF0F0F0),
              child: IconButton(
                iconSize: 16,
                padding: EdgeInsets.zero,
                onPressed: canPlay ? _togglePlayback : null,
                icon: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: const Color(0xFF222222),
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFF0F0F0),
              child: IconButton(
                iconSize: 16,
                padding: EdgeInsets.zero,
                onPressed: _clear,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFF222222),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xFFDDDDDD)),
              ),
              child: Text(
                _formatDuration(_controller.seconds),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF222222),
            inactiveTrackColor: const Color(0xFFDDDDDD),
            thumbColor: const Color(0xFF222222),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: _playProgress,
            onChanged: canPlay ? _seekTo : null,
          ),
        ),
      ],
    );
  }
}

class _WaveBars extends StatelessWidget {
  const _WaveBars({required this.levels, required this.active});

  final List<double> levels;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List<Widget>.generate(12, (int index) {
          final double normalized = index < levels.length ? levels[index] : 0.2;
          final double h = (4 + (20 * normalized)).clamp(4, 24);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 6,
            height: h,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF222222) : const Color(0xFF777777),
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    );
  }
}
