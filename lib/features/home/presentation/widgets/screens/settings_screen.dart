import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../config/app_config.dart';
import '../../../../../core/models/coach_context.dart';
import '../../../../../core/models/coach_persona.dart';
import '../../../../../core/models/user_profile.dart';
import '../../../../../core/providers/app_state.dart';
import '../../../../../core/services/app_services.dart';
import 'data_export_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _nameCtrl.text = state.userName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              const Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              _SectionTitle('Body Profile'),
              _ProfileSummaryCard(
                profile: state.profile,
                onEdit: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle('AI Voice Trainer'),
              _VoiceSelector(
                current: state.coachVoice,
                onSelect: (v) => state.setCoachVoice(v),
              ),
              _SwitchTile(
                title: 'Voice coach',
                subtitle: 'Speak to your trainer & hear replies',
                value: state.voiceEnabled,
                onChanged: (v) async {
                  state.setVoiceEnabled(v);
                  await AppServices.prefs.setVoiceEnabled(v);
                },
              ),
              const SizedBox(height: 16),
              _SectionTitle('AI Model Connection'),
              _AiConnectionCard(
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 16),
              _SectionTitle('Training Intelligence'),
              _MissedSessionsTile(
                current: AppServices.storage.missedSessions,
                onChanged: (count) async {
                  await AppServices.intelligence.setMissedSessions(count);
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 16),
              _SectionTitle('Security & Privacy'),
              _SwitchTile(
                title: 'Biometric lock',
                subtitle: 'Fingerprint / Face ID to open app',
                value: state.biometricEnabled,
                onChanged: (v) async {
                  if (v) {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await AppServices.security.authenticate(
                      reason: 'Enable biometric lock',
                    );
                    if (!ok) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Biometric authentication failed')),
                      );
                      return;
                    }
                  }
                  state.setBiometricEnabled(v);
                  await AppServices.prefs.setBiometricEnabled(v);
                },
              ),
              _SwitchTile(
                title: 'Dark mode',
                subtitle: 'Easier on eyes at night',
                value: state.darkMode,
                onChanged: (v) async {
                  state.setDarkMode(v);
                  await AppServices.prefs.setDarkMode(v);
                },
              ),
              const SizedBox(height: 16),
              _SectionTitle('Account'),
              _TextFieldTile(
                controller: _nameCtrl,
                label: 'Display name',
                onSave: () async {
                  state.setUserName(_nameCtrl.text);
                  await AppServices.prefs.setUserName(_nameCtrl.text);
                },
              ),
              _ActionTile(
                icon: Icons.download_rounded,
                title: 'Export or erase your data',
                subtitle: 'Take your health history with you as JSON or CSV',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DataExportScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _Tile(title: 'App version', value: AppConfig.appVersion),
            ],
          ),
        );
      },
    );
  }
}

/// Lets the user attach their own Claude or OpenAI key so the coach answers
/// from a real model. Keys live in secure storage and never leave the device
/// except in the request to the chosen provider.
class _AiConnectionCard extends StatefulWidget {
  final VoidCallback onChanged;
  const _AiConnectionCard({required this.onChanged});

  @override
  State<_AiConnectionCard> createState() => _AiConnectionCardState();
}

class _AiConnectionCardState extends State<_AiConnectionCard> {
  final _keyCtrl = TextEditingController();
  AiProvider _provider = AiProvider.anthropic;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final current = AppServices.coach.provider;
    if (current != AiProvider.offline) _provider = current;
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _keyCtrl.text.trim();
    if (key.isEmpty) return;

    setState(() => _saving = true);
    await AppServices.coach.configure(provider: _provider, apiKey: key);
    if (!mounted) return;

    _keyCtrl.clear();
    setState(() => _saving = false);
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live AI coach connected'),
        backgroundColor: Color(0xFF00C853),
      ),
    );
  }

  Future<void> _disconnect() async {
    await AppServices.coach.clearCredentials();
    if (!mounted) return;
    setState(() {});
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Switched to the on-device coach')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connected = AppServices.coach.isModelBacked;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                connected
                    ? Icons.auto_awesome_rounded
                    : Icons.offline_bolt_rounded,
                size: 18,
                color: connected
                    ? const Color(0xFF00C853)
                    : const Color(0xFF8A9490),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  connected
                      ? 'Live coach active via ${AppServices.coach.provider.name}'
                      : 'Running on on-device knowledge',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your own API key to get full conversational coaching. Without '
            'a key the app still answers from built-in knowledge using your '
            'live numbers.',
            style: TextStyle(fontSize: 12, color: Color(0xFF5F6F72), height: 1.4),
          ),
          const SizedBox(height: 12),
          SegmentedButton<AiProvider>(
            segments: const [
              ButtonSegment(
                value: AiProvider.anthropic,
                label: Text('Claude'),
                icon: Icon(Icons.psychology_rounded, size: 16),
              ),
              ButtonSegment(
                value: AiProvider.openai,
                label: Text('OpenAI'),
                icon: Icon(Icons.blur_on_rounded, size: 16),
              ),
            ],
            selected: {_provider},
            onSelectionChanged: (s) => setState(() => _provider = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyCtrl,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: connected ? 'Replace API key' : 'API key',
              hintText: _provider == AiProvider.anthropic ? 'sk-ant-…' : 'sk-…',
              prefixIcon: const Icon(Icons.key_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (connected)
                TextButton(
                  onPressed: _disconnect,
                  child: const Text('Disconnect'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(connected ? 'Update key' : 'Connect'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shows the metrics driving every target, or prompts for them when the
/// profile has never been filled in.
class _ProfileSummaryCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEdit;

  const _ProfileSummaryCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    if (!profile.isComplete) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFD9A8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add your body metrics',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Until then the app uses generic defaults. Height, weight, age, '
              'sex and activity level produce real calorie and macro targets.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Set up profile'),
              ),
            ),
          ],
        ),
      );
    }

    final t = profile.targets;
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your metrics',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF5F6F72),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${profile.sex.label} · ${profile.age} yrs · '
                '${profile.heightCm.toStringAsFixed(0)} cm · '
                '${profile.weightKg.toStringAsFixed(1)} kg',
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                '${profile.activity.label} · ${profile.goal.label}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF5F6F72),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Targets: ${t.calories} kcal · '
                '${t.proteinG.toStringAsFixed(0)}g protein · '
                '${t.waterLiters.toStringAsFixed(1)}L water · '
                '${t.stepGoal} steps',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00A045),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissedSessionsTile extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;
  const _MissedSessionsTile({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Missed sessions this week',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2),
                Text(
                  'The plan reschedules rather than stacking them.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5F6F72)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: current > 0 ? () => onChanged(current - 1) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Text(
            '$current',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          IconButton(
            onPressed: current < 7 ? () => onChanged(current + 1) : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
  );
}

class _VoiceSelector extends StatelessWidget {
  final CoachVoice current;
  final ValueChanged<CoachVoice> onSelect;
  const _VoiceSelector({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final persona in CoachPersona.all) ...[
          if (persona != CoachPersona.all.first) const SizedBox(width: 10),
          Expanded(
            child: _VoiceChip(
              label: persona.name,
              subtitle: persona.tagline,
              selected: current == persona.voice,
              onTap: () => onSelect(persona.voice),
            ),
          ),
        ],
      ],
    );
  }
}

class _VoiceChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _VoiceChip({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFF2F6BFF)
          : Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Icon(
                Icons.graphic_eq_rounded,
                color: selected ? Colors.white : const Color(0xFF5F6F72),
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  color: selected ? Colors.white : const Color(0xFF5F6F72),
                ),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? Colors.white70 : const Color(0xFF8A9490),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _SwitchTile({required this.title, required this.subtitle, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        activeThumbColor: const Color(0xFF00C853),
        onChanged: onChanged,
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String title, value;
  const _Tile({required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      Text(value, style: const TextStyle(color: Color(0xFF5F6F72))),
    ]),
  );
}

class _TextFieldTile extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback onSave;
  const _TextFieldTile({required this.controller, required this.label, required this.onSave});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      Expanded(child: TextField(controller: controller, decoration: InputDecoration(labelText: label))),
      IconButton(onPressed: onSave, icon: const Icon(Icons.check_rounded, color: Color(0xFF00C853))),
    ]),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF1A1A2E),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(icon, color: const Color(0xFF00E676)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            Text(subtitle, style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 13)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70),
        ]),
      ),
    ),
  );
}
