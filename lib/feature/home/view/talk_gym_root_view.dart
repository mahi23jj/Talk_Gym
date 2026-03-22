import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talk_gym/core/Appcolor.dart';
import 'package:talk_gym/core/Theme/theme_provider.dart';
import 'package:talk_gym/feature/exercise/view/Rope.dart';

import '../../exercise/data/mock_exercise_repository.dart';
import '../../exercise/view/exercise_journey_view.dart';
import '../../voice/data/mock_voice_repository.dart';
import '../../voice/view/voice_analysis_view.dart';

import '../data/home_repository.dart';
import '../model/home_models.dart';
import '../viewmodel/home_view_model.dart';

class TalkGymRootView extends StatefulWidget {
  const TalkGymRootView({super.key, required this.repository});

  final HomeRepository repository;

  @override
  State<TalkGymRootView> createState() => _TalkGymRootViewState();
}

class _TalkGymRootViewState extends State<TalkGymRootView>
    with SingleTickerProviderStateMixin {
  late final HomeViewModel _viewModel;
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(repository: widget.repository);
    _viewModel.loadDashboard();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (BuildContext context, Widget? child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          color: themeProvider.isDarkMode
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: FadeTransition(
              opacity: _fadeController,
              child: SafeArea(child: _buildBody()),
            ),
            bottomNavigationBar: _AnimatedBottomNav(
              currentIndex: _viewModel.currentNavIndex,
              onTap: _viewModel.setNavIndex,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading && _viewModel.dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.error != null && _viewModel.dashboard == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              _viewModel.error!,
              style: const TextStyle(fontSize: 16, color: Color(0xFF2B3650)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _viewModel.loadDashboard,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    final HomeDashboardData data = _viewModel.dashboard!;

    final List<Widget> screens = <Widget>[
      _HomeDashboardContent(data: data),
      ExerciseJourneyView(repository: MockExerciseRepository()),
      VoiceAnalysisView(repository: MockVoiceRepository()),
      RopeJourneyView(),
      // const _TabPlaceholder(title: 'Upload'),
      const _TabPlaceholder(title: 'Stats'),
    ];

    return IndexedStack(index: _viewModel.currentNavIndex, children: screens);
  }
}

class _AnimatedBottomNav extends StatelessWidget {
  const _AnimatedBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color:
                (isDark ? AppColors.darkCardShadow : AppColors.lightCardShadow)
                    .withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        indicatorColor: isDark
            ? AppColors.darkPrimary.withOpacity(0.2)
            : AppColors.lightPrimary.withOpacity(0.12),
        height: 72,
        backgroundColor: Colors.transparent,
        elevation: 0,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            selectedIcon: Icon(Icons.track_changes),
            label: 'Exercise',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none_rounded),
            selectedIcon: Icon(Icons.mic_rounded),
            label: 'Voice',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_file_outlined),
            selectedIcon: Icon(Icons.upload_file_rounded),
            label: 'Upload',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}

class _HomeDashboardContent extends StatelessWidget {
  const _HomeDashboardContent({required this.data});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Welcome back! 👋',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Color(0xFF081A3A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to level up your communication?',
            style: TextStyle(
              fontSize: 20,
              color: Colors.blueGrey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (BuildContext context, int index) {
                return _StatCard(data: data.stats[index]);
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: data.stats.length,
            ),
          ),
          const SizedBox(height: 24),
          _DailyChallengeCard(challenge: data.challenge),
          const SizedBox(height: 24),
          _AchievementsCard(achievements: data.achievements),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final StatCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(data.startColorHex), Color(data.endColorHex)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(data.endColorHex).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(_iconFromName(data.icon), size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                data.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            data.unit,
            style: const TextStyle(
              color: Color(0xFFE8EEFF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.challenge});

  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x13081A3A),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8D4BF6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Daily Challenge',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '✨ + ${challenge.xpReward} XP',
                style: const TextStyle(
                  color: Color(0xFFFF9800),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            challenge.title,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Color(0xFF081A3A),
              height: 1.2,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            challenge.description,
            style: const TextStyle(
              fontSize: 24,
              color: Color(0xFF3B4A65),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              const Icon(
                Icons.timer_outlined,
                size: 16,
                color: Color(0xFF7A869D),
              ),
              const SizedBox(width: 6),
              Text(
                '${challenge.durationMinutes} min',
                style: const TextStyle(
                  color: Color(0xFF52617E),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D78FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                ),
                onPressed: () {},
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Start Challenge',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementsCard extends StatelessWidget {
  const _AchievementsCard({required this.achievements});

  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12081A3A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Your Achievements',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF081A3A),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (BuildContext context, int index) {
                final Achievement item = achievements[index];
                return _AchievementItem(achievement: item);
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: achievements.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  const _AchievementItem({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = achievement.isLocked
        ? const Color(0xFFD4DCEC)
        : const Color(0xFF9FC1FF);

    final Color textColor = achievement.isLocked
        ? const Color(0xFF9EA9BF)
        : const Color(0xFF1D3F7A);

    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: achievement.isLocked
            ? const Color(0xFFF4F7FC)
            : const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: <Widget>[
          Text(achievement.emoji, style: const TextStyle(fontSize: 28)),
          const Spacer(),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      indicatorColor: const Color(0xFFDCE9FF),
      height: 72,
      backgroundColor: Colors.white,
      destinations: const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.track_changes_outlined),
          selectedIcon: Icon(Icons.track_changes),
          label: 'Exercise',
        ),
        NavigationDestination(
          icon: Icon(Icons.mic_none_rounded),
          selectedIcon: Icon(Icons.mic_rounded),
          label: 'Voice',
        ),
        NavigationDestination(
          icon: Icon(Icons.upload_file_outlined),
          selectedIcon: Icon(Icons.upload_file_rounded),
          label: 'Upload',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'Stats',
        ),
      ],
    );
  }
}

class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title screen (MVVM-ready)',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1D3F7A),
        ),
      ),
    );
  }
}

IconData _iconFromName(String name) {
  switch (name) {
    case 'local_fire_department':
      return Icons.local_fire_department;
    case 'auto_awesome':
      return Icons.auto_awesome;
    case 'emoji_events':
      return Icons.emoji_events;
    default:
      return Icons.star;
  }
}
