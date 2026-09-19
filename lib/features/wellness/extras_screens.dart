import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/providers/app_state.dart';
import '../shared/nf_design.dart';

/// Daily readiness from sleep, hydration, steps — no fake baselines.
class ReadinessScreen extends StatelessWidget {
  const ReadinessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final score = state.readinessScore;
    final label = state.readinessLabel;
    final pad = NfLayout.pagePad(context);

    return Scaffold(
      backgroundColor: AppTheme.labBg,
      appBar: AppBar(title: const Text('Readiness')),
      body: NfAmbientBackdrop(
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, 12, pad, 40),
          children: [
            NfGlassCard(
              child: Column(
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value: score / 100,
                            strokeWidth: 12,
                            backgroundColor: AppTheme.labBorder,
                            color: AppTheme.bronze,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$score',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(label,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Built from today’s sleep, water, and steps — empty inputs lower the score honestly.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Factor(
              title: 'Sleep',
              detail: state.hasSleepLog
                  ? '${state.sleepHours}h · ${state.sleepQuality}%'
                  : 'Not logged',
              weight: state.hasSleepLog ? state.sleepQuality / 100 : 0,
            ),
            _Factor(
              title: 'Hydration',
              detail:
                  '${state.hydrationLiters.toStringAsFixed(1)} / ${state.hydrationGoal.toStringAsFixed(1)} L',
              weight: (state.hydrationLiters / state.hydrationGoal)
                  .clamp(0.0, 1.0),
            ),
            _Factor(
              title: 'Movement',
              detail: '${state.steps} / ${state.stepGoal} steps',
              weight: state.stepProgress,
            ),
          ],
        ),
      ),
    );
  }
}

class _Factor extends StatelessWidget {
  final String title;
  final String detail;
  final double weight;

  const _Factor({
    required this.title,
    required this.detail,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NfGlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                Text('${(weight * 100).round()}%',
                    style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(detail, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: weight.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppTheme.labBorder,
                color: AppTheme.bronze,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick mood check-in for Bot context.
class MoodCheckSheet {
  static Future<void> show(BuildContext context) async {
    final moods = [
      ('Great', Icons.sentiment_very_satisfied_rounded, 5),
      ('Good', Icons.sentiment_satisfied_rounded, 4),
      ('Okay', Icons.sentiment_neutral_rounded, 3),
      ('Low', Icons.sentiment_dissatisfied_rounded, 2),
      ('Rough', Icons.sentiment_very_dissatisfied_rounded, 1),
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.labCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How do you feel?',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('Bot uses this for tone — not diagnosis.',
                    style: Theme.of(ctx).textTheme.bodySmall),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final m in moods)
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ctx.read<AppState>().logMood(m.$1, m.$3);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 96,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.labBorder),
                            color: AppTheme.labLift,
                          ),
                          child: Column(
                            children: [
                              Icon(m.$2, color: AppTheme.bronze, size: 28),
                              const SizedBox(height: 6),
                              Text(m.$1,
                                  style: Theme.of(ctx).textTheme.titleSmall),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Reminder toggles for water / meal / evening wind-down.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pad = NfLayout.pagePad(context);

    return Scaffold(
      backgroundColor: AppTheme.labBg,
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(pad, 12, pad, 40),
        children: [
          Text(
            'Local nudges only — Bot stays quiet unless you enable them.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          NfGlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  value: state.remindWater,
                  activeTrackColor: AppTheme.bronze,
                  title: const Text('Water nudge'),
                  subtitle: const Text('Midday hydration ping'),
                  onChanged: state.setRemindWater,
                ),
                const Divider(height: 1, color: AppTheme.labBorder),
                SwitchListTile(
                  value: state.remindMeal,
                  activeTrackColor: AppTheme.bronze,
                  title: const Text('Meal log nudge'),
                  subtitle: const Text('Evening diary reminder'),
                  onChanged: state.setRemindMeal,
                ),
                const Divider(height: 1, color: AppTheme.labBorder),
                SwitchListTile(
                  value: state.remindWindDown,
                  activeTrackColor: AppTheme.bronze,
                  title: const Text('Wind-down'),
                  subtitle: const Text('Quiet evening · log sleep'),
                  onChanged: state.setRemindWindDown,
                ),
                const Divider(height: 1, color: AppTheme.labBorder),
                SwitchListTile(
                  value: state.quietHours,
                  activeTrackColor: AppTheme.bronze,
                  title: const Text('Quiet hours'),
                  subtitle: const Text('Bot won’t initiate after 21:00'),
                  onChanged: state.setQuietHours,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Weekly recap from real weekly calories / workouts / steps.
class WeeklyRecapScreen extends StatelessWidget {
  const WeeklyRecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pad = NfLayout.pagePad(context);
    final week = state.weeklyCalories;
    final max = week.fold<double>(0, (a, b) => a > b ? a : b);
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Scaffold(
      backgroundColor: AppTheme.labBg,
      appBar: AppBar(title: const Text('Weekly recap')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(pad, 12, pad, 40),
        children: [
          NfGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This week',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  '${state.workoutsCompleted} workouts · ${state.mealsLogged} meals · ${state.dayStreak}-day streak',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: FractionallySizedBox(
                                    heightFactor: max <= 0
                                        ? 0.08
                                        : (week[i] / max).clamp(0.08, 1.0),
                                    widthFactor: 1,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: AppTheme.bronze
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(days[i],
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  max <= 0
                      ? 'No calories logged this week yet.'
                      : 'Bars show logged calories by day.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          NfGlassCard(
            child: Text(
              state.dailyBriefing,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.labInk,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
