

class ProfileModel {
  final String username;
  final String email;
  final TrialStatus trialStatus;
  final Progress progress;

  const ProfileModel({
    required this.username,
    required this.email,
    required this.trialStatus,
    required this.progress,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      trialStatus: TrialStatus.fromJson(json['trial_status'] ?? {}),
      progress: Progress.fromJson(json['progress'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'trial_status': trialStatus.toJson(),
      'progress': progress.toJson(),
    };
  }

  @override
  List<Object?> get props => [username, email, trialStatus, progress];
}

class TrialStatus  {
  final int interviewsUsed;
  final int interviewsLimit;
  final int remaining;

  const TrialStatus({
    required this.interviewsUsed,
    required this.interviewsLimit,
    required this.remaining,
  });

  factory TrialStatus.fromJson(Map<String, dynamic> json) {
    return TrialStatus(
      interviewsUsed: json['interviews_used'] ?? 0,
      interviewsLimit: json['interviews_limit'] ?? 0,
      remaining: json['remaining'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interviews_used': interviewsUsed,
      'interviews_limit': interviewsLimit,
      'remaining': remaining,
    };
  }

  double get usagePercentage {
    if (interviewsLimit == 0) return 0;
    return (interviewsUsed / interviewsLimit).clamp(0.0, 1.0);
  }

  bool get isLimitReached => remaining <= 0;

  @override
  List<Object?> get props => [interviewsUsed, interviewsLimit, remaining];
}

class Progress{
  final int totalQuestionsAttempted;
  final int completedSessions;
  final double avgImprovement;

  const Progress({
    required this.totalQuestionsAttempted,
    required this.completedSessions,
    required this.avgImprovement,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      totalQuestionsAttempted: json['total_questions_attempted'] ?? 0,
      completedSessions: json['completed_sessions'] ?? 0,
      avgImprovement: (json['avg_improvement'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_questions_attempted': totalQuestionsAttempted,
      'completed_sessions': completedSessions,
      'avg_improvement': avgImprovement,
    };
  }

  @override
  List<Object?> get props => [totalQuestionsAttempted, completedSessions, avgImprovement];
}