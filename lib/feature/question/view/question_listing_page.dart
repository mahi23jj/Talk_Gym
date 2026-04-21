import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/feature/analysis_results/view/analysis_results_page.dart';
import 'package:talk_gym/feature/question/data/model/question_item.dart';
import 'package:talk_gym/feature/question/view/question_detail_page.dart';
// import 'package:talk_gym/feature/behavioral_training/screens/training_intro_screen.dart';
import 'package:talk_gym/feature/question/viewmodel/question_listing_bloc.dart';

class QuestionListingPage extends StatefulWidget {
  const QuestionListingPage({super.key});

  @override
  State<QuestionListingPage> createState() => _QuestionListingPageState();
}

class _QuestionListingPageState extends State<QuestionListingPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final double triggerOffset =
        _scrollController.position.maxScrollExtent - 220;
    if (_scrollController.position.pixels >= triggerOffset) {
      context.read<QuestionListingBloc>().add(
        const QuestionLoadMoreRequested(),
      );
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      context.read<QuestionListingBloc>().add(QuestionSearchChanged(value));
      _scrollToTop();
    });
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<QuestionListingBloc>().add(
              const QuestionListingRefreshed(),
            );
          },
          child: BlocBuilder<QuestionListingBloc, QuestionListingState>(
            builder: (BuildContext context, QuestionListingState state) {
              final List<String> filters = state.availableFilters;

              if (_searchController.text != state.searchQuery) {
                _searchController.value = _searchController.value.copyWith(
                  text: state.searchQuery,
                  selection: TextSelection.collapsed(
                    offset: state.searchQuery.length,
                  ),
                );
              }

              return CustomScrollView(
                controller: _scrollController,
                slivers: <Widget>[
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    elevation: 0,
                    toolbarHeight: 92,
                    surfaceTintColor: Colors.transparent,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    actions: <Widget>[
                      IconButton(
                        tooltip: 'Open AI Analysis',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AnalysisResultsPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.analytics_outlined),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      title: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Behavioral Questions',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Practice with real interview questions',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _SearchBar(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onClear: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (BuildContext context, int index) {
                            if (index == filters.length) {
                              return Center(
                                child: GestureDetector(
                                  onTap: () {
                                    context.read<QuestionListingBloc>().add(
                                      const QuestionFiltersCleared(),
                                    );
                                    _searchController.clear();
                                    _scrollToTop();
                                  },
                                  child: Semantics(
                                    button: true,
                                    label: 'Clear all filters',
                                    child: Text(
                                      'Clear filters',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.78),
                                          ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            final String filter = filters[index];
                            final bool isActive = state.activeFilter == filter;

                            return Semantics(
                              button: true,
                              label: 'Filter by $filter',
                              selected: isActive,
                              child: ChoiceChip(
                                label: Text(
                                  filter,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isActive
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                selected: isActive,
                                shape: const StadiumBorder(),
                                side: BorderSide.none,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.padded,
                                selectedColor: AppColors.textPrimary,
                                backgroundColor: AppColors.cardBackground,
                                onSelected: (_) {
                                  context.read<QuestionListingBloc>().add(
                                    QuestionFilterChanged(filter),
                                  );
                                  _scrollToTop();
                                },
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemCount: filters.length + 1,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  if (state.status == QuestionListingStatus.loading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: _QuestionSkeletonList(),
                      ),
                    )
                  else if (state.items.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.separated(
                        itemCount:
                            state.items.length + (state.isLoadingMore ? 1 : 0),
                        itemBuilder: (BuildContext context, int index) {
                          if (index >= state.items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }

                          final QuestionItem item = state.items[index];
                          return _AnimatedQuestionCard(
                            index: index,
                            child: _QuestionCard(
                              item: item,
                              currentDay: state.currentDay,
                              onTap: item.dayUnlock <= state.currentDay
                                  ? () {
                                      Navigator.of(context).push(
                                        PageRouteBuilder<void>(
                                          transitionDuration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          reverseTransitionDuration:
                                              const Duration(milliseconds: 240),
                                          pageBuilder:
                                              (
                                                BuildContext context,
                                                Animation<double> animation,
                                                Animation<double>
                                                secondaryAnimation,
                                              ) {
                                                // return const BehavioralTrainingIntroScreen();
                                                return QuestionDetailPage(
                                                  item: item,
                                                );
                                              },
                                          transitionsBuilder:
                                              (
                                                BuildContext context,
                                                Animation<double> animation,
                                                Animation<double>
                                                secondaryAnimation,
                                                Widget child,
                                              ) {
                                                final Animation<Offset>
                                                offsetAnimation =
                                                    Tween<Offset>(
                                                      begin: const Offset(1, 0),
                                                      end: Offset.zero,
                                                    ).animate(
                                                      CurvedAnimation(
                                                        parent: animation,
                                                        curve:
                                                            Curves.easeOutCubic,
                                                      ),
                                                    );

                                                return SlideTransition(
                                                  position: offsetAnimation,
                                                  child: child,
                                                );
                                              },
                                        ),
                                      );
                                    }
                                  : null,
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (BuildContext context, TextEditingValue value, _) {
        return Semantics(
          textField: true,
          label: 'Search questions',
          hint: 'Search questions',
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 1,
            onChanged: onChanged,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              constraints: const BoxConstraints(minHeight: 40),
              hintText: 'Search questions...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: 'Clear search',
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.item,
    required this.currentDay,
    required this.onTap,
  });

  final QuestionItem item;
  final int currentDay;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLocked = item.dayUnlock > currentDay;

    final Widget cardBody = Card(
      margin: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Day ${item.dayUnlock}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.tags.take(3).map((String tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(tag, style: theme.textTheme.bodySmall),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Divider(color: theme.dividerColor, height: 1),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: !isLocked,
      label: isLocked
          ? 'Locked question for day ${item.dayUnlock}: ${item.title}'
          : 'Question: ${item.title}',
      hint: isLocked
          ? 'Unavailable until day ${item.dayUnlock}'
          : 'Open question details',
      child: Stack(
        children: <Widget>[
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isLocked ? 0.7 : 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: cardBody,
            ),
          ),
          if (isLocked)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: const Icon(Icons.lock_outline_rounded, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuestionSkeletonList extends StatefulWidget {
  const _QuestionSkeletonList();

  @override
  State<_QuestionSkeletonList> createState() => _QuestionSkeletonListState();
}

class _QuestionSkeletonListState extends State<_QuestionSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return Column(
          children: List<Widget>.generate(5, (int index) {
            final double shimmer = (0.55 + (0.45 * (_controller.value))).clamp(
              0.55,
              1,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Opacity(
                opacity: shimmer,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: <Widget>[
                      _skeletonLine(width: double.infinity, height: 16),
                      const SizedBox(height: 8),
                      _skeletonLine(width: 240, height: 12),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          _skeletonPill(width: 56),
                          const SizedBox(width: 6),
                          _skeletonPill(width: 66),
                          const SizedBox(width: 6),
                          _skeletonPill(width: 72),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _skeletonLine({required double width, required double height}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _skeletonPill({required double width}) {
    return Container(
      width: width,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.textTertiary),
                  ),
                  child: const Icon(Icons.filter_alt_off_outlined),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('No questions found', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 6),
            Text(
              'Try different filters or search term',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedQuestionCard extends StatelessWidget {
  const _AnimatedQuestionCard({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final int delay = (index * 40).clamp(0, 280);
    final Duration duration = Duration(milliseconds: 280 + delay);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (BuildContext context, double value, Widget? child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
    );
  }
}
