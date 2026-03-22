// lib/exercise/view/rope_journey_view.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui' as ui;

class RopeJourneyView extends StatefulWidget {
  const RopeJourneyView({super.key});

  @override
  State<RopeJourneyView> createState() => _RopeJourneyViewState();
}

class _RopeJourneyViewState extends State<RopeJourneyView>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  final List<RopeNode> _nodes = [];
  double _scrollOffset = 0;

  // Node positions (vertical positions in pixels)
  final List<double> _nodePositions = [
    100,
    250,
    400,
    550,
    700,
    850,
    1000,
    1150,
    1300,
    1450,
  ];

  final List<String> _nodeNumbers = [
    '5',
    'FULL OF LIFE',
    '9',
    '8',
    '7',
    '6',
    '5',
    '4',
    '3',
    '2',
  ];

  final List<bool> _isCompleted = [
    true,
    true,
    true,
    true,
    false,
    false,
    false,
    false,
    false,
    false,
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _scrollController.addListener(_onScroll);
    _initializeNodes();
  }

  void _initializeNodes() {
    for (int i = 0; i < _nodePositions.length; i++) {
      _nodes.add(
        RopeNode(
          position: _nodePositions[i],
          number: _nodeNumbers[i],
          isCompleted: _isCompleted[i],
          index: i,
        ),
      );
    }
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerWidth = screenWidth * 0.10; // Minimized center width
    final sideWidth = (screenWidth - centerWidth) / 2;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Left Side - Communication Animations
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: sideWidth,
            child: _LeftCommunicationSide(
              scrollOffset: _scrollOffset,
              animationController: _animationController,
            ),
          ),

          // Right Side - Communication Animations
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: sideWidth,
            child: _RightCommunicationSide(
              scrollOffset: _scrollOffset,
              animationController: _animationController,
            ),
          ),

          // Center Scrollable Content (Minimized)
          Center(
            child: Container(
              width: centerWidth,
              constraints: const BoxConstraints(maxWidth: 100),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFFF9F5FF).withOpacity(0.8),
                    const Color(0xFFFFF4EA).withOpacity(0.7),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Stack(
                        children: [
                          ...List.generate(18, (index) {
                            return _FloatingParticle(
                              left: index.isEven ? 8 + (index * 7) % 120 : null,
                              right: index.isOdd ? 8 + (index * 7) % 120 : null,
                              top:
                                  (_scrollOffset * 0.22 + index * 65) %
                                  (_nodePositions.last + 220),
                              size: 2 + (index % 4),
                              color: index.isEven
                                  ? const Color(0xFF9B59B6)
                                  : const Color(0xFFE67E22),
                              delay: index * 0.12,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Custom App Bar
                      /*           SliverAppBar(
                    expandedHeight: 100,
                    floating: true,
                    pinned: true,
                    centerTitle: true,
                    backgroundColor: const Color(0xFF6B4E8E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    toolbarHeight: 60,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'COMMUNICATION JOURNEY',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B4E8E),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      titlePadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ), */

                      // Rope Journey Content
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: _nodePositions.last + 200,
                          child: Stack(
                            children: [
                              // Rope Path
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: RopePainter(
                                    nodePositions: _nodePositions,
                                    scrollOffset: _scrollOffset,
                                    animationValue: _animationController.value,
                                    completedNodes: _isCompleted,
                                  ),
                                ),
                              ),

                              // Nodes
                              ..._nodes.map(
                                (node) => _RopeNodeWidget(
                                  node: node,
                                  scrollOffset: _scrollOffset,
                                  animationController: _animationController,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
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

class _LeftCommunicationSide extends StatelessWidget {
  final double scrollOffset;
  final AnimationController animationController;

  const _LeftCommunicationSide({
    required this.scrollOffset,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFF9F5FF).withOpacity(0.8),
            const Color(0xFFFFF4EA).withOpacity(0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Lottie Animation - Speaking/Waveform
          /*   Positioned(
            top: 100 + (scrollOffset * 0.2),
            left: 20,
            right: 20,
            child: Lottie.network(
              'https://assets10.lottiefiles.com/packages/lf20_pwfxm3mc.json',
              controller: animationController,
              height: 150,
              width: 150,
              fit: BoxFit.contain,
            ),
          ),
          
          // Lottie Animation - Microphone
          Positioned(
            top: 350 + (scrollOffset * 0.15),
            left: 30,
            right: 30,
            child: Lottie.network(
              'https://assets2.lottiefiles.com/packages/lf20_5y7p3hvu.json',
              controller: animationController,
              height: 120,
              width: 120,
              fit: BoxFit.contain,
            ),
          ),
          
          // Lottie Animation - Conversation Bubbles
          Positioned(
            top: 600 + (scrollOffset * 0.1),
            left: 15,
            right: 15,
            child: Lottie.network(
              'https://assets5.lottiefiles.com/packages/lf20_sy0nnoqj.json',
              controller: animationController,
              height: 140,
              width: 140,
              fit: BoxFit.contain,
            ),
          ),
           */
          // Decorative floating particles
          ...List.generate(15, (index) {
            return _FloatingParticle(
              left: 10 + (index * 8) % 80,
              top: (scrollOffset * 0.3 + index * 45) % 800,
              size: 3 + (index % 3),
              color: const Color(0xFF9B59B6),
              delay: index * 0.2,
            );
          }),
        ],
      ),
    );
  }
}

class _RightCommunicationSide extends StatelessWidget {
  final double scrollOffset;
  final AnimationController animationController;

  const _RightCommunicationSide({
    required this.scrollOffset,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            const Color(0xFFF9F5FF).withOpacity(0.8),
            const Color(0xFFFFF4EA).withOpacity(0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Lottie Animation - Listening/Ears
          // Positioned(
          //   top: 150 + (scrollOffset * 0.18),
          //   right: 20,
          //   child: Lottie.network(
          //     'https://assets3.lottiefiles.com/packages/lf20_ibmz7dua.json',
          //     controller: animationController,
          //     height: 140,
          //     width: 140,
          //     fit: BoxFit.contain,
          //   ),
          // ),

          // // Lottie Animation - Voice Recording
          // Positioned(
          //   top: 400 + (scrollOffset * 0.12),
          //   right: 25,
          //   child: Lottie.network(
          //     'https://assets1.lottiefiles.com/packages/lf20_ke0zrzry.json',
          //     controller: animationController,
          //     height: 130,
          //     width: 130,
          //     fit: BoxFit.contain,
          //   ),
          // ),

          // // Lottie Animation - Thinking/Processing
          // Positioned(
          //   top: 650 + (scrollOffset * 0.08),
          //   right: 20,
          //   child: Lottie.network(
          //     'https://assets4.lottiefiles.com/packages/lf20_jk2pjfia.json',
          //     controller: animationController,
          //     height: 150,
          //     width: 150,
          //     fit: BoxFit.contain,
          //   ),
          // ),

          // Decorative floating particles
          ...List.generate(15, (index) {
            return _FloatingParticle(
              left: null,
              right: 10 + (index * 8) % 80,
              top: (scrollOffset * 0.25 + index * 52) % 800,
              size: 3 + (index % 3),
              color: const Color(0xFFE67E22),
              delay: index * 0.15,
            );
          }),
        ],
      ),
    );
  }
}

class _FloatingParticle extends StatefulWidget {
  final double? left;
  final double? right;
  final double top;
  final double size;
  final Color color;
  final double delay;

  const _FloatingParticle({
    this.left,
    this.right,
    required this.top,
    required this.size,
    required this.color,
    required this.delay,
  });

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.left,
      right: widget.right,
      top: widget.top,
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RopeNodeWidget extends StatelessWidget {
  final RopeNode node;
  final double scrollOffset;
  final AnimationController animationController;

  const _RopeNodeWidget({
    required this.node,
    required this.scrollOffset,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final double screenPosition = node.position - scrollOffset;
    final bool isVisible =
        screenPosition > -100 &&
        screenPosition < MediaQuery.of(context).size.height + 100;

    if (!isVisible) return const SizedBox.shrink();

    final double scale = 1.0 + (animationController.value * 0.15);
    final double opacity = 1.0 - (animationController.value * 0.2);

    return Positioned(
      left: 0,
      right: 0,
      top: node.position - scrollOffset - 40,
      child: Center(
        child: AnimatedBuilder(
          animation: animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // Add your tap logic here
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: node.isCompleted
                          ? const LinearGradient(
                              colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                Colors.grey.shade300,
                                Colors.grey.shade400,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: node.isCompleted
                              ? const Color(0xFF9B59B6).withOpacity(0.4)
                              : Colors.grey.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Center(
                      child: node.number.length > 2
                          ? Text(
                              node.number,
                              style: TextStyle(
                                fontSize: node.number == 'FULL OF LIFE'
                                    ? 11
                                    : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: node.number == 'FULL OF LIFE'
                                    ? 0.5
                                    : 0,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : Text(
                              node.number,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class RopeNode {
  final double position;
  final String number;
  final bool isCompleted;
  final int index;

  RopeNode({
    required this.position,
    required this.number,
    required this.isCompleted,
    required this.index,
  });
}

class RopePainter extends CustomPainter {
  final List<double> nodePositions;
  final double scrollOffset;
  final double animationValue;
  final List<bool> completedNodes;

  RopePainter({
    required this.nodePositions,
    required this.scrollOffset,
    required this.animationValue,
    required this.completedNodes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint ropePaint = Paint()
      ..color = const Color(0xFFD4B8A4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final Paint highlightPaint = Paint()
      ..color = const Color(0xFFE8D2BC)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Path mainRope = Path();
    final Path highlightRope = Path();

    final double centerX = size.width / 2;

    for (int i = 0; i < nodePositions.length - 1; i++) {
      final double y1 = nodePositions[i] - scrollOffset + 35;
      final double y2 = nodePositions[i + 1] - scrollOffset + 35;

      if (y1 < -50 && y2 < -50) continue;
      if (y1 > size.height + 50 && y2 > size.height + 50) continue;

      final double startY = y1.clamp(-50, size.height + 50);
      final double endY = y2.clamp(-50, size.height + 50);

      final bool isCompleted = completedNodes[i];

      // Create rope path with wave effect
      final Path segment = Path();
      segment.moveTo(centerX, startY);

      // Add wave effect based on scroll
      final double waveOffset = sin(animationValue * pi * 2) * 2;

      for (double t = 0; t <= 1; t += 0.05) {
        final double y = startY + (endY - startY) * t;
        final double x =
            centerX +
            sin(y * 0.02 + animationValue * 4) * 3 +
            waveOffset * sin(y * 0.03);
        segment.lineTo(x, y);
      }

      if (isCompleted) {
        // Draw completed rope with gradient
        final Paint completedPaint = Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF9B59B6), Color(0xFFE67E22)],
          ).createShader(Rect.fromLTWH(centerX - 8, startY, 16, endY - startY))
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;
        canvas.drawPath(segment, completedPaint);
      } else {
        canvas.drawPath(segment, ropePaint);
        canvas.drawPath(segment, highlightPaint);
      }

      // Add rope texture (dots)
      final Paint dotPaint = Paint()..color = const Color(0xFFB88D6E);
      for (double t = 0; t <= 1; t += 0.1) {
        final double y = startY + (endY - startY) * t;
        final double x = centerX + sin(y * 0.02 + animationValue * 4) * 3;
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RopePainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.completedNodes != completedNodes;
  }
}
