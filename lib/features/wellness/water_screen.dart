import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/providers/app_state.dart';

/// Daily + workout water logging.
class WaterScreen extends StatelessWidget {
  const WaterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final dayGoal = state.hydrationGoal;
    final day = state.hydrationLiters;
    final dayPct = dayGoal <= 0 ? 0.0 : (day / dayGoal).clamp(0.0, 1.0);
    final workout = state.workoutHydrationLiters;
    final workoutGoal = state.workoutHydrationGoal;

    return Scaffold(
      backgroundColor: AppTheme.labBg,
      appBar: AppBar(title: const Text('Water')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _RingCard(
            title: 'Today',
            subtitle:
                '${day.toStringAsFixed(1)} / ${dayGoal.toStringAsFixed(1)} L',
            progress: dayPct,
            color: AppTheme.labWater,
          ),
          const SizedBox(height: 12),
          _RingCard(
            title: 'This workout',
            subtitle:
                '${workout.toStringAsFixed(2)} / ${workoutGoal.toStringAsFixed(1)} L',
            progress: (workout / workoutGoal).clamp(0.0, 1.0),
            color: AppTheme.bronze,
          ),
          const SizedBox(height: 20),
          Text('Quick add', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Chip(
                label: '+250 ml',
                onTap: () => state.addHydration(0.25),
              ),
              _Chip(
                label: '+500 ml',
                onTap: () => state.addHydration(0.5),
              ),
              _Chip(
                label: 'Workout +200 ml',
                onTap: () => state.addWorkoutHydration(0.2),
              ),
              _Chip(
                label: 'Workout +400 ml',
                onTap: () => state.addWorkoutHydration(0.4),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Aim for ~35 ml per kg bodyweight daily, plus ~0.4–0.6 L per hard session.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final Color color;

  const _RingCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.labCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.labBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  backgroundColor: AppTheme.labBorder,
                  color: color,
                ),
                Icon(Icons.water_drop_rounded, color: color, size: 22),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.labLift,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
      ),
    );
  }
}
