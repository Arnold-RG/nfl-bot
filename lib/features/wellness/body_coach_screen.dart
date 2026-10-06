import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/engines/activity_engine.dart';
import '../../core/engines/nutrition_plan_engine.dart';
import '../../core/models/user_profile.dart';
import '../../core/providers/app_state.dart';
import '../shared/nf_design.dart';
import '../train/train_screen.dart';

/// Body-connected coach: goal progress, what to eat, skip/overeat recovery, training from food.
class BodyCoachScreen extends StatelessWidget {
  const BodyCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final plan = state.nutritionPlan;
    final advice = state.trainingAdvice;
    final pad = NfLayout.pagePad(context);

    return Scaffold(
      backgroundColor: AppTheme.labBg,
      appBar: AppBar(title: const Text('Body Coach')),
      body: NfAmbientBackdrop(
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, 12, pad, 40),
          children: [
            Text(
              'Connected to your body & health',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bot tracks your goal in real time, tells you what to eat (protein & vitamins), '
              'adapts if you skip or overeat, and turns that into gym time + sports you like.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            NfGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR GOAL',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTheme.bronze,
                            letterSpacing: 1.1,
                          )),
                  const SizedBox(height: 8),
                  Text(
                    state.profile.isComplete
                        ? state.profile.goal.label
                        : 'Set a goal in Account',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(state.bodyGoalSummary,
                      style: Theme.of(context).textTheme.bodyMedium),
                  if (state.profile.targetWeightKg != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: state.profile.weightGoalProgress ?? 0.15,
                        minHeight: 8,
                        backgroundColor: AppTheme.labBorder,
                        color: AppTheme.bronze,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Now ${state.profile.weightKg.toStringAsFixed(1)} kg → target ${state.profile.targetWeightKg!.toStringAsFixed(1)} kg',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _editTargetWeight(context, state),
                    icon: const Icon(Icons.monitor_weight_outlined),
                    label: const Text('Set target weight'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            NfGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.headline,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(plan.coachNote,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(context,
                          '${state.caloriesConsumed}/${state.calorieGoal} kcal'),
                      _chip(context,
                          '${state.proteinG.toStringAsFixed(0)}/${state.targets.proteinG.toStringAsFixed(0)} g protein'),
                      ...plan.vitaminFocus.entries.take(3).map(
                            (e) => _chip(context, 'Vit ${e.key}'),
                          ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Skip a meal?',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final slot in [
                        MealSlot.breakfast,
                        MealSlot.lunch,
                        MealSlot.dinner,
                      ])
                        FilterChip(
                          label: Text(slot.name),
                          selected: state.skippedMeals.contains(slot),
                          onSelected: (on) {
                            HapticFeedback.selectionClick();
                            if (on) {
                              state.skipMeal(slot);
                            } else {
                              state.clearSkippedMeal(slot);
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('Suggested plates',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final s in plan.suggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NfGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(s.reason,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Text(
                        '${s.calories} kcal · ${s.proteinG.toStringAsFixed(0)} g protein · ${s.vitaminsHint}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.bronzeSoft,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(s.plate.join(' · '),
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            NfGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TRAINING FROM YOUR FOOD',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTheme.bronze,
                            letterSpacing: 1.1,
                          )),
                  const SizedBox(height: 8),
                  Text(
                    '${advice.gymMinutes} min · ${advice.focus}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(advice.reason,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  for (final e in advice.exerciseTypes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.fitness_center,
                              size: 16, color: AppTheme.bronze),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(advice.sportReason,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        state.generateWorkout();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TrainScreen()),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start this session'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            NfGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sports you like',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Bot prefers these when suggesting alternatives to the gym.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final sport in const [
                        ActivityType.swim,
                        ActivityType.dance,
                        ActivityType.cycle,
                        ActivityType.run,
                        ActivityType.yoga,
                        ActivityType.walk,
                      ])
                        FilterChip(
                          label: Text(sport.label),
                          selected: state.preferredSports.contains(sport),
                          onSelected: (on) async {
                            HapticFeedback.selectionClick();
                            final next = [...state.preferredSports];
                            if (on) {
                              if (!next.contains(sport)) next.add(sport);
                            } else {
                              next.remove(sport);
                            }
                            await state.setPreferredSports(next);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppTheme.labBorder),
        color: AppTheme.labLift,
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }

  Future<void> _editTargetWeight(BuildContext context, AppState state) async {
    final controller = TextEditingController(
      text: state.profile.targetWeightKg?.toStringAsFixed(1) ??
          (state.profile.weightKg - 5).toStringAsFixed(1),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.labCard,
        title: const Text('Target weight (kg)'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'e.g. 70.0'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final v = double.tryParse(controller.text.replaceAll(',', '.'));
    if (v == null || v < 35 || v > 250) return;
    await state.setTargetWeightKg(v);
    if (state.profile.goal != FitnessGoal.cut) {
      await state.saveProfile(state.profile.copyWith(goal: FitnessGoal.cut));
    }
  }
}
