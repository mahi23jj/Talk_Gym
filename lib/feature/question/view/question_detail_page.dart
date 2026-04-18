import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talk_gym/feature/analysis_results/view/analysis_results_page.dart';
import 'package:talk_gym/feature/question/data/model/question_item.dart';

const Color _kBackground = Color(0xFFFFFFFF);
const Color _kSurface = Color(0xFFF8F9FA);
const Color _kSurfaceAlt = Color(0xFFF5F5F5);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kPrimaryText = Color(0xFF111111);
const Color _kSecondaryText = Color(0xFF555555);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kInteractive = Color(0xFF222222);
const Color _kInteractiveSoft = Color(0xFF444444);
const Color _kDivider = Color(0xFFE5E5E5);
const Color _kWaveActive = Color(0xFF333333);
const Color _kWaveInactive = Color(0xFFD0D0D0);

enum _RecordingState { idle, recording, paused, review }

class QuestionDetailPage extends StatefulWidget {
  const QuestionDetailPage({required this.item, super.key});

  final QuestionItem item;

  @override
  State<QuestionDetailPage> createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends State<QuestionDetailPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final Random _random = Random();

  bool _isLoading = true;
  bool _isTipExpanded = false;
  bool _isHistoryExpanded = false;
  bool _useTextInput = false;
  bool _micPermissionAsked = false;
  bool _micPermissionGranted = false;
  bool _permissionDenied = false;
  bool _showTrashZone = false;
  bool _compareAnswers = false;
  bool _isSubmitting = false;
  bool _showSuccessCheck = false;

  _RecordingState _recordingState = _RecordingState.idle;
  Timer? _waveTimer;
  int _recordingSeconds = 0;
  int _waveTick = 0;
  double _dragDistance = 0;
  double _playProgress = 0.36;
  double _ambientNoise = 0.2;
  List<double> _waveLevels = List<double>.filled(12, 0.25);

  final List<_PastAnswer> _pastAnswers = <_PastAnswer>[
    const _PastAnswer(dateLabel: 'Apr 12', durationLabel: '0:39'),
    const _PastAnswer(dateLabel: 'Apr 10', durationLabel: '0:45'),
  ];

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _waveTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _onMicPressed() async {
    if (_recordingState == _RecordingState.recording) {
      _stopRecording();
      return;
    }

    if (!_micPermissionGranted) {
      await _requestMicPermission();
      if (!_micPermissionGranted) {
        return;
      }
    }

    _startRecording();
  }

  Future<void> _requestMicPermission() async {
    _micPermissionAsked = true;
    final bool? allowed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _kBackground,
          title: const Text(
            'Microphone Permission',
            style: TextStyle(color: _kPrimaryText, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Talk Gym needs microphone access to record your answer.',
            style: TextStyle(color: _kSecondaryText),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Deny',
                style: TextStyle(color: _kInteractiveSoft),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Allow',
                style: TextStyle(color: _kInteractive),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _micPermissionGranted = allowed == true;
      _permissionDenied = allowed != true;
      if (_permissionDenied) {
        _useTextInput = true;
      }
    });
  }

  void _startRecording() {
    HapticFeedback.mediumImpact();
    _waveTimer?.cancel();
    setState(() {
      _recordingState = _RecordingState.recording;
      _recordingSeconds = 0;
      _waveTick = 0;
      _showTrashZone = false;
      _dragDistance = 0;
      _playProgress = 0;
    });

    _waveTimer = Timer.periodic(const Duration(milliseconds: 140), (
      Timer timer,
    ) {
      if (!mounted) {
        return;
      }

      _waveTick += 1;
      final bool shouldCountSecond = _waveTick % 7 == 0;

      setState(() {
        _waveLevels = List<double>.generate(12, (_) {
          if (_recordingState == _RecordingState.paused) {
            return 0.18;
          }
          return 0.2 + (_random.nextDouble() * 0.8);
        });

        _ambientNoise = 0.2 + (_random.nextDouble() * 0.7);

        if (shouldCountSecond && _recordingState == _RecordingState.recording) {
          _recordingSeconds += 1;
        }
      });
    });
  }

  void _pauseOrResumeRecording() {
    if (_recordingState != _RecordingState.recording &&
        _recordingState != _RecordingState.paused) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _recordingState = _recordingState == _RecordingState.recording
          ? _RecordingState.paused
          : _RecordingState.recording;
    });
  }

  void _stopRecording() {
    HapticFeedback.heavyImpact();
    _waveTimer?.cancel();
    setState(() {
      _recordingState = _RecordingState.review;
      _showTrashZone = false;
      _dragDistance = 0;
      if (_recordingSeconds == 0) {
        _recordingSeconds = 45;
      }
      _playProgress = 0.35;
    });
  }

  void _cancelRecording() {
    _waveTimer?.cancel();
    setState(() {
      _recordingState = _RecordingState.idle;
      _recordingSeconds = 0;
      _showTrashZone = false;
      _dragDistance = 0;
      _waveLevels = List<double>.filled(12, 0.25);
    });
  }

  void _resetToIdle() {
    setState(() {
      _recordingState = _RecordingState.idle;
      _recordingSeconds = 0;
      _playProgress = 0;
      _showTrashZone = false;
      _dragDistance = 0;
    });
  }

  Future<void> _submitAnswer() async {
    final bool hasVoice = _recordingState == _RecordingState.review;
    final bool hasText = _textController.text.trim().isNotEmpty;

    if (!hasVoice && !hasText) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a recording or type your answer first.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _showSuccessCheck = true;
    });

    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 3000));

    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: AnalysisResultsPage(
              // key: const Key('analysis_results_page'),
              // analysis: _mockAnalysisResult,
            ),
          );
        },
      ),
    );
  }

  String get _formattedTimer {
    final int minutes = _recordingSeconds ~/ 60;
    final int seconds = _recordingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _kBackground,
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: Column(
              children: <Widget>[
                _buildTopBar(context),
                Expanded(
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.only(
                      bottom: keyboardInset > 0 ? 84 : 0,
                    ),
                    child: _isLoading
                        ? _buildSkeleton()
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                _buildQuestionCard(),
                                const SizedBox(height: 16),
                                _buildCoachingTip(),
                                const SizedBox(height: 16),
                                _buildRecordingSection(),
                                const SizedBox(height: 16),
                                _buildPastAnswersSection(),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (_showSuccessCheck)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showSuccessCheck ? 1 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.08),
                    child: Center(
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 240),
                        scale: _showSuccessCheck ? 1 : 0.6,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: _kInteractive,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                button: true,
                label: 'Submit answer',
                child: SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kInteractive,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit Answer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _resetToIdle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kInteractive,
                    side: const BorderSide(color: _kInteractive, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Re-record',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kDivider)),
      ),
      child: Row(
        children: <Widget>[
          Semantics(
            button: true,
            label: 'Back',
            child: IconButton(
              icon: const Icon(
                Icons.chevron_left_rounded,
                size: 28,
                color: _kPrimaryText,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const Expanded(
            child: Text(
              'Answer Question',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _kPrimaryText,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: _kPrimaryText),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.item.title,
            style: const TextStyle(
              fontSize: 20,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: _kPrimaryText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.item.tags.take(3).map((String tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(fontSize: 12, color: _kWaveActive),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Day ${widget.item.dayUnlock}',
              style: const TextStyle(fontSize: 12, color: _kSecondaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachingTip() {
    return GestureDetector(
      onTap: () => setState(() => _isTipExpanded = !_isTipExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Coaching Tip',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kSecondaryText,
                    ),
                  ),
                ),
                Icon(
                  _isTipExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: _kInteractiveSoft,
                ),
              ],
            ),
            if (_isTipExpanded) ...<Widget>[
              const SizedBox(height: 8),
              const Text(
                'Use STAR method: Situation, Task, Action, Result',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Voice Answer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kPrimaryText,
            ),
          ),
          const SizedBox(height: 12),
          if (_permissionDenied)
            _buildPermissionError()
          else if (_recordingState == _RecordingState.idle)
            _buildIdleState()
          else if (_recordingState == _RecordingState.recording ||
              _recordingState == _RecordingState.paused)
            _buildRecordingActiveState()
          else
            _buildReviewState(),
          const SizedBox(height: 10),
          if (_useTextInput) _buildTextAnswerInput(),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => setState(() => _useTextInput = !_useTextInput),
              child: Text(
                _useTextInput ? 'Use voice input' : 'Switch to text',
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
            ),
          ),
          if (_micPermissionAsked)
            const Text(
              'First use prompts microphone permission. If denied, text input remains available.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _kTertiaryText),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kBackground,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Microphone access denied',
            style: TextStyle(color: _kPrimaryText, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enable microphone permission to record, or type your answer below.',
            style: TextStyle(color: _kSecondaryText, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _requestMicPermission,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kInteractive),
                foregroundColor: _kInteractive,
              ),
              child: const Text('Request permission'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleState() {
    return Column(
      children: <Widget>[
        Semantics(
          button: true,
          label: 'Record answer',
          child: GestureDetector(
            onTap: _onMicPressed,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                shape: BoxShape.circle,
                border: Border.all(color: _kInteractive, width: 1.5),
              ),
              child: const Icon(
                Icons.mic_none_rounded,
                size: 32,
                color: _kInteractive,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Tap to record',
          style: TextStyle(fontSize: 14, color: _kSecondaryText),
        ),
        const SizedBox(height: 4),
        const Text(
          'Practice answering naturally',
          style: TextStyle(fontSize: 12, color: _kTertiaryText),
        ),
      ],
    );
  }

  Widget _buildRecordingActiveState() {
    final bool isPaused = _recordingState == _RecordingState.paused;

    return Column(
      children: <Widget>[
        if (_showTrashZone)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: _kInteractive,
                ),
                SizedBox(width: 6),
                Text(
                  'Release to cancel',
                  style: TextStyle(color: _kSecondaryText),
                ),
              ],
            ),
          ),
        GestureDetector(
          onTap: _onMicPressed,
          onDoubleTap: _pauseOrResumeRecording,
          onVerticalDragUpdate: (DragUpdateDetails details) {
            if (details.delta.dy <= 0) {
              return;
            }

            setState(() {
              _dragDistance += details.delta.dy;
              _showTrashZone = _dragDistance > 34;
            });
          },
          onVerticalDragEnd: (_) {
            final bool cancel = _dragDistance > 86;
            if (cancel) {
              _cancelRecording();
              return;
            }
            setState(() {
              _dragDistance = 0;
              _showTrashZone = false;
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1, end: isPaused ? 1 : 1.08),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                builder: (BuildContext context, double scale, Widget? child) {
                  return Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kInteractive.withValues(
                        alpha: isPaused ? 0 : 0.3,
                      ),
                    ),
                    transform: Matrix4.identity()..scale(scale),
                  );
                },
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  shape: BoxShape.circle,
                  border: Border.all(color: _kInteractive, width: 1.5),
                ),
                child: Center(
                  child: isPaused
                      ? const Icon(
                          Icons.pause_rounded,
                          color: _kInteractive,
                          size: 32,
                        )
                      : Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _kInteractive,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildWaveform(width: 200, height: 48),
        const SizedBox(height: 8),
        Text(
          _formattedTimer,
          style: const TextStyle(
            fontSize: 16,
            color: _kInteractive,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isPaused ? 'Paused' : 'Recording...',
          style: const TextStyle(fontSize: 12, color: _kSecondaryText),
        ),
        const SizedBox(height: 8),
        _buildNoiseIndicator(),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
              onPressed: _cancelRecording,
              child: const Text(
                'Cancel',
                style: TextStyle(color: _kInteractiveSoft),
              ),
            ),
            const SizedBox(width: 18),
            Semantics(
              button: true,
              label: 'Stop recording',
              child: TextButton(
                onPressed: _stopRecording,
                child: const Text(
                  'Stop',
                  style: TextStyle(color: _kInteractive),
                ),
              ),
            ),
          ],
        ),
        const Text(
          'Double tap to pause or resume',
          style: TextStyle(fontSize: 12, color: _kTertiaryText),
        ),
      ],
    );
  }

  Widget _buildReviewState() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildWaveform(width: 120, height: 32),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _kBackground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _kBorder),
              ),
              child: Text(
                '${_recordingSeconds ~/ 60}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: _kInteractive,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F0F0),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  size: 18,
                  color: _kInteractive,
                ),
                onPressed: () {
                  setState(() {
                    _playProgress = (_playProgress + 0.15).clamp(0.0, 1.0);
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F0F0),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: _kInteractive,
                ),
                onPressed: _resetToIdle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _kWaveActive,
            inactiveTrackColor: const Color(0xFFE0E0E0),
            thumbColor: _kInteractive,
            overlayColor: _kInteractive.withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: _playProgress,
            onChanged: (double value) => setState(() => _playProgress = value),
          ),
        ),
        const Text(
          'Saved',
          style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildTextAnswerInput() {
    final int count = _textController.text.length;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _textController,
            minLines: 4,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: _kPrimaryText),
            decoration: InputDecoration(
              hintText: 'Type your answer...',
              hintStyle: const TextStyle(color: _kTertiaryText),
              filled: true,
              fillColor: _kSurfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count characters',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, color: _kTertiaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildNoiseIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text(
          'Ambient noise',
          style: TextStyle(fontSize: 12, color: _kSecondaryText),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: LinearProgressIndicator(
            value: _ambientNoise,
            minHeight: 6,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: _kWaveInactive,
            color: _kWaveActive,
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform({required double width, required double height}) {
    return SizedBox(
      width: width,
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List<Widget>.generate(12, (int index) {
          final double level = _waveLevels[index];
          final bool isActive =
              _recordingState == _RecordingState.recording ||
              _recordingState == _RecordingState.paused;
          final double barHeight = isActive
              ? (4 + (20 * level)).clamp(4, 24)
              : 6 + ((index % 4) * 2);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: width <= 120 ? 4 : 6,
            height: barHeight,
            decoration: BoxDecoration(
              color: isActive ? _kWaveActive : _kWaveInactive,
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPastAnswersSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () =>
                setState(() => _isHistoryExpanded = !_isHistoryExpanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Previous attempts (${_pastAnswers.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kInteractive,
                      ),
                    ),
                  ),
                  Icon(
                    _isHistoryExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _kInteractiveSoft,
                  ),
                ],
              ),
            ),
          ),
          if (_isHistoryExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Compare answers',
                          style: TextStyle(
                            fontSize: 12,
                            color: _kSecondaryText,
                          ),
                        ),
                      ),
                      Switch(
                        value: _compareAnswers,
                        onChanged: (bool value) =>
                            setState(() => _compareAnswers = value),
                        thumbColor: MaterialStateProperty.resolveWith<Color>((
                          Set<MaterialState> states,
                        ) {
                          if (states.contains(MaterialState.selected)) {
                            return _kWaveActive;
                          }
                          return _kWaveInactive;
                        }),
                        trackColor: MaterialStateProperty.resolveWith<Color>((
                          Set<MaterialState> states,
                        ) {
                          if (states.contains(MaterialState.selected)) {
                            return _kWaveInactive;
                          }
                          return const Color(0xFFE3E3E3);
                        }),
                      ),
                    ],
                  ),
                  if (_pastAnswers.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: _kBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kBorder),
                      ),
                      child: const Column(
                        children: <Widget>[
                          Icon(
                            Icons.mic_none_rounded,
                            color: _kTertiaryText,
                            size: 26,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No previous answers yet',
                            style: TextStyle(
                              fontSize: 13,
                              color: _kSecondaryText,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Your first recording will appear here',
                            style: TextStyle(
                              fontSize: 12,
                              color: _kTertiaryText,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: _pastAnswers
                          .map(
                            (_PastAnswer answer) => _buildPastAnswerRow(answer),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPastAnswerRow(_PastAnswer answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.play_arrow_rounded, color: _kInteractive, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  answer.dateLabel,
                  style: const TextStyle(fontSize: 12, color: _kPrimaryText),
                ),
                const SizedBox(height: 2),
                Text(
                  answer.durationLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kSecondaryText,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 84,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List<Widget>.generate(
                8,
                (int index) => Container(
                  width: 4,
                  height: 8 + ((index % 3) * 3),
                  decoration: BoxDecoration(
                    color: _kWaveInactive,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    Widget block({required double height, double radius = 12, double? width}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        block(height: 180, radius: 16),
        const SizedBox(height: 16),
        block(height: 62),
        const SizedBox(height: 16),
        block(height: 260, radius: 16),
        const SizedBox(height: 16),
        block(height: 80, radius: 16),
      ],
    );
  }
}

class _PastAnswer {
  const _PastAnswer({required this.dateLabel, required this.durationLabel});

  final String dateLabel;
  final String durationLabel;
}
