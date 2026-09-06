import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/models/meal_recognition.dart';
import '../../core/providers/app_state.dart';
import '../../core/services/app_services.dart';
import '../shared/app_ui.dart';

class PlateScreen extends StatefulWidget {
  const PlateScreen({super.key});

  @override
  State<PlateScreen> createState() => _PlateScreenState();
}

class _PlateScreenState extends State<PlateScreen> {
  final _picker = ImagePicker();
  Uint8List? _bytes;
  MealRecognition? _result;
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    if (!await AppServices.billing.consumeScan()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppServices.billing.scanGateReason ?? '')),
      );
      return;
    }

    Uint8List bytes;
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1400,
        imageQuality: 86,
      );
      if (file == null) return;
      bytes = await file.readAsBytes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open camera/gallery: $e')),
      );
      return;
    }

    setState(() {
      _bytes = bytes;
      _result = null;
      _busy = true;
    });

    final result = await AppServices.foodVision.analyze(bytes);
    if (!mounted) return;
    setState(() {
      _result = result;
      _busy = false;
    });

    if (result.succeeded && AppServices.appState.voiceEnabled) {
      await AppServices.voice.speak(
        'That plate is about ${result.totalCalories} calories with '
        '${result.totalProteinG.toStringAsFixed(0)} grams of protein.',
        voice: AppServices.appState.coachVoice,
      );
    }
  }

  void _log() {
    final result = _result;
    if (result == null || !result.succeeded) return;
    context.read<AppState>().logMeal(result.asSingleEntry());
    setState(() {
      _result = null;
      _bytes = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to today’s meals')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppServices.locale.copy;
    final state = context.watch<AppState>();
    final result = _result;
    final theme = Theme.of(context);

    return AppPage(
      title: copy.t('plate'),
      subtitle: 'Snap a meal or attach a photo for calories and protein.',
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(copy.t('scanPlate')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.image_outlined),
                label: Text(copy.t('attachPlate')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_bytes != null)
          AppCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _bytes!,
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (_busy) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analyzing meal…', style: theme.textTheme.titleSmall),
                const SizedBox(height: 10),
                const LinearProgressIndicator(),
              ],
            ),
          ),
        ],
        if (result != null && result.succeeded) ...[
          const SizedBox(height: 16),
          SectionLabel('Estimate'),
          MacroGrid(
            kcal: result.totalCalories,
            protein: result.totalProteinG,
            carbs: result.totalCarbsG,
            fat: result.totalFatG,
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                for (final item in result.items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name, style: theme.textTheme.titleSmall),
                    subtitle: Text(
                      '${item.portionG.toStringAsFixed(0)} g · ${item.calories} kcal · '
                      '${item.proteinG.toStringAsFixed(0)} g protein',
                    ),
                  ),
                if (result.insight != null) ...[
                  const Divider(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(result.insight!, style: theme.textTheme.bodyMedium),
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _log,
                    child: const Text('Add to today'),
                  ),
                ),
              ],
            ),
          ),
        ] else if (result?.failure != null) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Text(
              result!.failure!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.warningColor,
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        SectionLabel('Today'),
        MacroGrid(
          kcal: state.caloriesConsumed,
          protein: state.proteinG,
          carbs: state.carbsG,
          fat: state.fatG,
        ),
        const SizedBox(height: 12),
        if (state.todayMeals.isEmpty)
          AppCard(
            child: Text(
              'No meals logged yet. Take a photo of your next plate.',
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
                    trailing: Text(
                      '${state.todayMeals[i].calories} kcal',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
