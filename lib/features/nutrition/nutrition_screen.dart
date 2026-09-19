import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/providers/app_state.dart';
import '../plate/plate_screen.dart';

/// Diary — empty until the user logs real meals.
class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.labBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Text(
              'Diary',
              style: theme.textTheme.displaySmall?.copyWith(
                color: AppTheme.labInk,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Meals appear here after you confirm a scan. Nothing is pre-filled.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.labCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.labBorder),
              ),
              child: Column(
                children: [
                  Text(
                    'Today',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.electric,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    state.todayMeals.isEmpty
                        ? '— / ${state.calorieGoal} kcal'
                        : '${state.caloriesConsumed} / ${state.calorieGoal} kcal',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppTheme.labInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.todayMeals.isEmpty
                        ? 'Log a meal to start tracking.'
                        : '${state.todayMeals.length} meal${state.todayMeals.length == 1 ? '' : 's'} confirmed today.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PlateScreen()),
                        );
                      },
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Scan meal'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Logged meals',
              style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.labInk),
            ),
            const SizedBox(height: 10),
            if (state.todayMeals.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.labCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.labBorder),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.no_meals_outlined,
                        size: 40, color: AppTheme.labMuted),
                    const SizedBox(height: 12),
                    Text(
                      'Empty diary',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.labInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Snap → analyze → confirm. No demo meals.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              )
            else
              ...state.todayMeals.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.labCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.labBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            m.foodName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.labInk,
                            ),
                          ),
                        ),
                        Text(
                          '${m.calories} kcal',
                          style: const TextStyle(color: AppTheme.electric),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
