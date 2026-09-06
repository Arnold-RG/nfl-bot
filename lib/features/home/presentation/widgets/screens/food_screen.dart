import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../../config/routes.dart';
import '../../../../../core/models/food_model.dart';
import '../../../../../core/models/meal_recognition.dart';
import '../../../../../core/models/coach_persona.dart';
import '../../../../../core/providers/app_state.dart';
import '../../../../../core/services/app_services.dart';
import '../components/ai_voice_orb.dart';
import '../components/live_coach_orb.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  MealRecognition? _result;
  bool _analyzing = false;

  Future<void> _pickImage(ImageSource source) async {
    Uint8List bytes;
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (file == null) return;
      bytes = await file.readAsBytes();
    } catch (e) {
      if (!mounted) return;
      _toast('Could not open ${source.name}: $e');
      return;
    }
    if (!mounted) return;

    setState(() {
      _imageBytes = bytes;
      _result = null;
      _analyzing = true;
    });

    context.read<AppState>().setCoachState(
      CoachMood.focused,
      'Looking at your meal...',
    );

    final result = await AppServices.foodVision.analyze(bytes);
    if (!mounted) return;

    setState(() {
      _result = result;
      _analyzing = false;
    });

    if (result.succeeded) {
      context.read<AppState>().setCoachState(
        CoachMood.celebrating,
        'Estimated ${result.totalCalories} kcal on that plate.',
      );
    } else {
      context.read<AppState>().setCoachState(CoachMood.concerned);
    }
  }

  void _logRecognized() {
    final result = _result;
    if (result == null || !result.succeeded) return;
    context.read<AppState>().logMeal(result.asSingleEntry());
    setState(() {
      _result = null;
      _imageBytes = null;
    });
    _toast('Meal logged');
  }

  Future<void> _addManually({RecognizedFood? prefill}) async {
    final food = await showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualEntrySheet(prefill: prefill),
    );
    if (food == null || !mounted) return;
    context.read<AppState>().logMeal(food);
    setState(() {
      _result = null;
      _imageBytes = null;
    });
    _toast('${food.name} logged');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF00C853),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visionReady = AppServices.foodVision.isAvailable;

    return SafeArea(
      child: Consumer<AppState>(
        builder: (context, state, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nutrition',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Log what you eat and track it against your targets',
                        style: TextStyle(color: Color(0xFF5F6F72)),
                      ),
                    ],
                  ),
                ),
                const LiveCoachOrb(size: 56),
              ],
            ),
            const SizedBox(height: 20),
            _MacroSummary(state: state),
            const SizedBox(height: 20),
            if (visionReady)
              _PhotoActions(
                onCamera: () => _pickImage(ImageSource.camera),
                onGallery: () => _pickImage(ImageSource.gallery),
                onManual: () => _addManually(),
              )
            else
              _VisionUnavailableCard(onManual: () => _addManually()),
            if (_imageBytes != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.memory(
                  _imageBytes!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            if (_analyzing) ...[
              const SizedBox(height: 24),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00C853)),
                    SizedBox(height: 12),
                    Text(
                      'Estimating nutrition from your photo...',
                      style: TextStyle(color: Color(0xFF5F6F72)),
                    ),
                  ],
                ),
              ),
            ],
            if (_result != null && !_analyzing) ...[
              const SizedBox(height: 20),
              if (_result!.succeeded)
                _RecognitionCard(
                  result: _result!,
                  onLog: _logRecognized,
                  onAdjust: () =>
                      _addManually(prefill: _result!.items.first),
                )
              else
                _AnalysisFailedCard(
                  reason: _result!.failure!,
                  onManual: () => _addManually(),
                ),
            ],
            const SizedBox(height: 28),
            const Text(
              'Logged today',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (state.todayMeals.isEmpty)
              const _EmptyMeals()
            else
              ...state.todayMeals.reversed.map((m) => _LoggedMealTile(meal: m)),
          ],
        ),
      ),
    );
  }
}

class _MacroSummary extends StatelessWidget {
  final AppState state;
  const _MacroSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final targets = state.targets;
    final remaining = (targets.calories - state.caloriesConsumed).clamp(
      0,
      99999,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1F1A), Color(0xFF1B5E45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$remaining',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'kcal left',
                  style: TextStyle(color: Color(0xFFB8D4C8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            state.hasProfile
                ? '${state.caloriesConsumed} of ${targets.calories} kcal · target built from your body metrics'
                : '${state.caloriesConsumed} of ${targets.calories} kcal · add your body metrics in Settings for a personal target',
            style: const TextStyle(color: Color(0xFFB8D4C8), fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MacroBar(
                label: 'Protein',
                current: state.proteinG,
                target: targets.proteinG,
                color: const Color(0xFFFFA85C),
              ),
              const SizedBox(width: 10),
              _MacroBar(
                label: 'Carbs',
                current: state.carbsG,
                target: targets.carbsG,
                color: const Color(0xFF7BC7B1),
              ),
              const SizedBox(width: 10),
              _MacroBar(
                label: 'Fat',
                current: state.fatG,
                target: targets.fatG,
                color: const Color(0xFFB38CFF),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFB8D4C8), fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}g',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoActions extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onManual;

  const _PhotoActions({
    required this.onCamera,
    required this.onGallery,
    required this.onManual,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ScanButton(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                color: const Color(0xFF00C853),
                onTap: onCamera,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScanButton(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                color: const Color(0xFF1A1A2E),
                onTap: onGallery,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onManual,
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('Enter a meal manually'),
        ),
      ],
    );
  }
}

/// Shown when no vision model is connected. The app says what it cannot do
/// instead of producing an estimate it has no basis for.
class _VisionUnavailableCard extends StatelessWidget {
  final VoidCallback onManual;
  const _VisionUnavailableCard({required this.onManual});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD9A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.camera_enhance_rounded, color: Color(0xFFB26A00)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Photo analysis needs an AI model',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect Claude or OpenAI in Settings and the app will estimate '
            'calories and macros straight from a photo of your plate. Until '
            'then you can log meals by hand.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.settings),
                  child: const Text('Open Settings'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onManual,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add meal'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalysisFailedCard extends StatelessWidget {
  final String reason;
  final VoidCallback onManual;

  const _AnalysisFailedCard({required this.reason, required this.onManual});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5C2C2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Color(0xFFC62828)),
              SizedBox(width: 10),
              Text(
                'Could not read that plate',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(reason, style: const TextStyle(fontSize: 13, height: 1.4)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onManual,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Enter it manually'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecognitionCard extends StatelessWidget {
  final MealRecognition result;
  final VoidCallback onLog;
  final VoidCallback onAdjust;

  const _RecognitionCard({
    required this.result,
    required this.onLog,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimated from your photo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          const Text(
            'Portion sizes are visual estimates — adjust anything that looks off.',
            style: TextStyle(fontSize: 12, color: Color(0xFF5F6F72)),
          ),
          const SizedBox(height: 16),
          ...result.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.restaurant_rounded,
                    size: 18,
                    color: Color(0xFF00C853),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '~${item.portionG.toStringAsFixed(0)}g · '
                          '${item.proteinG.toStringAsFixed(0)}p '
                          '${item.carbsG.toStringAsFixed(0)}c '
                          '${item.fatG.toStringAsFixed(0)}f',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5F6F72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.calories} kcal',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          Row(
            children: [
              _TotalChip(
                label: 'Total',
                value: '${result.totalCalories}',
                unit: 'kcal',
                color: const Color(0xFF00C853),
              ),
              const SizedBox(width: 8),
              _TotalChip(
                label: 'Protein',
                value: result.totalProteinG.toStringAsFixed(0),
                unit: 'g',
                color: const Color(0xFFFFA85C),
              ),
              const SizedBox(width: 8),
              _TotalChip(
                label: 'Carbs',
                value: result.totalCarbsG.toStringAsFixed(0),
                unit: 'g',
                color: const Color(0xFF7BC7B1),
              ),
              const SizedBox(width: 8),
              _TotalChip(
                label: 'Fat',
                value: result.totalFatG.toStringAsFixed(0),
                unit: 'g',
                color: const Color(0xFFB38CFF),
              ),
            ],
          ),
          if (result.insight != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const AiVoiceOrb(size: 40, compact: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.insight!,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onAdjust,
                  child: const Text('Adjust'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onLog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Log this meal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManualEntrySheet extends StatefulWidget {
  final RecognizedFood? prefill;
  const _ManualEntrySheet({this.prefill});

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _portion;
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    _name = TextEditingController(text: p?.name ?? '');
    _portion = TextEditingController(
      text: p != null ? p.portionG.toStringAsFixed(0) : '',
    );
    _calories = TextEditingController(text: p?.calories.toString() ?? '');
    _protein = TextEditingController(
      text: p != null ? p.proteinG.toStringAsFixed(0) : '',
    );
    _carbs = TextEditingController(
      text: p != null ? p.carbsG.toStringAsFixed(0) : '',
    );
    _fat = TextEditingController(
      text: p != null ? p.fatG.toStringAsFixed(0) : '',
    );
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    double parse(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

    Navigator.of(context).pop(
      FoodItem(
        id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
        name: _name.text.trim(),
        brand: 'Manual entry',
        servingSizeG: parse(_portion),
        calories: parse(_calories).round(),
        proteinG: parse(_protein),
        carbsG: parse(_carbs),
        fatG: parse(_fat),
        fiberG: 0,
        vitamins: const {},
        minerals: const {},
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
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCFD8DC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.prefill == null ? 'Add a meal' : 'Adjust the estimate',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'What did you eat?',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _NumberField(
                      controller: _calories,
                      label: 'Calories',
                      suffix: 'kcal',
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumberField(
                      controller: _portion,
                      label: 'Portion',
                      suffix: 'g',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _NumberField(
                      controller: _protein,
                      label: 'Protein',
                      suffix: 'g',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NumberField(
                      controller: _carbs,
                      label: 'Carbs',
                      suffix: 'g',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NumberField(
                      controller: _fat,
                      label: 'Fat',
                      suffix: 'g',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Log meal'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool required;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: (v) {
        final text = v?.trim() ?? '';
        if (text.isEmpty) return required ? 'Required' : null;
        final parsed = double.tryParse(text);
        if (parsed == null || parsed < 0) return 'Invalid';
        return null;
      },
    );
  }
}

class _ScanButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ScanButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _TotalChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(unit, style: TextStyle(fontSize: 10, color: color)),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF5F6F72)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoggedMealTile extends StatelessWidget {
  final MealLogItem meal;
  const _LoggedMealTile({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: Color(0xFF00C853),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.foodName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${meal.proteinG.toStringAsFixed(0)}g protein · '
                  '${meal.carbsG.toStringAsFixed(0)}g carbs · '
                  '${meal.fatG.toStringAsFixed(0)}g fat',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5F6F72),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${meal.calories} kcal',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _EmptyMeals extends StatelessWidget {
  const _EmptyMeals();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.no_food_rounded,
            size: 34,
            color: Color(0xFFB0BEC5),
          ),
          SizedBox(height: 10),
          Text(
            'Nothing logged yet today',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Snap a photo or add a meal by hand to start tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF5F6F72)),
          ),
        ],
      ),
    );
  }
}
