import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/models/meal_recognition.dart';
import '../../core/providers/app_state.dart';
import '../../core/services/app_services.dart';
import '../shared/lab_ui.dart';

/// Snap → Analyze → Confirm → Track (CalorieLab loop).
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
  }

  Future<void> _editItem(int index) async {
    final result = _result;
    if (result == null || index >= result.items.length) return;
    final edited = await showModalBottomSheet<RecognizedFood>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PortionEditorSheet(item: result.items[index]),
    );
    if (edited == null || !mounted) return;
    final items = [...result.items];
    items[index] = edited;
    setState(() => _result = result.copyWith(items: items));
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
      const SnackBar(content: Text('Meal added to your diary')),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final step = result != null && result.succeeded ? 2 : (_busy ? 1 : 0);

    return Scaffold(
      backgroundColor: AppTheme.labBg,
      appBar: AppBar(
        title: const Text('Add Meal'),
        backgroundColor: AppTheme.labBg,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _Steps(active: step),
          const SizedBox(height: 16),
          Text(
            'Take a photo — AI estimates calories. You confirm before logging.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_bytes != null)
            LabCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.memory(
                  _bytes!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LabCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analyzing meal…',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.labInk,
                    ),
                  ),
                  SizedBox(height: 12),
                  LinearProgressIndicator(
                    color: AppTheme.labOrange,
                    backgroundColor: AppTheme.labBorder,
                  ),
                ],
              ),
            ),
          ],
          if (result != null && result.succeeded) ...[
            const SizedBox(height: 16),
            LabCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: AppTheme.labOrange),
                      const SizedBox(width: 8),
                      const Text(
                        'AI estimate',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.labInk,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${result.totalCalories} kcal',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.labOrange,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MacroPill(
                        'P ${result.totalProteinG.toStringAsFixed(0)}g',
                        AppTheme.labBlue,
                      ),
                      const SizedBox(width: 8),
                      _MacroPill(
                        'C ${result.totalCarbsG.toStringAsFixed(0)}g',
                        AppTheme.labOrange,
                      ),
                      const SizedBox(width: 8),
                      _MacroPill(
                        'F ${result.totalFatG.toStringAsFixed(0)}g',
                        AppTheme.labPink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < result.items.length; i++) ...[
                    const Divider(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        result.items[i].name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.labInk,
                        ),
                      ),
                      subtitle: Text(
                        '${result.items[i].portionG.toStringAsFixed(0)} g · '
                        '${result.items[i].calories} kcal',
                      ),
                      trailing: TextButton(
                        onPressed: () => _editItem(i),
                        child: const Text('Edit'),
                      ),
                    ),
                  ],
                  if (result.insight != null) ...[
                    const Divider(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        result.insight!,
                        style: const TextStyle(color: AppTheme.labMuted),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _log,
                      child: const Text(
                        'Confirm & add to diary',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (result?.failure != null) ...[
            const SizedBox(height: 16),
            LabCard(
              child: Text(
                result!.failure!,
                style: const TextStyle(
                  color: AppTheme.labOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  final int active;
  const _Steps({required this.active});

  @override
  Widget build(BuildContext context) {
    const labels = ['Snap', 'Analyze', 'Track'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: i <= active ? AppTheme.labOrange : AppTheme.labBorder,
              ),
            ),
          Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    i <= active ? AppTheme.labInk : AppTheme.labBorder,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: i <= active ? Colors.white : AppTheme.labMuted,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: i == active ? FontWeight.w800 : FontWeight.w500,
                  color: AppTheme.labInk,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String text;
  final Color color;
  const _MacroPill(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }
}

class _PortionEditorSheet extends StatefulWidget {
  final RecognizedFood item;
  const _PortionEditorSheet({required this.item});

  @override
  State<_PortionEditorSheet> createState() => _PortionEditorSheetState();
}

class _PortionEditorSheetState extends State<_PortionEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _portion;
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;

  @override
  void initState() {
    super.initState();
    final p = widget.item;
    _name = TextEditingController(text: p.name);
    _portion = TextEditingController(text: p.portionG.toStringAsFixed(0));
    _calories = TextEditingController(text: p.calories.toString());
    _protein = TextEditingController(text: p.proteinG.toStringAsFixed(0));
    _carbs = TextEditingController(text: p.carbsG.toStringAsFixed(0));
    _fat = TextEditingController(text: p.fatG.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _name.dispose();
    _portion.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  void _onPortionChanged(String raw) {
    final next = double.tryParse(raw.trim());
    if (next == null || next <= 0) return;
    final scaled = widget.item.scaledToPortion(next);
    setState(() {
      _calories.text = scaled.calories.toString();
      _protein.text = scaled.proteinG.toStringAsFixed(0);
      _carbs.text = scaled.carbsG.toStringAsFixed(0);
      _fat.text = scaled.fatG.toStringAsFixed(0);
    });
  }

  void _save() {
    double n(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
    Navigator.pop(
      context,
      RecognizedFood(
        name: _name.text.trim().isEmpty ? widget.item.name : _name.text.trim(),
        portionG: n(_portion),
        calories: n(_calories).round(),
        proteinG: n(_protein),
        carbsG: n(_carbs),
        fatG: n(_fat),
        fiberG: widget.item.fiberG,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.labBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Adjust estimate',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.labInk,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Change portion to auto-scale macros, or edit any field.',
              style: TextStyle(color: AppTheme.labMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Food name'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _portion,
                    keyboardType: TextInputType.number,
                    onChanged: _onPortionChanged,
                    decoration: const InputDecoration(
                      labelText: 'Portion',
                      suffixText: 'g',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _calories,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calories',
                      suffixText: 'kcal',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _protein,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Protein',
                      suffixText: 'g',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _carbs,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Carbs',
                      suffixText: 'g',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fat,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fat',
                      suffixText: 'g',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _save,
                child: const Text(
                  'Save adjustments',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
