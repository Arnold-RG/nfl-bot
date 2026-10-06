import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/providers/app_state.dart';
import '../plate/plate_screen.dart';
import '../shared/nf_design.dart';

/// Diary — empty until the user logs real meals.
class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final pad = NfLayout.pagePad(context);

    return Scaffold(
      backgroundColor: AppTheme.labBg,
      body: NfAmbientBackdrop(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(pad, 8, pad, 120),
            children: [
              Text(
                'Diary',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppTheme.labInk,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Meals appear after you confirm a scan. Nothing is pre-filled.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              NfGlassCard(
                child: Column(
                  children: [
                    Text(
                      'TODAY',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.bronze,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      state.todayMeals.isEmpty
                          ? '— / ${state.calorieGoal} kcal'
                          : '${state.caloriesConsumed} / ${state.calorieGoal} kcal',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppTheme.labInk,
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
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PlateScreen(),
                            ),
                          );
                        },
                        child: const Text('Scan meal'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const NfSectionLabel('Coach plan'),
              Text(
                state.nutritionPlan.headline,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.labInk,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.nutritionPlan.coachNote,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ...state.nutritionPlan.suggestions.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: NfGlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppTheme.labInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s.calories} kcal · ${s.proteinG.toStringAsFixed(0)} g protein · ${s.vitaminsHint}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.bronzeSoft,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(s.reason, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const NfSectionLabel('Logged meals'),
              if (state.todayMeals.isEmpty)
                NfGlassCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.no_meals_outlined,
                        size: 36,
                        color: AppTheme.labMuted,
                      ),
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
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NfGlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              m.foodName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppTheme.labInk,
                              ),
                            ),
                          ),
                          Text(
                            '${m.calories} kcal',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.bronze,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
