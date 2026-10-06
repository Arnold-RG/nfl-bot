import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/data/world_countries.dart';
import '../../core/data/world_languages.dart';
import '../../core/models/user_profile.dart';
import '../../core/providers/app_state.dart';
import '../../core/services/app_services.dart';
import '../home/presentation/widgets/components/ai_voice_orb.dart';
import '../live/coach_mark.dart';
import '../shared/nf_design.dart';

/// First-run setup — calm, short steps, new coach mark.
class WelcomeFlow extends StatefulWidget {
  final VoidCallback onComplete;
  const WelcomeFlow({super.key, required this.onComplete});

  @override
  State<WelcomeFlow> createState() => _WelcomeFlowState();
}

class _WelcomeFlowState extends State<WelcomeFlow> {
  static const _totalSteps = 7;

  int _step = 0;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _age = TextEditingController(text: '30');
  final _height = TextEditingController(text: '175');
  final _weight = TextEditingController(text: '75');
  BiologicalSex _sex = BiologicalSex.male;
  ActivityLevel _activity = ActivityLevel.moderate;
  FitnessGoal _goal = FitnessGoal.maintain;
  String _experience = 'intermediate';
  int _daysPerWeek = 3;
  String _equipment = 'home';
  final Set<String> _dietPrefs = {};

  static const _dietOptions = [
    'High protein',
    'Vegetarian',
    'Vegan',
    'Low carb',
    'Halal',
    'Gluten free',
    'No preference',
  ];

  @override
  void initState() {
    super.initState();
    AppServices.locale.suggestFromDevice();
    _name.text =
        AppServices.prefs.userName == 'Alex' ? '' : AppServices.prefs.userName;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final state = context.read<AppState>();
    state.setUserName(
      _name.text.trim().isEmpty ? 'Athlete' : _name.text.trim(),
    );
    await AppServices.prefs.setUserName(state.userName);
    await AppServices.prefs.setEmail(_email.text.trim());
    await state.setEquipmentProfile(_equipment);
    await state.setTrainingExperience(_experience);
    await state.setTrainingFrequency(_daysPerWeek);
    await state.saveProfile(
      UserProfile(
        sex: _sex,
        age: int.tryParse(_age.text) ?? 30,
        heightCm: double.tryParse(_height.text) ?? 175,
        weightKg: double.tryParse(_weight.text) ?? 75,
        activity: _activity,
        goal: _goal,
      ),
    );
    await AppServices.voice.applyLanguage(AppServices.locale.speechLocale);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titles = [
      'Meet your coach',
      'You',
      'Body basics',
      'Your goal',
      'Training',
      'Food prefs',
      'Ready',
    ];
    final subs = [
      'NFL BOT coaches from your real logs — never invented numbers.',
      'Name and where you train from.',
      'These set calories and protein so coaching is not a guess.',
      'What are you working toward this season?',
      'Experience, days, and equipment shape your plan.',
      'Optional filters for meal suggestions.',
      kIsWeb
          ? 'Health platforms on web are labeled only — native apps sync HealthKit / Health Connect.'
          : 'Link health data later from Account when you are ready.',
    ];

    return Scaffold(
      backgroundColor: AppTheme.labBg,
      body: NfAmbientBackdrop(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              NfLayout.pagePad(context),
              12,
              NfLayout.pagePad(context),
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CoachMark(
                      size: 44,
                      showGlow: false,
                      state: VoiceOrbState.idle,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'NFL BOT',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.labInk,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_step + 1} / $_totalSteps',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / _totalSteps,
                    minHeight: 3,
                    backgroundColor: AppTheme.labBorder,
                    color: AppTheme.bronze,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  titles[_step],
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppTheme.labInk,
                  ),
                ),
                const SizedBox(height: 8),
                Text(subs[_step], style: theme.textTheme.bodyMedium),
                const SizedBox(height: 18),
                Expanded(child: _stepBody()),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_step > 0)
                      TextButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text('Back'),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        if (_step < _totalSteps - 1) {
                          setState(() => _step++);
                        } else {
                          _finish();
                        }
                      },
                      child: Text(
                        _step < _totalSteps - 1 ? 'Continue' : 'Start coaching',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepBody() {
    return switch (_step) {
      0 => _hello(),
      1 => _place(),
      2 => _body(),
      3 => _goalStep(),
      4 => _trainingStep(),
      5 => _dietStep(),
      _ => _readyStep(),
    };
  }

  Widget _panel(Widget child) => NfGlassCard(child: child);

  Widget _hello() {
    return ListView(
      children: [
        _panel(
          Column(
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'What should the coach call you?',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email (optional)'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _place() {
    final locale = AppServices.locale;
    return ListView(
      children: [
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: locale.country.iso2,
                decoration: const InputDecoration(labelText: 'Country'),
                items: [
                  for (final c in WorldCountries.all)
                    DropdownMenuItem(
                      value: c.iso2,
                      child: Text('${c.name} · ${c.currencyCode}'),
                    ),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  await locale.applyCountry(v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: locale.language.code,
                decoration: const InputDecoration(labelText: 'Language'),
                items: [
                  for (final l in WorldLanguages.all)
                    DropdownMenuItem(value: l.code, child: Text(l.label)),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  await locale.setLanguage(v);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _body() {
    return ListView(
      children: [
        _panel(
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _age,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _height,
                      decoration: const InputDecoration(labelText: 'Height cm'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _weight,
                      decoration: const InputDecoration(labelText: 'Weight kg'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<BiologicalSex>(
                initialValue: _sex,
                decoration: const InputDecoration(labelText: 'Sex'),
                items: [
                  for (final s in BiologicalSex.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (v) => setState(() => _sex = v ?? _sex),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ActivityLevel>(
                initialValue: _activity,
                decoration: const InputDecoration(labelText: 'Daily activity'),
                items: [
                  for (final a in ActivityLevel.values)
                    DropdownMenuItem(value: a, child: Text(a.label)),
                ],
                onChanged: (v) => setState(() => _activity = v ?? _activity),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chipWrap(List<Widget> children) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: children,
      );

  Widget _goalStep() {
    return ListView(
      children: [
        _chipWrap([
          for (final g in FitnessGoal.values)
            ChoiceChip(
              label: Text(g.label),
              selected: _goal == g,
              onSelected: (_) => setState(() => _goal = g),
            ),
        ]),
      ],
    );
  }

  Widget _trainingStep() {
    return ListView(
      children: [
        Text('Experience', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        _chipWrap([
          for (final e in ['beginner', 'intermediate', 'advanced'])
            ChoiceChip(
              label: Text(e[0].toUpperCase() + e.substring(1)),
              selected: _experience == e,
              onSelected: (_) => setState(() => _experience = e),
            ),
        ]),
        const SizedBox(height: 18),
        Text('Days per week', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        _chipWrap([
          for (final d in [2, 3, 4, 5, 6])
            ChoiceChip(
              label: Text('$d'),
              selected: _daysPerWeek == d,
              onSelected: (_) => setState(() => _daysPerWeek = d),
            ),
        ]),
        const SizedBox(height: 18),
        Text('Equipment', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        _chipWrap([
          ChoiceChip(
            label: const Text('Home'),
            selected: _equipment == 'home',
            onSelected: (_) => setState(() => _equipment = 'home'),
          ),
          ChoiceChip(
            label: const Text('Gym'),
            selected: _equipment == 'gym',
            onSelected: (_) => setState(() => _equipment = 'gym'),
          ),
        ]),
      ],
    );
  }

  Widget _dietStep() {
    return ListView(
      children: [
        _chipWrap([
          for (final d in _dietOptions)
            FilterChip(
              label: Text(d),
              selected: _dietPrefs.contains(d),
              onSelected: (on) {
                setState(() {
                  if (on) {
                    if (d == 'No preference') {
                      _dietPrefs
                        ..clear()
                        ..add(d);
                    } else {
                      _dietPrefs.remove('No preference');
                      _dietPrefs.add(d);
                    }
                  } else {
                    _dietPrefs.remove(d);
                  }
                });
              },
            ),
        ]),
      ],
    );
  }

  Widget _readyStep() {
    return ListView(
      children: [
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CoachMark(size: 72, state: VoiceOrbState.listening),
              const SizedBox(height: 16),
              Text(
                'You’re set.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.labInk,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                kIsWeb
                    ? 'On web, health connections are informational. Use iOS/Android for HealthKit or Health Connect.'
                    : 'Link Apple Health or Health Connect anytime from Account → Connected devices.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Say “hey bot” for food, training, water, and recovery — always from your logs.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.bronzeSoft,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
