import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/models/user_profile.dart';
import '../../../../../core/providers/app_state.dart';

/// Full-screen profile editor reached from Settings.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Body profile')),
      body: SafeArea(
        child: ProfileForm(
          initial: context.read<AppState>().profile,
          submitLabel: 'Save profile',
          onSubmit: (profile) async {
            await context.read<AppState>().saveProfile(profile);
            if (!context.mounted) return;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Targets recalculated from your metrics'),
                backgroundColor: Color(0xFF00C853),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Collects the body metrics that every personalized target depends on, and
/// previews the resulting numbers live so the user can see the effect.
class ProfileForm extends StatefulWidget {
  final UserProfile initial;
  final String submitLabel;
  final ValueChanged<UserProfile> onSubmit;

  /// Hides the surrounding title, for use inside the onboarding flow.
  final bool compact;

  const ProfileForm({
    super.key,
    required this.initial,
    required this.submitLabel,
    required this.onSubmit,
    this.compact = false,
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;

  late BiologicalSex _sex;
  late ActivityLevel _activity;
  late FitnessGoal _goal;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _sex = p.sex;
    _activity = p.activity;
    _goal = p.goal;
    _age = TextEditingController(text: p.isComplete ? '${p.age}' : '');
    _height = TextEditingController(
      text: p.isComplete ? p.heightCm.toStringAsFixed(0) : '',
    );
    _weight = TextEditingController(
      text: p.isComplete ? p.weightKg.toStringAsFixed(1) : '',
    );
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  /// Best-effort profile from whatever is currently typed, for the live
  /// preview. Falls back to the previous values while a field is empty.
  UserProfile get _draft => UserProfile(
    sex: _sex,
    age: int.tryParse(_age.text.trim()) ?? widget.initial.age,
    heightCm: double.tryParse(_height.text.trim()) ?? widget.initial.heightCm,
    weightKg: double.tryParse(_weight.text.trim()) ?? widget.initial.weightKg,
    activity: _activity,
    goal: _goal,
  );

  bool get _hasEnoughForPreview =>
      int.tryParse(_age.text.trim()) != null &&
      double.tryParse(_height.text.trim()) != null &&
      double.tryParse(_weight.text.trim()) != null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(_draft);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          if (!widget.compact) ...[
            const Text(
              'Your body metrics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Calorie, macro, hydration and step targets are calculated from '
              'these values. Nothing leaves your device.',
              style: TextStyle(color: Color(0xFF5F6F72), height: 1.4),
            ),
            const SizedBox(height: 22),
          ],
          _Label('Biological sex'),
          const SizedBox(height: 8),
          SegmentedButton<BiologicalSex>(
            segments: [
              for (final s in BiologicalSex.values)
                ButtonSegment(value: s, label: Text(s.label)),
            ],
            selected: {_sex},
            onSelectionChanged: (s) => setState(() => _sex = s.first),
          ),
          const SizedBox(height: 6),
          const Text(
            'Used for the metabolic rate equation, which differs by sex.',
            style: TextStyle(fontSize: 12, color: Color(0xFF5F6F72)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricField(
                  controller: _age,
                  label: 'Age',
                  suffix: 'yrs',
                  min: 13,
                  max: 100,
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricField(
                  controller: _height,
                  label: 'Height',
                  suffix: 'cm',
                  min: 120,
                  max: 230,
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricField(
                  controller: _weight,
                  label: 'Weight',
                  suffix: 'kg',
                  min: 30,
                  max: 300,
                  decimal: true,
                  onChanged: () => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _Label('Activity level'),
          const SizedBox(height: 8),
          ...ActivityLevel.values.map(
            (level) => _RadioTile<ActivityLevel>(
              value: level,
              groupValue: _activity,
              title: level.label,
              subtitle: level.description,
              onChanged: (v) => setState(() => _activity = v),
            ),
          ),
          const SizedBox(height: 22),
          _Label('Primary goal'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final goal in FitnessGoal.values)
                ChoiceChip(
                  label: Text(goal.label),
                  selected: _goal == goal,
                  onSelected: (_) => setState(() => _goal = goal),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_hasEnoughForPreview) _TargetPreview(profile: _draft),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                widget.submitLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Live readout of what the entered metrics produce, so the targets are
/// transparent rather than appearing from nowhere.
class _TargetPreview extends StatelessWidget {
  final UserProfile profile;
  const _TargetPreview({required this.profile});

  @override
  Widget build(BuildContext context) {
    final t = profile.targets;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1F1A), Color(0xFF1B5E45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your daily targets',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            'Maintenance is ${t.maintenanceCalories} kcal · '
            'BMI ${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory})',
            style: const TextStyle(color: Color(0xFFB8D4C8), fontSize: 12),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PreviewChip(
                label: 'Calories',
                value: '${t.calories}',
                unit: 'kcal',
              ),
              _PreviewChip(
                label: 'Protein',
                value: t.proteinG.toStringAsFixed(0),
                unit: 'g',
              ),
              _PreviewChip(
                label: 'Carbs',
                value: t.carbsG.toStringAsFixed(0),
                unit: 'g',
              ),
              _PreviewChip(
                label: 'Fat',
                value: t.fatG.toStringAsFixed(0),
                unit: 'g',
              ),
              _PreviewChip(
                label: 'Water',
                value: t.waterLiters.toStringAsFixed(1),
                unit: 'L',
              ),
              _PreviewChip(
                label: 'Steps',
                value: '${t.stepGoal}',
                unit: '',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _PreviewChip({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFB8D4C8), fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            unit.isEmpty ? value : '$value $unit',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final double min;
  final double max;
  final bool decimal;
  final VoidCallback onChanged;

  const _MetricField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.min,
    required this.max,
    required this.onChanged,
    this.decimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: (v) {
        final text = v?.trim() ?? '';
        if (text.isEmpty) return 'Required';
        final parsed = double.tryParse(text);
        if (parsed == null) return 'Invalid';
        if (parsed < min || parsed > max) {
          return '${min.toStringAsFixed(0)}-${max.toStringAsFixed(0)}';
        }
        return null;
      },
    );
  }
}

class _RadioTile<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final String title;
  final String subtitle;
  final ValueChanged<T> onChanged;

  const _RadioTile({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? const Color(0xFF00C853).withValues(alpha: 0.10)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 20,
                  color: selected
                      ? const Color(0xFF00C853)
                      : const Color(0xFFB0BEC5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5F6F72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
  );
}
