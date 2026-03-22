import 'package:flutter/material.dart';

import '../data/voice_repository.dart';
import '../model/voice_models.dart';
import '../viewmodel/voice_view_model.dart';

class VoiceAnalysisView extends StatefulWidget {
  const VoiceAnalysisView({super.key, required this.repository});

  final VoiceRepository repository;

  @override
  State<VoiceAnalysisView> createState() => _VoiceAnalysisViewState();
}

class _VoiceAnalysisViewState extends State<VoiceAnalysisView> {
  late final VoiceViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = VoiceViewModel(repository: widget.repository);
    _viewModel.loadScenarios();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (BuildContext context, Widget? child) {
        if (_viewModel.isLoading && _viewModel.scenarios.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_viewModel.error != null && _viewModel.scenarios.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _viewModel.error!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2B3650),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _viewModel.loadScenarios,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        final VoiceScenario? selected = _viewModel.selectedScenario;
        if (selected != null) {
          return _VoiceScenarioDetailView(
            scenario: selected,
            isPlayingAudio: _viewModel.isPlayingAudio,
            responseDraft: _viewModel.responseDraft,
            canSubmit: _viewModel.canSubmitResponse,
            onBack: _viewModel.backToList,
            onToggleAudio: _viewModel.toggleAudioPlayback,
            onResponseChanged: _viewModel.updateResponseDraft,
            onSubmit: () {},
          );
        }

        return _VoiceAnalysisContent(
          scenarios: _viewModel.scenarios,
          onScenarioTap: _viewModel.selectScenario,
        );
      },
    );
  }
}

class _VoiceAnalysisContent extends StatelessWidget {
  const _VoiceAnalysisContent({
    required this.scenarios,
    required this.onScenarioTap,
  });

  final List<VoiceScenario> scenarios;
  final ValueChanged<VoiceScenario> onScenarioTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: <Widget>[
        const Text(
          'Voice Analysis',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: Color(0xFF081A3A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose a scenario to practice your response',
          style: TextStyle(
            fontSize: 22,
            color: Color(0xFF334B73),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        ...scenarios.map((VoiceScenario scenario) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _VoiceScenarioCard(
              scenario: scenario,
              onTap: () => onScenarioTap(scenario),
            ),
          );
        }),
      ],
    );
  }
}

class _VoiceScenarioCard extends StatelessWidget {
  const _VoiceScenarioCard({required this.scenario, required this.onTap});

  final VoiceScenario scenario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _DifficultyStyle style = _difficultyStyle(scenario.difficulty);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x14081A3A),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFEDEAFF),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                scenario.avatarEmoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        scenario.personName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF081A3A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: style.bg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: style.border),
                        ),
                        child: Text(
                          style.label,
                          style: TextStyle(
                            fontSize: 14,
                            color: style.fg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${scenario.context} - ${scenario.topic}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2E446E),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Color(0xFF5D6F90),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${scenario.durationSeconds}s',
                        style: const TextStyle(
                          color: Color(0xFF5D6F90),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.volume_up_outlined,
                        size: 16,
                        color: Color(0xFF5D6F90),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Audio',
                        style: TextStyle(
                          color: Color(0xFF5D6F90),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF8A9CBB),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceScenarioDetailView extends StatefulWidget {
  const _VoiceScenarioDetailView({
    required this.scenario,
    required this.isPlayingAudio,
    required this.responseDraft,
    required this.canSubmit,
    required this.onBack,
    required this.onToggleAudio,
    required this.onResponseChanged,
    required this.onSubmit,
  });

  final VoiceScenario scenario;
  final bool isPlayingAudio;
  final String responseDraft;
  final bool canSubmit;
  final VoidCallback onBack;
  final VoidCallback onToggleAudio;
  final ValueChanged<String> onResponseChanged;
  final VoidCallback onSubmit;

  @override
  State<_VoiceScenarioDetailView> createState() =>
      _VoiceScenarioDetailViewState();
}

class _VoiceScenarioDetailViewState extends State<_VoiceScenarioDetailView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.responseDraft);
  }

  @override
  void didUpdateWidget(covariant _VoiceScenarioDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.responseDraft != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.responseDraft,
        selection: TextSelection.collapsed(offset: widget.responseDraft.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _DifficultyStyle style = _difficultyStyle(widget.scenario.difficulty);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: widget.onBack,
            child: const Text(
              '← Back to List',
              style: TextStyle(
                color: Color(0xFF1F66FF),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Listen & Respond',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Color(0xFF081A3A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Listen carefully and write your response',
            style: TextStyle(
              fontSize: 22,
              color: Color(0xFF334B73),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFA43FF0), Color(0xFF4C43E8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x1E4C43E8),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0x26FFFFFF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.scenario.avatarEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                widget.scenario.personName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: style.bg,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: style.border),
                                ),
                                child: Text(
                                  style.label,
                                  style: TextStyle(
                                    color: style.fg,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.scenario.context} - ${widget.scenario.topic}',
                            style: const TextStyle(
                              color: Color(0xFFE8EEFF),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0x30FFFFFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Container(
                      width: widget.isPlayingAudio ? 88 : 0,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    const Text(
                      '0s',
                      style: TextStyle(color: Color(0xFFE8EEFF)),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.scenario.durationSeconds}s',
                      style: const TextStyle(color: Color(0xFFE8EEFF)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: widget.onToggleAudio,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x26FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          widget.isPlayingAudio
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isPlayingAudio ? 'Pause Audio' : 'Play Audio',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x14081A3A),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Your Response',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF081A3A),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Type how you would respond to this situation. Focus on clarity, empathy, and effectiveness.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF31486F),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  onChanged: widget.onResponseChanged,
                  minLines: 6,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Type your response here...',
                    filled: true,
                    fillColor: const Color(0xFFF0F3F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '💡 Tip: Listen to the audio carefully before responding. Consider the speaker\'s tone and emotion.',
                    style: TextStyle(
                      color: Color(0xFF43557A),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: widget.canSubmit ? widget.onSubmit : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: widget.canSubmit
                          ? const Color(0xFF2D78FF)
                          : const Color(0xFFDCE3EE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.send_outlined,
                          color: widget.canSubmit
                              ? Colors.white
                              : const Color(0xFF8EA2C1),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Submit Response',
                          style: TextStyle(
                            color: widget.canSubmit
                                ? Colors.white
                                : const Color(0xFF8EA2C1),
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyStyle {
  const _DifficultyStyle({
    required this.label,
    required this.bg,
    required this.border,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color border;
  final Color fg;
}

_DifficultyStyle _difficultyStyle(VoiceDifficulty difficulty) {
  switch (difficulty) {
    case VoiceDifficulty.easy:
      return const _DifficultyStyle(
        label: 'Easy',
        bg: Color(0xFFDDF9E7),
        border: Color(0xFF8AE5AE),
        fg: Color(0xFF11874A),
      );
    case VoiceDifficulty.medium:
      return const _DifficultyStyle(
        label: 'Medium',
        bg: Color(0xFFFFF2C7),
        border: Color(0xFFFFD35D),
        fg: Color(0xFF8C5A00),
      );
    case VoiceDifficulty.hard:
      return const _DifficultyStyle(
        label: 'Hard',
        bg: Color(0xFFFFDFDE),
        border: Color(0xFFFF9F98),
        fg: Color(0xFFC63328),
      );
  }
}
