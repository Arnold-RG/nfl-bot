import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/engines/body_engine.dart';
import '../../core/models/user_profile.dart';
import '../../core/providers/app_state.dart';
import '../../features/home/presentation/widgets/screens/workout_session_screen.dart';
import '../watch/watch_connect_screen.dart';

/// Opens the active workout session if one exists.
class TrainSessionLauncher extends StatelessWidget {
  const TrainSessionLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<AppState>().currentWorkout;
    if (plan == null) {
      return Theme(
        data: AppTheme.darkTheme,
        child: Scaffold(
          appBar: AppBar(title: const Text('Train')),
          body: const Center(child: Text('Generating workout…')),
        ),
      );
    }
    return WorkoutSessionScreen(workout: plan);
  }
}

/// Gravl-style Train: dark navy + volt green, milestones, calendar, overload.
class TrainScreen extends StatelessWidget {
  const TrainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final day = BodyEngine.snapshot(state);
    final overload = state.overloadPreview;
    final now = DateTime.now();
    final yearGoal = 100;
    final done = state.workoutsCompleted.clamp(0, yearGoal);

    return Theme(
      data: AppTheme.darkTheme,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Scaffold(
            backgroundColor: AppTheme.navy,
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TRAIN',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppTheme.gravlVolt,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Consistent. Results.',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WatchConnectScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.watch_outlined),
                        color: AppTheme.gravlVolt,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DarkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.gravlVolt,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('TODAY',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: AppTheme.gravlVolt,
                                        fontWeight: FontWeight.w800,
                                      )),
                                  Text(day.workoutTitle,
                                      style: theme.textTheme.titleLarge),
                                  Text(
                                    '${day.workoutFocus} · ${day.workoutMinutes} min · Ready ${day.trainingReadiness}%',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              state.generateWorkout(
                                focus: day.workoutFocus
                                    .split('+')
                                    .first
                                    .trim(),
                                minutes: day.workoutMinutes,
                                level: state.trainingExperience,
                              );
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const TrainSessionLauncher(),
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.gravlVolt,
                              foregroundColor: AppTheme.navy,
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: const Text('START WORKOUT'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DarkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.emoji_events_outlined,
                                color: AppTheme.gravlVolt, size: 20),
                            const SizedBox(width: 8),
                            Text('MILESTONES',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppTheme.gravlVolt,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MilestoneTile(
                                title: day.workoutTitle,
                                subtitle: DateFormat('MMM d').format(now),
                                icon: Icons.sports_gymnastics_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MilestoneTile(
                                title: '$done workouts',
                                subtitle: 'This year',
                                icon: Icons.check_circle_outline_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DarkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$yearGoal WORKOUTS IN A YEAR',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$done / $yearGoal · ${((done / yearGoal) * 100).round()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.gravlVolt,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: done / yearGoal,
                            minHeight: 8,
                            color: AppTheme.gravlVolt,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _WorkoutCalendar(
                          completedCount: done,
                          frequency: state.trainingFrequency,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DarkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROGRESSIVE OVERLOAD',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppTheme.gravlVolt,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(overload.exercise,
                            style: theme.textTheme.titleMedium),
                        Text(
                          overload.summary,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(overload.rationale,
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DarkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WATCH WORKOUT',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppTheme.gravlVolt,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _WatchPreview(
                                title: '2:26',
                                subtitle: state.watchConnected
                                    ? '${state.watchHeartRate} BPM'
                                    : '72 BPM (demo)',
                                bar: 0.45,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _WatchPreview(
                                title: overload.summary.split(' · ').first,
                                subtitle: '0/3 Logged',
                                bar: 0.15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Manage workouts from your wrist — pair Apple Watch / Wear OS from Account.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DarkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EQUIPMENT & LEVEL',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final opt in ['home', 'gym'])
                              ChoiceChip(
                                label: Text(opt == 'home' ? 'Home' : 'Gym'),
                                selected: state.equipmentProfile == opt,
                                selectedColor: AppTheme.gravlVolt,
                                labelStyle: TextStyle(
                                  color: state.equipmentProfile == opt
                                      ? AppTheme.navy
                                      : Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (_) =>
                                    state.setEquipmentProfile(opt),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final exp in [
                              'beginner',
                              'intermediate',
                              'advanced'
                            ])
                              FilterChip(
                                label: Text(exp[0].toUpperCase() +
                                    exp.substring(1)),
                                selected: state.trainingExperience == exp,
                                selectedColor: AppTheme.gravlVolt,
                                checkmarkColor: AppTheme.navy,
                                labelStyle: TextStyle(
                                  color: state.trainingExperience == exp
                                      ? AppTheme.navy
                                      : Colors.white70,
                                ),
                                onSelected: (_) =>
                                    state.setTrainingExperience(exp),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final d in [2, 3, 4, 5, 6])
                              ChoiceChip(
                                label: Text('$d× / wk'),
                                selected: state.trainingFrequency == d,
                                selectedColor: AppTheme.gravlVolt,
                                labelStyle: TextStyle(
                                  color: state.trainingFrequency == d
                                      ? AppTheme.navy
                                      : Colors.white70,
                                ),
                                onSelected: (_) =>
                                    state.setTrainingFrequency(d),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DarkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MUSCLE RECOVERY',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 10),
                        for (final m in day.muscles)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 72,
                                  child: Text(m.name,
                                      style: theme.textTheme.bodySmall),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: m.percent / 100,
                                      minHeight: 8,
                                      color: m.percent >= 70
                                          ? AppTheme.gravlVolt
                                          : m.percent >= 45
                                              ? AppTheme.amber
                                              : AppTheme.errorColor,
                                      backgroundColor: Colors.white12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${m.percent}%',
                                    style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final focus in [
                        'Chest',
                        'Back',
                        'Legs',
                        'Full Body',
                        'Core'
                      ])
                        ActionChip(
                          label: Text(focus),
                          backgroundColor: AppTheme.navyCard,
                          labelStyle: const TextStyle(color: Colors.white),
                          side: BorderSide(
                              color: AppTheme.gravlVolt.withValues(alpha: 0.4)),
                          onPressed: () {
                            state.generateWorkout(focus: focus, minutes: 40);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TrainSessionLauncher(),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _pickGoal(context),
                    child: Text(
                      'Goal: ${state.profile.goal.label}',
                      style: const TextStyle(color: AppTheme.gravlVolt),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickGoal(BuildContext context) async {
    final state = context.read<AppState>();
    final chosen = await showModalBottomSheet<FitnessGoal>(
      context: context,
      backgroundColor: AppTheme.navyCard,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final g in FitnessGoal.values)
              ListTile(
                title: Text(g.label, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, g),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await state.saveProfile(state.profile.copyWith(goal: chosen));
  }
}

class _DarkCard extends StatelessWidget {
  final Widget child;
  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _MilestoneTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.navyLift,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.gravlVolt, size: 22),
          const SizedBox(height: 8),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          Text(subtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}

class _WorkoutCalendar extends StatelessWidget {
  final int completedCount;
  final int frequency;

  const _WorkoutCalendar({
    required this.completedCount,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // Deterministic “completed” dots from workout count + frequency.
    final trained = <int>{};
    for (var d = 1; d <= now.day; d++) {
      if ((d + completedCount) % (8 - frequency.clamp(2, 6)) == 0) {
        trained.add(d);
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final w in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              SizedBox(
                width: 28,
                child: Text(
                  w,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (_, i) {
            final day = i + 1;
            final isToday = day == now.day;
            final hit = trained.contains(day);
            return Container(
              decoration: BoxDecoration(
                color: hit
                    ? AppTheme.gravlVolt
                    : (isToday ? Colors.white12 : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
                border: isToday && !hit
                    ? Border.all(color: AppTheme.gravlVolt.withValues(alpha: 0.5))
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hit ? AppTheme.navy : Colors.white70,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WatchPreview extends StatelessWidget {
  final String title;
  final String subtitle;
  final double bar;

  const _WatchPreview({
    required this.title,
    required this.subtitle,
    required this.bar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: bar,
              minHeight: 6,
              color: AppTheme.gravlVolt,
              backgroundColor: Colors.white12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.favorite, color: Colors.redAccent, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
