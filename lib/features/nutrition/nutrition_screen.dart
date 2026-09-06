import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/engines/body_engine.dart';
import '../../core/engines/fasting_engine.dart';
import '../../core/providers/app_state.dart';
import '../plate/plate_screen.dart';
import '../shared/app_ui.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final day = BodyEngine.snapshot(state);
    final theme = Theme.of(context);
    final plan = state.caloriePlan;
    final fast = state.fastingStatus;

    return AppPage(
      title: 'Nutrition',
      subtitle: 'Diary, AI food camera, macros, fasting, and water.',
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MacroBar(
                label: 'Calories',
                current: day.caloriesConsumed,
                goal: plan.adjustedTarget.toDouble(),
                color: AppTheme.primaryColor,
              ),
              MacroBar(
                label: 'Protein',
                current: day.proteinG,
                goal: day.proteinGoal,
                color: const Color(0xFF2563EB),
              ),
              MacroBar(
                label: 'Carbs',
                current: day.carbsG,
                goal: day.carbsGoal,
                color: AppTheme.amber,
              ),
              MacroBar(
                label: 'Fat',
                current: day.fatG,
                goal: day.fatGoal,
                color: const Color(0xFFDB2777),
              ),
              Text(
                '${(plan.adjustedTarget - day.caloriesConsumed).clamp(0, 99999)} kcal remaining · '
                'target ${plan.adjustedTarget} (base ${plan.baseTarget}'
                '${plan.activityAdjustment > 0 ? ' +${plan.activityAdjustment} activity' : ''})',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                plan.note,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        AppCard(
          child: Text(
            'AI calorie and macro estimates must be confirmed before you log — edit portions if they look wrong.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.warningColor,
            ),
          ),
        ),
        SectionLabel('Food diary'),
        if (state.todayMeals.isEmpty)
          AppCard(
            child: Text(
              'No meals yet. Scan a plate, barcode, or attach a photo — AI estimates are editable before you log.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          AppCard(
            child: Column(
              children: [
                for (var i = 0; i < state.todayMeals.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      state.todayMeals[i].foodName,
                      style: theme.textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      '${state.todayMeals[i].proteinG.toStringAsFixed(0)} g protein',
                    ),
                    trailing: Text('${state.todayMeals[i].calories} kcal'),
                  ),
                ],
              ],
            ),
          ),
        SectionLabel('Log food'),
        AppCard(
          onTap: () => _openPlate(context),
          child: SettingTile(
            icon: Icons.photo_camera_outlined,
            title: 'Scan or attach a meal photo',
            subtitle: 'Estimate → edit portions → log',
            onTap: () => _openPlate(context),
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          onTap: () => _barcodeStub(context),
          child: SettingTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Barcode',
            subtitle: 'Scan or enter a product code (stub)',
            onTap: () => _barcodeStub(context),
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          onTap: () => _recipeStub(context),
          child: SettingTile(
            icon: Icons.auto_awesome_outlined,
            title: 'Recipe AI',
            subtitle: 'Suggest a high-protein meal',
            onTap: () => _recipeStub(context),
          ),
        ),
        SectionLabel('Fasting'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final p in FastingProtocol.values)
                    ChoiceChip(
                      label: Text(p.label),
                      selected: state.fastingProtocol == p,
                      onSelected: (_) => state.setFastingProtocol(p),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                fast.active
                    ? 'Elapsed ${fast.elapsedLabel} · remaining ${fast.remainingLabel}'
                    : 'Not fasting · ${fast.protocol.label} window ready',
                style: theme.textTheme.titleMedium,
              ),
              if (fast.active) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: fast.progress,
                    minHeight: 8,
                    color: AppTheme.electric,
                    backgroundColor: AppTheme.dividerColor,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: fast.active
                          ? () => state.stopFasting()
                          : null,
                      child: const Text('End fast'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: fast.active
                          ? null
                          : () => state.startFasting(),
                      child: const Text('Start fast'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SectionLabel('Water'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day.waterLiters.toStringAsFixed(1)} / ${day.waterGoal.toStringAsFixed(1)} L',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => state.addHydration(0.25),
                      child: const Text('+250 ml'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => state.addHydration(0.5),
                      child: const Text('+500 ml'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openPlate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Scan food')),
          body: const PlateScreen(),
        ),
      ),
    );
  }

  Future<void> _barcodeStub(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Barcode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Scan with the camera on mobile, or enter a barcode manually. '
              'Lookup is a stub in this build.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Scan / enter barcode',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    controller.text.trim().isEmpty
                        ? 'No barcode entered'
                        : 'Barcode ${controller.text.trim()} — product lookup coming soon',
                  ),
                ),
              );
            },
            child: const Text('Look up'),
          ),
        ],
      ),
    );
  }

  Future<void> _recipeStub(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recipe AI'),
        content: const Text(
          'High-protein suggestion (stub):\n\n'
          '• Greek yogurt bowl — 250 g yogurt, berries, 20 g whey, '
          'handful of almonds (~45 g protein)\n'
          '• Chicken + rice plate — 150 g chicken breast, 120 g cooked rice, '
          'broccoli (~42 g protein)\n\n'
          'Confirm portions before logging. AI estimates are not nutrition labels.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
