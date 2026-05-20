import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:talk_gym/feature/profile/data/models/profile_model.dart';
import 'package:talk_gym/feature/profile/data/repositories/profile_repository.dart';
import 'package:talk_gym/feature/profile/presentation/views/achievement_chip.dart';
import 'package:talk_gym/feature/profile/presentation/views/error_view.dart';
import 'package:talk_gym/feature/profile/presentation/views/profile_stats_card.dart';
import 'package:talk_gym/feature/profile/viewmodel/bloc/profile_bloc.dart';
import 'package:talk_gym/feature/profile/viewmodel/bloc/profile_event.dart';
import 'package:talk_gym/feature/profile/viewmodel/bloc/profile_state.dart';
import 'package:talk_gym/feature/profile/viewmodel/bloc/profile_status.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  
  

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(
        repository: ProfileRepository(client: http.Client()),
      )..add(LoadProfile()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.hasError && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ProfileStatus.loading && state.profile == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            );
          }

          if (state.status == ProfileStatus.error && state.profile == null) {
            return ErrorView(
              errorMessage: state.errorMessage ?? 'Failed to load profile',
              onRetry: () {
                context.read<ProfileBloc>().add(const LoadProfile());
              },
            );
          }

          if (state.profile == null) {
            return const Center(child: Text('No profile data available'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProfileBloc>().add(const RefreshProfile());
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context, state),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserInfoCard(context, state.profile!),
                        const SizedBox(height: 20),
                        _buildStatsSection(context, state.profile!),
                        const SizedBox(height: 20),
                        _buildAchievementsSection(context, state.profile!),
                        const SizedBox(height: 24),
                        _buildActionButtons(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ProfileState state) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.person,
              size: 80,
              color: Colors.white,
            ),
          ),
        ),
      ),
      actions: [
        if (state.isRefreshing)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        IconButton(
          onPressed: () {
            context.read<ProfileBloc>().add(const RefreshProfile());
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildUserInfoCard(BuildContext context, ProfileModel profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.username,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // Navigate to edit profile
              },
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, ProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interview Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ProfileStatsCard(
          title: 'Trial Usage',
          icon: Icons.timer_outlined,
          stats: [
            StatItem(
              label: 'Interviews Used',
              value: '${profile.trialStatus.interviewsUsed}',
              subtitle: 'of ${profile.trialStatus.interviewsLimit}',
            ),
            StatItem(
              label: 'Remaining',
              value: '${profile.trialStatus.remaining}',
              subtitle: profile.trialStatus.isLimitReached 
                  ? 'Limit reached' 
                  : 'available',
              isWarning: profile.trialStatus.isLimitReached,
            ),
          ],
          progress: profile.trialStatus.usagePercentage,
        ),
        const SizedBox(height: 16),
        ProfileStatsCard(
          title: 'Learning Progress',
          icon: Icons.trending_up_outlined,
          stats: [
            StatItem(
              label: 'Questions Attempted',
              value: '${profile.progress.totalQuestionsAttempted}',
              subtitle: 'total answers',
            ),
            StatItem(
              label: 'Completed Sessions',
              value: '${profile.progress.completedSessions}',
              subtitle: 'interviews finished',
            ),
            StatItem(
              label: 'Avg. Improvement',
              value: '${profile.progress.avgImprovement}%',
              subtitle: profile.progress.avgImprovement == 0 
                  ? 'Complete more sessions' 
                  : 'from last session',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(BuildContext context, ProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Achievements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AchievementChip(
              icon: Icons.speed,
              label: 'Interview Master',
              achieved: profile.progress.completedSessions >= 5,
            ),
            AchievementChip(
              icon: Icons.trending_up,
              label: 'Improvement Seeker',
              achieved: profile.progress.avgImprovement > 0,
            ),
            AchievementChip(
              icon: Icons.rocket_launch,
              label: 'Quick Starter',
              achieved: profile.trialStatus.interviewsUsed >= 10,
            ),
            AchievementChip(
              icon: Icons.star,
              label: 'Dedicated Learner',
              achieved: profile.progress.totalQuestionsAttempted >= 20,
            ),
            AchievementChip(
              icon: Icons.emoji_events,
              label: 'Session Warrior',
              achieved: profile.progress.completedSessions >= 10,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Navigate to interview history
            },
            icon: const Icon(Icons.history),
            label: const Text('Interview History'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to settings
            },
            icon: const Icon(Icons.settings),
            label: const Text('Settings'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}