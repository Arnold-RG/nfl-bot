import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../../core/providers/app_state.dart';

/// Weekly progress analytics and achievement tracking.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        // The series ends today, so labels are generated backwards from today
        // rather than assuming a fixed Monday-to-Sunday window.
        final today = DateTime.now();
        final days = List.generate(
          7,
          (i) => DateFormat.E().format(today.subtract(Duration(days: 6 - i))),
        );
        final peak = state.weeklyCalories.reduce((a, b) => a > b ? a : b);
        final maxCal = peak <= 0 ? 2000.0 : peak;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              const Text('Your Progress', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Weekly wellness analytics', style: TextStyle(color: Color(0xFF5F6F72))),
              const SizedBox(height: 20),
              Row(
                children: [
                  _StatCard(
                    label: 'Workouts',
                    value: '${state.workoutsCompleted}',
                    icon: Icons.fitness_center_rounded,
                    color: const Color(0xFF00C853),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Meals logged',
                    value: '${state.mealsLogged}',
                    icon: Icons.restaurant_rounded,
                    color: const Color(0xFFFF6B6B),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(
                    label: 'Last sleep',
                    value: state.hasSleepLog ? '${state.sleepHours}h' : '—',
                    icon: Icons.bedtime_rounded,
                    color: const Color(0xFF7B68EE),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Hydration',
                    value: '${state.hydrationLiters.toStringAsFixed(1)}L',
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFF42A5F5),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Weekly calories', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          maxY: maxCal * 1.2,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) => Text(
                                  days[v.toInt() % 7],
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          barGroups: List.generate(7, (i) {
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: state.weeklyCalories[i],
                                  color: i == 6
                                      ? const Color(0xFF00C853)
                                      : const Color(0xFF00C853).withValues(alpha: 0.4),
                                  width: 20,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _AchievementCard(
                title: 'Steps today',
                desc: '${state.steps} of ${state.stepGoal} — ${(state.stepProgress * 100).toInt()}% of goal',
                progress: state.stepProgress,
              ),
              _AchievementCard(
                title: 'Calories today',
                desc: '${state.caloriesConsumed} / ${state.calorieGoal} kcal consumed',
                progress: (state.caloriesConsumed / state.calorieGoal).clamp(0.0, 1.0),
              ),
              _AchievementCard(
                title: 'Protein today',
                desc: '${state.proteinG.toStringAsFixed(0)} of '
                    '${state.targets.proteinG.toStringAsFixed(0)}g logged',
                progress: (state.proteinG / state.targets.proteinG)
                    .clamp(0.0, 1.0),
              ),
              _AchievementCard(
                title: 'Hydration today',
                desc: '${state.hydrationLiters.toStringAsFixed(1)} of '
                    '${state.hydrationGoal.toStringAsFixed(1)}L',
                progress: (state.hydrationLiters / state.hydrationGoal)
                    .clamp(0.0, 1.0),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6F72))),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final String title, desc;
  final double progress;
  const _AchievementCard({required this.title, required this.desc, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xFF5F6F72))),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE8EFEA),
              color: const Color(0xFF00C853),
            ),
          ),
        ],
      ),
    );
  }
}
