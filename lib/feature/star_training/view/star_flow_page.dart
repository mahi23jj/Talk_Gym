import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/feature/star_training/data/model/star_training_models.dart';
import 'package:talk_gym/feature/star_training/viewmodel/star_training_bloc.dart';

class StarFlowPage extends StatelessWidget {
  const StarFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StarTrainingBloc, StarTrainingState>(
      builder: (BuildContext context, StarTrainingState state) {
        final StarStepContent step = state.activeStep!;

        return SafeArea(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ProgressHeader(
                  steps: state.session!.steps,
                  currentStep: state.currentStep,
                  completedSteps: state.completedSteps,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'STEP ${state.currentStep + 1} OF 4',
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 1,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          Text(
                            step.part.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(step.icon, style: const TextStyle(fontSize: 22)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          step.prompt,
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          step.example,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _VoiceAnswerSection(
                        key: ValueKey<StarPart>(step.part),
                        part: step.part,
                        textMode: state.isTextMode,
                        currentAnswer: state.answerFor(step.part),
                        onTextModeToggle: () =>
                            context.read<StarTrainingBloc>().toggleTextMode(),
                        onTextChanged: (String value) => context
                            .read<StarTrainingBloc>()
                            .setTextAnswer(step.part, value),
                        onAnswerSaved:
                            ({
                              required String path,
                              required int seconds,
                              required List<double> waveform,
                            }) {
                              context.read<StarTrainingBloc>().saveVoiceAnswer(
                                part: step.part,
                                audioPath: path,
                                durationSeconds: seconds,
                                waveform: waveform,
                              );
                            },
                        onClear: () => context
                            .read<StarTrainingBloc>()
                            .clearAnswer(step.part),
                      ),
                      if (state.durationWarning != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            border: Border(
                              left: BorderSide(
                                color: AppColors.textTertiary,
                                width: 3,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            state.durationWarning!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context
                            .read<StarTrainingBloc>()
                            .clearAnswer(step.part),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF222222),
                          side: const BorderSide(color: Color(0xFF222222)),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text('Re-record'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: state.canGoNext
                            ? () {
                                HapticFeedback.selectionClick();
                                context.read<StarTrainingBloc>().nextStep();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF222222),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text('Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.steps,
    required this.currentStep,
    required this.completedSteps,
  });

  final List<StarStepContent> steps;
  final int currentStep;
  final Set<int> completedSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: List<Widget>.generate(steps.length, (int index) {
            final bool active = index <= currentStep;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: index == steps.length - 1 ? 0 : 8,
                ),
                height: 4,
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          children: List<Widget>.generate(steps.length, (int index) {
            final bool active = index == currentStep;
            final bool canTap = completedSteps.contains(index) || active;
            return Expanded(
              child: InkWell(
                onTap: canTap
                    ? () => context.read<StarTrainingBloc>().jumpToStep(index)
                    : null,
                child: Text(
                  steps[index].part.shortLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: active ? AppColors.accent : AppColors.textTertiary,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

enum _RecordUiState { idle, recording, paused, review }

class _VoiceAnswerSection extends StatefulWidget {
  const _VoiceAnswerSection({
    required this.part,
    required this.textMode,
    required this.currentAnswer,
    required this.onTextModeToggle,
    required this.onTextChanged,
    required this.onAnswerSaved,
    required this.onClear,
    super.key,
  });

  final StarPart part;
  final bool textMode;
  final StarAnswer currentAnswer;
  final VoidCallback onTextModeToggle;
  final ValueChanged<String> onTextChanged;
  final void Function({
    required String path,
    required int seconds,
    required List<double> waveform,
  })
  onAnswerSaved;
  final VoidCallback onClear;

  @override
  State<_VoiceAnswerSection> createState() => _VoiceAnswerSectionState();
}

class _VoiceAnswerSectionState extends State<_VoiceAnswerSection> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _textController = TextEditingController();
  final Random _random = Random();

  _RecordUiState _uiState = _RecordUiState.idle;
  Timer? _timer;
  StreamSubscription<Amplitude>? _ampSub;
  String? _recordPath;
  int _seconds = 0;
  bool _permissionDenied = false;
  bool _isPlaying = false;
  double _playProgress = 0;
  List<double> _wave = List<double>.filled(12, 0.2);

  @override
  void initState() {
    super.initState();
    _hydrateFromAnswer();
    _textController.text = widget.currentAnswer.text;
  }

  @override
  void didUpdateWidget(covariant _VoiceAnswerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAnswer != widget.currentAnswer) {
      _hydrateFromAnswer();
      if (_textController.text != widget.currentAnswer.text) {
        _textController.text = widget.currentAnswer.text;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ampSub?.cancel();
    _recorder.dispose();
    _player.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _hydrateFromAnswer() {
    if (!mounted) {
      return;
    }

    setState(() {
      _recordPath = widget.currentAnswer.audioPath;
      _seconds = widget.currentAnswer.durationSeconds ?? 0;
      _wave = widget.currentAnswer.waveform.isEmpty
          ? List<double>.filled(12, 0.2)
          : widget.currentAnswer.waveform;
      _uiState = widget.currentAnswer.hasVoice
          ? _RecordUiState.review
          : _RecordUiState.idle;
    });
  }

  Future<void> _start() async {
    final PermissionStatus status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _permissionDenied = true;
        _uiState = _RecordUiState.idle;
      });
      widget.onTextModeToggle();
      return;
    }

    final Directory dir = await getTemporaryDirectory();
    final String path =
        '${dir.path}/star_${widget.part.name}_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: path,
    );

    HapticFeedback.mediumImpact();
    _ampSub?.cancel();
    _timer?.cancel();

    setState(() {
      _recordPath = path;
      _seconds = 0;
      _uiState = _RecordUiState.recording;
      _wave = List<double>.filled(12, 0.15);
      _permissionDenied = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _uiState != _RecordUiState.recording) {
        return;
      }
      setState(() {
        _seconds += 1;
      });
    });

    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((Amplitude amp) {
          final double normalized = ((amp.current + 45) / 45).clamp(0.0, 1.0);
          if (!mounted || _uiState == _RecordUiState.paused) {
            return;
          }
          setState(() {
            _wave = List<double>.generate(12, (_) {
              return (0.15 + normalized + (_random.nextDouble() * 0.25)).clamp(
                0.1,
                1.0,
              );
            });
          });
        });
  }

  Future<void> _pauseResume() async {
    if (_uiState == _RecordUiState.recording) {
      await _recorder.pause();
      HapticFeedback.selectionClick();
      setState(() => _uiState = _RecordUiState.paused);
      return;
    }

    if (_uiState == _RecordUiState.paused) {
      await _recorder.resume();
      HapticFeedback.selectionClick();
      setState(() => _uiState = _RecordUiState.recording);
    }
  }

  Future<void> _stop() async {
    final String? path = await _recorder.stop();
    _timer?.cancel();
    _ampSub?.cancel();

    if (path == null) {
      return;
    }

    HapticFeedback.heavyImpact();

    setState(() {
      _recordPath = path;
      _uiState = _RecordUiState.review;
      if (_seconds == 0) {
        _seconds = 1;
      }
    });

    widget.onAnswerSaved(path: path, seconds: _seconds, waveform: _wave);
  }

  Future<void> _play() async {
    if (_recordPath == null) {
      return;
    }

    await _player.setFilePath(_recordPath!);
    await _player.play();

    setState(() => _isPlaying = true);

    _player.positionStream.listen((Duration pos) {
      final Duration total = _player.duration ?? const Duration(seconds: 1);
      if (!mounted) {
        return;
      }
      setState(() {
        _playProgress = (pos.inMilliseconds / max(total.inMilliseconds, 1))
            .clamp(0.0, 1.0);
      });
    });

    _player.playerStateStream.listen((PlayerState event) {
      if (!mounted) {
        return;
      }
      if (event.processingState == ProcessingState.completed ||
          !event.playing) {
        setState(() => _isPlaying = false);
      }
    });
  }

  Future<void> _clear() async {
    await _player.stop();
    await _recorder.stop();
    _timer?.cancel();
    _ampSub?.cancel();

    setState(() {
      _uiState = _RecordUiState.idle;
      _seconds = 0;
      _recordPath = null;
      _playProgress = 0;
      _isPlaying = false;
      _wave = List<double>.filled(12, 0.2);
    });

    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: <Widget>[
          if (_permissionDenied)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Enable microphone for voice answers',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: openAppSettings,
                    child: const Text('Open settings'),
                  ),
                ],
              ),
            ),
          if (_uiState == _RecordUiState.idle) _buildIdle(),
          if (_uiState == _RecordUiState.recording ||
              _uiState == _RecordUiState.paused)
            _buildRecording(),
          if (_uiState == _RecordUiState.review) _buildReview(),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onTextModeToggle,
            child: Text(
              widget.textMode
                  ? 'Switch to voice input'
                  : 'Switch to text input',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
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
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIdle() {
    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: _start,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 1.3),
            ),
            child: const Icon(
              Icons.mic_none_rounded,
              color: AppColors.accent,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap to record',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRecording() {
    final bool paused = _uiState == _RecordUiState.paused;

    return Column(
      children: <Widget>[
        GestureDetector(
          onDoubleTap: _pauseResume,
          onTap: paused ? _pauseResume : _stop,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 1.3),
            ),
            child: Center(
              child: paused
                  ? const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.accent,
                    )
                  : Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _WaveBars(levels: _wave),
        const SizedBox(height: 6),
        Text(
          _formatSeconds(_seconds),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(onPressed: _clear, child: const Text('Cancel')),
            const SizedBox(width: 12),
            TextButton(onPressed: _stop, child: const Text('Stop')),
          ],
        ),
      ],
    );
  }

  Widget _buildReview() {
    return Column(
      children: <Widget>[
        _WaveBars(levels: _wave),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFF0F0F0),
              child: IconButton(
                iconSize: 16,
                padding: EdgeInsets.zero,
                onPressed: _play,
                icon: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: AppColors.accent,
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
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                _formatSeconds(_seconds),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.divider,
            thumbColor: AppColors.accent,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: _playProgress,
            onChanged: (double value) => setState(() => _playProgress = value),
          ),
        ),
      ],
    );
  }

  String _formatSeconds(int value) {
    final int m = value ~/ 60;
    final int s = value % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _WaveBars extends StatelessWidget {
  const _WaveBars({required this.levels});

  final List<double> levels;

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
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    );
  }
}
