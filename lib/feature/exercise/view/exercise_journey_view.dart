// change this page to be clean + modern + animative using App constant
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:talk_gym/core/Appcolor.dart';

import '../data/exercise_repository.dart';
import '../model/journey_models.dart';
import '../viewmodel/exercise_view_model.dart';
import 'package:flutter/services.dart';


// lib/exercise/view/exercise_journey_view.dart




class ExerciseJourneyView extends StatefulWidget {
  const ExerciseJourneyView({super.key, required this.repository});

  final ExerciseRepository repository;

  @override
  State<ExerciseJourneyView> createState() => _ExerciseJourneyViewState();
}

class _ExerciseJourneyViewState extends State<ExerciseJourneyView>
    with TickerProviderStateMixin {
  late final ExerciseViewModel _viewModel;
  late final AnimationController _pageTransitionController;
  late final Animation<double> _pageTransitionAnimation;

  @override
  void initState() {
    super.initState();
    _viewModel = ExerciseViewModel(repository: widget.repository);
    _viewModel.loadJourney();
    
    _pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pageTransitionAnimation = CurvedAnimation(
      parent: _pageTransitionController,
      curve: Curves.easeOutCubic,
    );
    _pageTransitionController.forward();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _pageTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (BuildContext context, Widget? child) {
        if (_viewModel.isLoading && _viewModel.journey == null) {
          return _buildLoadingState();
        }

        if (_viewModel.error != null && _viewModel.journey == null) {
          return _buildErrorState();
        }

        final JourneyData data = _viewModel.journey!;
        final JourneyNode? selected = _viewModel.selectedNode;

        Widget content;
        
        if (selected != null) {
          if (_viewModel.isResultVisible) {
            content = _AnalysisResultsView(
              mode: _viewModel.activeChallengeMode ?? ChallengeMode.concise,
              onRetry: _viewModel.retryQuestionFromResults,
              onBackToJourney: _viewModel.backToJourney,
            );
          } else if (_viewModel.isCoachConversationVisible) {
            content = _AiCoachConversationView(
              lastVoiceSeconds: _viewModel.recordingSeconds,
              recordingSeconds: _viewModel.coachRecordingSeconds,
              isRecording: _viewModel.isCoachRecording,
              onBackToChallenge: _viewModel.backToChallengeActive,
              onRecordTap: _viewModel.toggleCoachRecording,
              onEndChat: _viewModel.openResultsPage,
            );
          } else if (_viewModel.activeChallengeMode != null) {
            content = _ChallengeActiveLevelView(
              node: selected,
              mode: _viewModel.activeChallengeMode!,
              recordingSeconds: _viewModel.recordingSeconds,
              isRecording: _viewModel.isRecording,
              onBackToJourney: _viewModel.backToJourney,
              onBackToChallengeSelection: _viewModel.backToChallengeSelection,
              onRecordTap: _viewModel.toggleRecording,
              onSubmit: _viewModel.openCoachConversation,
            );
          } else if (_viewModel.isChallengeModeSelectionVisible) {
            content = _ChallengeModeSelectionView(
              recordingSeconds: _viewModel.recordingSeconds,
              onBackToLevel: _viewModel.backToLevelDetail,
              onSelectSpeed: _viewModel.selectSpeedChallenge,
              onSelectConcise: _viewModel.selectConciseChallenge,
            );
          } else {
            content = _ExerciseLevelDetailView(
              node: selected,
              recordingSeconds: _viewModel.recordingSeconds,
              isRecording: _viewModel.isRecording,
              canSubmit: _viewModel.canSubmitAnswer,
              onBack: _viewModel.backToJourney,
              onRecordTap: _viewModel.toggleRecording,
              onSubmit: _viewModel.openChallengeModeSelection,
            );
          }
        } else {
          content = _ExerciseJourneyContent(
            data: data,
            onNodeTap: _viewModel.selectNode,
          );
        }

        return FadeTransition(
          opacity: _pageTransitionAnimation,
          child: content,
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your journey...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            _viewModel.error!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _viewModel.loadJourney,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseJourneyContent extends StatefulWidget {
  const _ExerciseJourneyContent({required this.data, required this.onNodeTap});

  final JourneyData data;
  final ValueChanged<JourneyNode> onNodeTap;

  @override
  State<_ExerciseJourneyContent> createState() => _ExerciseJourneyContentState();
}

class _ExerciseJourneyContentState extends State<_ExerciseJourneyContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scrollController;
  late final ScrollController _mainScrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _mainScrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double stageHeight = 860;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        controller: _mainScrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: AnimatedOpacity(
                opacity: _mainScrollController.hasClients &&
                        _mainScrollController.offset > 100
                    ? 1.0
                    : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  widget.data.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE7E1F2),
                      const Color(0xFFD8E9F7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FadeTransition(
                          opacity: _scrollController,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _scrollController,
                              curve: Curves.easeOutCubic,
                            )),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.data.title,
                                  style: const TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF081A3A),
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.data.subtitle,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    color: Color(0xFF2A3D63),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              constraints: const BoxConstraints(minHeight: stageHeight),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              child: SizedBox(
                height: 740,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _AnimatedJourneyPathPainter(
                              nodes: widget.data.nodes,
                              animation: _scrollController,
                            ),
                          ),
                        ),
                        ...widget.data.nodes.asMap().entries.map(
                          (entry) => _AnimatedJourneyNode(
                            node: entry.value,
                            index: entry.key,
                            parentWidth: constraints.maxWidth,
                            onTap: widget.onNodeTap,
                            animation: _scrollController,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedJourneyNode extends StatelessWidget {
  const _AnimatedJourneyNode({
    required this.node,
    required this.index,
    required this.parentWidth,
    required this.onTap,
    required this.animation,
  });

  final JourneyNode node;
  final int index;
  final double parentWidth;
  final ValueChanged<JourneyNode> onTap;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    const double nodeSize = 96;
    final double left = (parentWidth * node.centerX) - (nodeSize / 2);

    return Positioned(
      left: left,
      top: node.top,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Interval(
              index * 0.1,
              0.8 + index * 0.05,
              curve: Curves.easeOutBack,
            ),
          )),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap(node);
            },
            child: MouseRegion(
              cursor: node.state == JourneyNodeState.locked
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
              child: Column(
                children: [
                  _ModernCircleNode(node: node, size: nodeSize),
                  const SizedBox(height: 10),
                  _ModernNodeTag(node: node),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernCircleNode extends StatefulWidget {
  const _ModernCircleNode({required this.node, required this.size});

  final JourneyNode node;
  final double size;

  @override
  State<_ModernCircleNode> createState() => _ModernCircleNodeState();
}

class _ModernCircleNodeState extends State<_ModernCircleNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.node.state == JourneyNodeState.current) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color background;
    Color fg;
    Widget content;

    switch (widget.node.state) {
      case JourneyNodeState.completed:
        background = const Color(0xFF0FD267);
        fg = Colors.white;
        content = const Icon(
          Icons.check_circle_outline,
          size: 36,
          color: Colors.white,
        );
      case JourneyNodeState.current:
        background = const Color(0xFFA19AF3);
        fg = Colors.white;
        content = Text(
          '${widget.node.level}',
          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700),
        );
      case JourneyNodeState.upcoming:
        background = const Color(0xFFC9D3E8);
        fg = Colors.white;
        content = Text(
          '${widget.node.level}',
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
        );
      case JourneyNodeState.locked:
        background = const Color(0xFFB6C4D8);
        fg = const Color(0xFFE8EEF8);
        content = const Icon(Icons.lock_outline_rounded, size: 36);
    }

    final bool isLocked = widget.node.state == JourneyNodeState.locked;
    final bool isCurrent = widget.node.state == JourneyNodeState.current;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              gradient: isCurrent
                  ? RadialGradient(
                      colors: [
                        background,
                        background.withOpacity(0.8),
                      ],
                      radius: 0.8 + _pulseController.value * 0.2,
                    )
                  : null,
              color: !isCurrent ? background : null,
              shape: BoxShape.circle,
              boxShadow: [
                if (_isHovered && !isLocked)
                  BoxShadow(
                    color: background.withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: AnimatedScale(
              scale: _isHovered && !isLocked ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: DefaultTextStyle(
                style: TextStyle(color: fg),
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModernNodeTag extends StatelessWidget {
  const _ModernNodeTag({required this.node});

  final JourneyNode node;

  @override
  Widget build(BuildContext context) {
    final bool isLocked = node.state == JourneyNodeState.locked;
    final bool isCurrent = node.state == JourneyNodeState.current;
    final bool isCompleted = node.state == JourneyNodeState.completed;

    return Transform.translate(
      offset: Offset(node.centerX > 0.5 ? -74 : 74, -54),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        constraints: const BoxConstraints(minWidth: 130),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrent
              ? Colors.white
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF0FD267).withOpacity(0.3)
                : isCurrent
                    ? const Color(0xFFA19AF3)
                    : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              node.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isLocked
                    ? Colors.grey.shade500
                    : isCurrent
                        ? const Color(0xFFA19AF3)
                        : const Color(0xFF081A3A),
              ),
            ),
            if (isLocked)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Complete previous level',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (isCompleted && node.stars > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    node.stars,
                    (index) => const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFFFB74D),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedJourneyPathPainter extends CustomPainter {
  const _AnimatedJourneyPathPainter({
    required this.nodes,
    required this.animation,
  }) : super(repaint: animation);

  final List<JourneyNode> nodes;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.length < 2) return;

    for (int i = 0; i < nodes.length - 1; i++) {
      final startNode = nodes[i];
      final endNode = nodes[i + 1];

      final start = Offset(
        size.width * startNode.centerX,
        startNode.top + 48,
      );
      final end = Offset(size.width * endNode.centerX, endNode.top + 48);

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(start.dx, start.dy + 40, end.dx, end.dy - 40, end.dx, end.dy);

      final isCompleted = startNode.state == JourneyNodeState.completed;
      
      final Paint paint = Paint()
        ..color = isCompleted
            ? const Color(0xFF0FD267).withOpacity(0.5 * animation.value)
            : const Color(0xFFB7C3D4).withOpacity(0.4 * animation.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      canvas.drawPath(_toDashedPath(path), paint);
      
      // Draw animated progress line
      if (isCompleted) {
        final progressPaint = Paint()
          ..color = const Color(0xFF0FD267)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        
        final metrics = path.computeMetrics();
        for (final metric in metrics) {
          final progressPath = metric.extractPath(0, metric.length * animation.value);
          canvas.drawPath(progressPath, progressPaint);
        }
      }
    }
  }

  Path _toDashedPath(Path source) {
    final dashedPath = Path();
    const dashWidth = 8;
    const dashSpace = 6;

    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        dashedPath.addPath(metric.extractPath(distance, next), Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant _AnimatedJourneyPathPainter oldDelegate) {
    return oldDelegate.nodes != nodes || oldDelegate.animation != animation;
  }
}

// class ExerciseJourneyView extends StatefulWidget {
//   const ExerciseJourneyView({super.key, required this.repository});

//   final ExerciseRepository repository;

//   @override
//   State<ExerciseJourneyView> createState() => _ExerciseJourneyViewState();
// }

// class _ExerciseJourneyViewState extends State<ExerciseJourneyView> {
//   late final ExerciseViewModel _viewModel;

//   @override
//   void initState() {
//     super.initState();
//     _viewModel = ExerciseViewModel(repository: widget.repository);
//     _viewModel.loadJourney();
//   }

//   @override
//   void dispose() {
//     _viewModel.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _viewModel,
//       builder: (BuildContext context, Widget? child) {
//         if (_viewModel.isLoading && _viewModel.journey == null) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (_viewModel.error != null && _viewModel.journey == null) {
//           return Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: <Widget>[
//                 Text(
//                   _viewModel.error!,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     color: Color(0xFF2B3650),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 ElevatedButton(
//                   onPressed: _viewModel.loadJourney,
//                   child: const Text('Try Again'),
//                 ),
//               ],
//             ),
//           );
//         }

//         final JourneyData data = _viewModel.journey!;
//         final JourneyNode? selected = _viewModel.selectedNode;

//         if (selected != null) {
//           if (_viewModel.isResultVisible) {
//             return _AnalysisResultsView(
//               mode: _viewModel.activeChallengeMode ?? ChallengeMode.concise,
//               onRetry: _viewModel.retryQuestionFromResults,
//               onBackToJourney: _viewModel.backToJourney,
//             );
//           }

//           if (_viewModel.isCoachConversationVisible) {
//             return _AiCoachConversationView(
//               lastVoiceSeconds: _viewModel.recordingSeconds,
//               recordingSeconds: _viewModel.coachRecordingSeconds,
//               isRecording: _viewModel.isCoachRecording,
//               onBackToChallenge: _viewModel.backToChallengeActive,
//               onRecordTap: _viewModel.toggleCoachRecording,
//               onEndChat: _viewModel.openResultsPage,
//             );
//           }

//           final ChallengeMode? activeMode = _viewModel.activeChallengeMode;
//           if (activeMode != null) {
//             return _ChallengeActiveLevelView(
//               node: selected,
//               mode: activeMode,
//               recordingSeconds: _viewModel.recordingSeconds,
//               isRecording: _viewModel.isRecording,
//               onBackToJourney: _viewModel.backToJourney,
//               onBackToChallengeSelection: _viewModel.backToChallengeSelection,
//               onRecordTap: _viewModel.toggleRecording,
//               onSubmit: _viewModel.openCoachConversation,
//             );
//           }

//           if (_viewModel.isChallengeModeSelectionVisible) {
//             return _ChallengeModeSelectionView(
//               recordingSeconds: _viewModel.recordingSeconds,
//               onBackToLevel: _viewModel.backToLevelDetail,
//               onSelectSpeed: _viewModel.selectSpeedChallenge,
//               onSelectConcise: _viewModel.selectConciseChallenge,
//             );
//           }

//           return _ExerciseLevelDetailView(
//             node: selected,
//             recordingSeconds: _viewModel.recordingSeconds,
//             isRecording: _viewModel.isRecording,
//             canSubmit: _viewModel.canSubmitAnswer,
//             onBack: _viewModel.backToJourney,
//             onRecordTap: _viewModel.toggleRecording,
//             onSubmit: _viewModel.openChallengeModeSelection,
//           );
//         }

//         return _ExerciseJourneyContent(
//           data: data,
//           onNodeTap: _viewModel.selectNode,
//         );
//       },
//     );
//   }
// }

// class _ExerciseJourneyContent extends StatelessWidget {
//   const _ExerciseJourneyContent({required this.data, required this.onNodeTap});

//   final JourneyData data;
//   final ValueChanged<JourneyNode> onNodeTap;

//   @override
//   Widget build(BuildContext context) {
//     const double stageHeight = 860;

//     return SingleChildScrollView(
//       child: Container(
//         constraints: const BoxConstraints(minHeight: stageHeight),
//         padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: <Color>[Color(0xFFE7E1F2), Color(0xFFD8E9F7)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             Text(
//               data.title,
//               style: const TextStyle(
//                 fontSize: 44,
//                 fontWeight: FontWeight.w800,
//                 color: Color(0xFF081A3A),
//                 letterSpacing: -0.4,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               data.subtitle,
//               style: const TextStyle(
//                 fontSize: 22,
//                 color: Color(0xFF2A3D63),
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 30),
//             SizedBox(
//               height: 740,
//               child: LayoutBuilder(
//                 builder: (BuildContext context, BoxConstraints constraints) {
//                   return Stack(
//                     children: <Widget>[
//                       Positioned.fill(
//                         child: CustomPaint(
//                           painter: _JourneyPathPainter(nodes: data.nodes),
//                         ),
//                       ),
//                       ...data.nodes.map(
//                         (JourneyNode node) => _JourneyNodeItem(
//                           node: node,
//                           parentWidth: constraints.maxWidth,
//                           onTap: onNodeTap,
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _JourneyNodeItem extends StatelessWidget {
  const _JourneyNodeItem({
    required this.node,
    required this.parentWidth,
    required this.onTap,
  });

  final JourneyNode node;
  final double parentWidth;
  final ValueChanged<JourneyNode> onTap;

  @override
  Widget build(BuildContext context) {
    const double nodeSize = 96;
    final double left = (parentWidth * node.centerX) - (nodeSize / 2);

    return Positioned(
      left: left,
      top: node.top,
      child: SizedBox(
        width: nodeSize,
        child: Column(
          children: <Widget>[
            _CircleNode(node: node, size: nodeSize, onTap: () => onTap(node)),
            const SizedBox(height: 10),
            _NodeTag(node: node),
          ],
        ),
      ),
    );
  }
}

class _CircleNode extends StatelessWidget {
  const _CircleNode({
    required this.node,
    required this.size,
    required this.onTap,
  });

  final JourneyNode node;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color fg;
    Widget content;

    switch (node.state) {
      case JourneyNodeState.completed:
        background = const Color(0xFF0FD267);
        fg = Colors.white;
        content = const Icon(
          Icons.check_circle_outline,
          size: 36,
          color: Colors.white,
        );
      case JourneyNodeState.current:
        background = const Color(0xFFA19AF3);
        fg = Colors.white;
        content = Text(
          '${node.level}',
          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700),
        );
      case JourneyNodeState.upcoming:
        background = const Color(0xFFC9D3E8);
        fg = Colors.white;
        content = Text(
          '${node.level}',
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
        );
      case JourneyNodeState.locked:
        background = const Color(0xFFB6C4D8);
        fg = const Color(0xFFE8EEF8);
        content = Icon(Icons.lock_outline_rounded, size: 36, color: fg);
    }

    final bool isLocked = node.state == JourneyNodeState.locked;

    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: isLocked ? null : onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x21081A3A),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: TextStyle(color: fg),
              child: content,
            ),
          ),
        ),
        if (node.stars > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('⭐' * node.stars, style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}

class _ExerciseLevelDetailView extends StatelessWidget {
  const _ExerciseLevelDetailView({
    required this.node,
    required this.recordingSeconds,
    required this.isRecording,
    required this.canSubmit,
    required this.onBack,
    required this.onRecordTap,
    required this.onSubmit,
  });

  final JourneyNode node;
  final int recordingSeconds;
  final bool isRecording;
  final bool canSubmit;
  final VoidCallback onBack;
  final VoidCallback onRecordTap;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: onBack,
            child: const Text(
              ' Back to Journey',
              style: TextStyle(
                color: Color(0xFF1F66FF),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Level ${node.level}',
            style: const TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w800,
              color: Color(0xFF081A3A),
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            node.title,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2B4268),
            ),
          ),
          const SizedBox(height: 22),
          _QuestionCard(prompt: node.prompt),
          const SizedBox(height: 26),
          _RecorderCard(
            recordingSeconds: recordingSeconds,
            isRecording: isRecording,
            onRecordTap: onRecordTap,
            buttonText: 'Submit Answer',
            buttonEnabled: canSubmit,
            buttonColor: const Color(0xFF2D78FF),
            onSubmit: canSubmit ? onSubmit : null,
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _ChallengeModeSelectionView extends StatelessWidget {
  const _ChallengeModeSelectionView({
    required this.recordingSeconds,
    required this.onBackToLevel,
    required this.onSelectSpeed,
    required this.onSelectConcise,
  });

  final int recordingSeconds;
  final VoidCallback onBackToLevel;
  final VoidCallback onSelectSpeed;
  final VoidCallback onSelectConcise;

  @override
  Widget build(BuildContext context) {
    final int speedSeconds = (recordingSeconds / 2).ceil().clamp(1, 99);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBackToLevel,
              child: const Text(
                ' Back to Level',
                style: TextStyle(
                  color: Color(0xFF1F66FF),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Icon(Icons.auto_awesome, size: 52, color: Color(0xFFE1A700)),
          const SizedBox(height: 10),
          const Text(
            'Great First Try!',
            style: TextStyle(
              fontSize: 44,
              color: Color(0xFF081A3A),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Now, choose your challenge mode',
            style: TextStyle(fontSize: 23, color: Color(0xFF2B4268)),
          ),
          const SizedBox(height: 28),
          _ModeCard(
            title: 'Speed Challenge',
            subtitle: 'Answer in half the time',
            icon: Icons.schedule_outlined,
            startColor: const Color(0xFFFF7A00),
            endColor: const Color(0xFFFF3B2E),
            infoPrimary: '${speedSeconds}s',
            infoSecondary: 'Original time: ${recordingSeconds}s',
            onTap: onSelectSpeed,
          ),
          const SizedBox(height: 18),
          _ModeCard(
            title: 'Concise Challenge',
            subtitle: 'Answer in 3 sentences',
            icon: Icons.chat_bubble_outline_rounded,
            startColor: const Color(0xFF3F84FF),
            endColor: const Color(0xFF932AE8),
            infoPrimary: '3 Sentences',
            infoSecondary: 'Keep it short and clear',
            onTap: onSelectConcise,
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.startColor,
    required this.endColor,
    required this.infoPrimary,
    required this.infoSecondary,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color startColor;
  final Color endColor;
  final String infoPrimary;
  final String infoSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x21081A3A),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x33FFFFFF),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFFF2F6FF),
                          fontSize: 29,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0x2BFFFFFF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    infoPrimary,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 45,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    infoSecondary,
                    style: const TextStyle(
                      color: Color(0xFFF4F8FF),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeActiveLevelView extends StatelessWidget {
  const _ChallengeActiveLevelView({
    required this.node,
    required this.mode,
    required this.recordingSeconds,
    required this.isRecording,
    required this.onBackToJourney,
    required this.onBackToChallengeSelection,
    required this.onRecordTap,
    required this.onSubmit,
  });

  final JourneyNode node;
  final ChallengeMode mode;
  final int recordingSeconds;
  final bool isRecording;
  final VoidCallback onBackToJourney;
  final VoidCallback onBackToChallengeSelection;
  final VoidCallback onRecordTap;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final String badgeTitle = mode == ChallengeMode.speed
        ? 'Speed Challenge Active'
        : 'Concise Challenge Active';

    final String badgeSubtitle = mode == ChallengeMode.speed
        ? 'Answer in half the time'
        : 'Answer in 3 sentences max';

    final int speedTarget = (recordingSeconds / 2).ceil().clamp(1, 99);
    final String actionText = mode == ChallengeMode.speed
        ? 'Complete in ${speedTarget}s Target'
        : 'Submit & Start Conversation';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: onBackToJourney,
            child: const Text(
              ' Back to Journey',
              style: TextStyle(
                color: Color(0xFF1F66FF),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Level ${node.level}',
            style: const TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w800,
              color: Color(0xFF081A3A),
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            node.title,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2B4268),
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: onBackToChallengeSelection,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF3F84FF), Color(0xFF932AE8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        badgeTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        badgeSubtitle,
                        style: const TextStyle(
                          color: Color(0xFFE9F0FF),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _QuestionCard(prompt: node.prompt),
          const SizedBox(height: 26),
          _RecorderCard(
            recordingSeconds: recordingSeconds,
            isRecording: isRecording,
            onRecordTap: onRecordTap,
            buttonText: actionText,
            buttonEnabled: true,
            buttonColor: const Color(0xFF07C650),
            onSubmit: onSubmit,
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _AiCoachConversationView extends StatelessWidget {
  const _AiCoachConversationView({
    required this.lastVoiceSeconds,
    required this.recordingSeconds,
    required this.isRecording,
    required this.onBackToChallenge,
    required this.onRecordTap,
    required this.onEndChat,
  });

  final int lastVoiceSeconds;
  final int recordingSeconds;
  final bool isRecording;
  final VoidCallback onBackToChallenge;
  final VoidCallback onRecordTap;
  final VoidCallback onEndChat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[Color(0xFF3F84FF), Color(0xFF932AE8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                onTap: onBackToChallenge,
                child: const Text(
                  ' Back to Challenge',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0x33FFFFFF),
                    child: Icon(Icons.work_outline, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'AI Coach',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        "Let's discuss your answer",
                        style: TextStyle(
                          color: Color(0xFFE7EEFF),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFF2F4F8),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D78FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.mic_none_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Voice message (${lastVoiceSeconds}s)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D78FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(width: 14),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA54AF4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.work_outline,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x12081A3A),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Text(
                          "That's a great start! Can you elaborate on what you mean by that? I'd love to hear more details.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF081A3A),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE5EAF2))),
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6FA),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Text(
                                  'Record your response',
                                  style: TextStyle(
                                    color: Color(0xFF1F3A68),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${recordingSeconds}s',
                                  style: const TextStyle(
                                    color: Color(0xFF081A3A),
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: onRecordTap,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D78FF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      isRecording
                                          ? Icons.stop_rounded
                                          : Icons.mic_none_rounded,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isRecording ? 'Stop' : 'Record',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
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
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: onEndChat,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color(0xFFA63FF0),
                                Color(0xFF4253E9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'End Chat & See Results',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnalysisResultsView extends StatelessWidget {
  const _AnalysisResultsView({
    required this.mode,
    required this.onRetry,
    required this.onBackToJourney,
  });

  final ChallengeMode mode;
  final VoidCallback onRetry;
  final VoidCallback onBackToJourney;

  @override
  Widget build(BuildContext context) {
    final String modeLine = mode == ChallengeMode.concise
        ? 'Concise Challenge'
        : 'Speed Challenge';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF08BE5A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: <Widget>[
                Icon(Icons.star_rounded, color: Colors.white, size: 30),
                SizedBox(height: 8),
                Text(
                  'Complete Analysis!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                Text(
                  '94',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ResultCard(
            title: 'Overall AI Summary',
            icon: Icons.auto_awesome,
            iconColor: const Color(0xFF3A75FF),
            child: Text(
              'Excellent performance! Your initial answer was well-structured and clear. Throughout the conversation, you maintained great engagement and responded thoughtfully to follow-up questions. Your pacing was natural and your explanations were easy to follow.',
              style: TextStyle(
                color: Colors.blueGrey.shade800,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const <Widget>[
              Expanded(
                child: _ScoreTile(
                  score: '92',
                  label: 'Clarity',
                  scoreColor: Color(0xFF2866F6),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _ScoreTile(
                  score: '88',
                  label: 'Confidence',
                  scoreColor: Color(0xFF914AF7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const <Widget>[
              Expanded(
                child: _ScoreTile(
                  score: '95',
                  label: 'Pace',
                  scoreColor: Color(0xFF08BE5A),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _ScoreTile(
                  score: '90',
                  label: 'Conversation',
                  scoreColor: Color(0xFFFF6B2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ResultCard(
            title: 'Conversation Highlights',
            icon: Icons.forum_outlined,
            iconColor: const Color(0xFF7A58FF),
            child: const _Bullets(
              items: <String>[
                'Strong opening that set the context well',
                'Good elaboration when asked for more details',
                'Natural conversation flow maintained',
              ],
            ),
          ),
          const SizedBox(height: 10),
          _ResultCard(
            title: 'Strengths',
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF08BE5A),
            child: const _Bullets(
              items: <String>[
                'Clear and logical flow in initial response',
                'Great engagement during conversation',
                'Confident delivery throughout',
                'Thoughtful responses to AI prompts',
              ],
            ),
          ),
          const SizedBox(height: 10),
          _ResultCard(
            title: 'Tips for Next Time',
            icon: Icons.auto_awesome,
            iconColor: const Color(0xFF3A75FF),
            child: const _Bullets(
              items: <String>[
                'Consider adding more specific examples',
                'Pause slightly longer between key points',
                'Could expand on certain details when asked',
              ],
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF3C8AFF), Color(0xFF9C3DF0)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Try This Question Again',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onBackToJourney,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFD7DFEC)),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Back to Journey',
                style: TextStyle(
                  color: Color(0xFF1D3762),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$modeLine • Conversation Completed',
            style: const TextStyle(color: Color(0xFF5D6F90), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14081A3A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF122B54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({
    required this.score,
    required this.label,
    required this.scoreColor,
  });

  final String score;
  final String label;
  final Color scoreColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x10081A3A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Text(
            score,
            style: TextStyle(
              color: scoreColor,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5F7292),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (String item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $item',
                style: const TextStyle(
                  color: Color(0xFF2D4572),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF3F84FF), Color(0xFF932AE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x2A3F84FF),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Your Question',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            prompt,
            style: const TextStyle(
              color: Color(0xFFF2F6FF),
              fontSize: 33,
              height: 1.38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecorderCard extends StatelessWidget {
  const _RecorderCard({
    required this.recordingSeconds,
    required this.isRecording,
    required this.onRecordTap,
    required this.buttonText,
    required this.buttonEnabled,
    required this.buttonColor,
    this.onSubmit,
  });

  final int recordingSeconds;
  final bool isRecording;
  final VoidCallback onRecordTap;
  final String buttonText;
  final bool buttonEnabled;
  final Color buttonColor;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14081A3A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2F6),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Column(
              children: <Widget>[
                const Text(
                  'Recording Time',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF43577A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${recordingSeconds}s',
                  style: const TextStyle(
                    fontSize: 62,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF081A3A),
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onRecordTap,
            child: Container(
              width: 102,
              height: 102,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2D78FF),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x263F84FF),
                    blurRadius: 22,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isRecording ? 'Tap to Stop' : 'Tap to Record',
            style: const TextStyle(
              fontSize: 34,
              color: Color(0xFF193B72),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: buttonEnabled ? onSubmit : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: buttonEnabled ? buttonColor : const Color(0xFFDCE3EE),
                borderRadius: BorderRadius.circular(999),
                boxShadow: buttonEnabled
                    ? const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x2D07C650),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.send_outlined,
                    color: buttonEnabled
                        ? Colors.white
                        : const Color(0xFF8EA2C1),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: 31,
                      color: buttonEnabled
                          ? Colors.white
                          : const Color(0xFF8EA2C1),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeTag extends StatelessWidget {
  const _NodeTag({required this.node});

  final JourneyNode node;

  @override
  Widget build(BuildContext context) {
    final bool isLocked = node.state == JourneyNodeState.locked;
    final bool isCurrent = node.state == JourneyNodeState.current;

    return Transform.translate(
      offset: Offset(node.centerX > 0.5 ? -74 : 74, -54),
      child: Container(
        constraints: const BoxConstraints(minWidth: 130),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFFE7EDF5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1A081A3A),
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Text(
              node.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isCurrent
                    ? const Color(0xFF627085)
                    : const Color(0xFF081A3A),
              ),
            ),
            if (isLocked)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Locked',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F8EA8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _JourneyPathPainter extends CustomPainter {
  const _JourneyPathPainter({required this.nodes});

  final List<JourneyNode> nodes;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.length < 2) {
      return;
    }

    final Paint paint = Paint()
      ..color = const Color(0xFFB7C3D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    for (int i = 0; i < nodes.length - 1; i++) {
      final JourneyNode startNode = nodes[i];
      final JourneyNode endNode = nodes[i + 1];

      final Offset start = Offset(
        size.width * startNode.centerX,
        startNode.top + 48,
      );
      final Offset end = Offset(size.width * endNode.centerX, endNode.top + 48);

      final Path path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(start.dx, start.dy + 40, end.dx, end.dy - 40, end.dx, end.dy);

      canvas.drawPath(_toDashedPath(path), paint);
    }
  }

  Path _toDashedPath(Path source) {
    final Path dashedPath = Path();
    const double dashWidth = 11;
    const double dashSpace = 8;

    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dashWidth;
        dashedPath.addPath(metric.extractPath(distance, next), Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }

    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant _JourneyPathPainter oldDelegate) {
    return oldDelegate.nodes != nodes;
  }
}
