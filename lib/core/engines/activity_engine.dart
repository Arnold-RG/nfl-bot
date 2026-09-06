// Steps, activity sessions, challenges, and mock leaderboard — deterministic.

enum ActivityType {
  walk,
  run,
  hike,
  cycle,
  swim,
  gym,
  yoga,
  sports,
  other,
}

extension ActivityTypeLabel on ActivityType {
  String get label => switch (this) {
        ActivityType.walk => 'Walk',
        ActivityType.run => 'Run',
        ActivityType.hike => 'Hike',
        ActivityType.cycle => 'Cycle',
        ActivityType.swim => 'Swim',
        ActivityType.gym => 'Gym',
        ActivityType.yoga => 'Yoga',
        ActivityType.sports => 'Sports',
        ActivityType.other => 'Other',
      };

  /// Rough kcal per minute for a mid-weight adult — estimate only.
  double get kcalPerMinute => switch (this) {
        ActivityType.walk => 4.0,
        ActivityType.run => 10.0,
        ActivityType.hike => 6.5,
        ActivityType.cycle => 8.0,
        ActivityType.swim => 9.0,
        ActivityType.gym => 7.0,
        ActivityType.yoga => 3.5,
        ActivityType.sports => 8.5,
        ActivityType.other => 5.0,
      };
}

class ActivitySession {
  final String id;
  final ActivityType type;
  final int minutes;
  final int steps;
  final int caloriesEst;
  final DateTime startedAt;

  const ActivitySession({
    required this.id,
    required this.type,
    required this.minutes,
    required this.steps,
    required this.caloriesEst,
    required this.startedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'minutes': minutes,
        'steps': steps,
        'caloriesEst': caloriesEst,
        'startedAt': startedAt.toIso8601String(),
      };

  factory ActivitySession.fromJson(Map<String, dynamic> json) =>
      ActivitySession(
        id: json['id'] as String,
        type: ActivityType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => ActivityType.other,
        ),
        minutes: json['minutes'] as int? ?? 0,
        steps: json['steps'] as int? ?? 0,
        caloriesEst: json['caloriesEst'] as int? ?? 0,
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

enum ChallengePeriod { daily, weekly, monthly }

class ActivityChallenge {
  final String id;
  final String title;
  final ChallengePeriod period;
  final int stepTarget;
  final int currentSteps;

  const ActivityChallenge({
    required this.id,
    required this.title,
    required this.period,
    required this.stepTarget,
    required this.currentSteps,
  });

  double get progress => (currentSteps / stepTarget).clamp(0.0, 1.0);
  bool get complete => currentSteps >= stepTarget;
  String get label =>
      '${_fmt(currentSteps)} / ${_fmt(stepTarget)} steps';

  static String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return '$n';
  }
}

class LeaderboardEntry {
  final String name;
  final int steps;
  final int rank;
  final bool isYou;

  const LeaderboardEntry({
    required this.name,
    required this.steps,
    required this.rank,
    this.isYou = false,
  });
}

class ActivityEngine {
  static const dailyTarget = 10000;
  static const weeklyTarget = 70000;
  static const monthlyTarget = 300000;

  /// Rest days still count toward the lifestyle streak.
  static int lifestyleStreak({
    required int workoutsCompleted,
    required int daysWithSteps,
    required int restDaysLogged,
  }) {
    final base = 1 + workoutsCompleted.clamp(0, 60);
    final movement = daysWithSteps.clamp(0, 30);
    final rest = restDaysLogged.clamp(0, 14);
    return (base + (movement ~/ 3) + rest).clamp(1, 365);
  }

  static List<ActivityChallenge> challenges({
    required int todaySteps,
    required int weekSteps,
    required int monthSteps,
  }) {
    return [
      ActivityChallenge(
        id: 'daily_10k',
        title: 'Daily 10k',
        period: ChallengePeriod.daily,
        stepTarget: dailyTarget,
        currentSteps: todaySteps,
      ),
      ActivityChallenge(
        id: 'weekly_70k',
        title: 'Weekly 70k',
        period: ChallengePeriod.weekly,
        stepTarget: weeklyTarget,
        currentSteps: weekSteps,
      ),
      ActivityChallenge(
        id: 'monthly_300k',
        title: 'Monthly 300k',
        period: ChallengePeriod.monthly,
        stepTarget: monthlyTarget,
        currentSteps: monthSteps,
      ),
    ];
  }

  static List<LeaderboardEntry> mockLeaderboard({
    required String youName,
    required int youSteps,
  }) {
    final peers = <(String, int)>[
      ('Maya K.', 12480),
      ('Jordan P.', 11210),
      ('Sam R.', 10840),
      (youName, youSteps),
      ('Chris L.', 9200),
      ('Ava M.', 8750),
    ];
    peers.sort((a, b) => b.$2.compareTo(a.$2));
    return [
      for (var i = 0; i < peers.length; i++)
        LeaderboardEntry(
          name: peers[i].$1,
          steps: peers[i].$2,
          rank: i + 1,
          isYou: peers[i].$1 == youName,
        ),
    ];
  }

  static ActivitySession buildSession({
    required ActivityType type,
    required int minutes,
    int steps = 0,
  }) {
    final kcal = (type.kcalPerMinute * minutes).round();
    return ActivitySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      minutes: minutes,
      steps: steps,
      caloriesEst: kcal,
      startedAt: DateTime.now(),
    );
  }

  /// Week / month rollups from sessions + today's pedometer steps.
  static int weekStepsFrom(
    List<ActivitySession> sessions,
    int todaySteps,
  ) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final fromSessions = sessions
        .where((s) => !s.startedAt.isBefore(
              DateTime(weekStart.year, weekStart.month, weekStart.day),
            ))
        .fold<int>(0, (sum, s) => sum + s.steps);
    return fromSessions + todaySteps;
  }

  static int monthStepsFrom(
    List<ActivitySession> sessions,
    int todaySteps,
  ) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final fromSessions = sessions
        .where((s) => !s.startedAt.isBefore(monthStart))
        .fold<int>(0, (sum, s) => sum + s.steps);
    return fromSessions + todaySteps;
  }
}
