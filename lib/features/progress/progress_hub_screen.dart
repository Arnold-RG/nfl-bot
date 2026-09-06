import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/engines/activity_engine.dart';
import '../../core/engines/body_engine.dart';
import '../../core/providers/app_state.dart';
import '../shared/app_ui.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final day = BodyEngine.snapshot(state);
    final theme = Theme.of(context);
    final week = state.weeklyCalories;
    final challenges = state.activityChallenges;
    final board = ActivityEngine.mockLeaderboard(
      youName: state.userName,
      youSteps: state.steps,
    );

    return AppPage(
      title: 'Progress',
      subtitle: 'Scores, challenges, recovery, and weekly report.',
      children: [
        Row(
          children: [
            Expanded(
              child: MetricTile(
                icon: Icons.fitness_center_rounded,
                label: 'Strength Score',
                value: '${state.strengthScore}',
                accent: AppTheme.electricDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                icon: Icons.directions_run_rounded,
                label: 'Fitness Score',
                value: '${state.fitnessScore}',
                accent: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                icon: Icons.favorite_outline_rounded,
                label: 'Health Score',
                value: '${day.healthScore}',
                accent: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                icon: Icons.local_fire_department,
                label: 'Streak',
                value: '${state.lifestyleStreak}',
                hint: 'Rest days count',
                accent: AppTheme.amber,
              ),
            ),
          ],
        ),
        SectionLabel('Challenges'),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: challenges.length,
            separatorBuilder: (_, i) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final c = challenges[i];
              return SizedBox(
                width: 160,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title, style: theme.textTheme.titleSmall),
                      const Spacer(),
                      Text(c.label, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: c.progress,
                          minHeight: 6,
                          color: AppTheme.electric,
                          backgroundColor: AppTheme.dividerColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SectionLabel('Weekly report'),
        AppCard(
          child: Text(
            state.weeklyReportBrief,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        SectionLabel('Body'),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                icon: Icons.monitor_weight_outlined,
                label: 'Weight',
                value: state.hasProfile
                    ? '${state.profile.weightKg.toStringAsFixed(1)} kg'
                    : '—',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                icon: Icons.speed_rounded,
                label: 'BMI',
                value: state.hasProfile
                    ? state.profile.bmi.toStringAsFixed(1)
                    : '—',
                hint: state.hasProfile ? state.profile.bmiCategory : null,
              ),
            ),
          ],
        ),
        SectionLabel('Calories this week'),
        AppCard(
          child: SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final i = v.toInt();
                        if (i < 0 || i > 6) return const SizedBox.shrink();
                        return Text(days[i], style: theme.textTheme.bodySmall);
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < week.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: week[i] <= 0 ? 40 : week[i],
                          color: AppTheme.primaryColor,
                          width: 14,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        SectionLabel('Today snapshot'),
        AppCard(
          child: Column(
            children: [
              _row(theme, 'Steps', '${day.steps} / ${day.stepGoal}'),
              _row(
                theme,
                'Protein',
                '${day.proteinG.toStringAsFixed(0)} / ${day.proteinGoal.toStringAsFixed(0)} g',
              ),
              _row(theme, 'Recovery', '${day.recoveryPercent}%'),
              _row(theme, 'Readiness', '${day.trainingReadiness}%'),
              _row(theme, 'Workouts', '${state.workoutsCompleted}'),
            ],
          ),
        ),
        SectionLabel('Leaderboard (mock)'),
        AppCard(
          child: Column(
            children: [
              for (final e in board.take(5))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text('#${e.rank}',
                            style: theme.textTheme.titleSmall),
                      ),
                      Expanded(
                        child: Text(
                          e.isYou ? '${e.name} (you)' : e.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                e.isYou ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      Text('${e.steps}', style: theme.textTheme.titleSmall),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(ThemeData theme, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(k, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(v, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
