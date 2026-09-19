import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/models/coach_persona.dart';
import '../../core/models/user_profile.dart';
import '../../core/providers/app_state.dart';
import '../../core/services/app_services.dart';
import '../shared/nf_design.dart';
import '../watch/watch_connect_screen.dart';
import 'permission_center_screen.dart';

/// Professional Account — rebuilt from scratch.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: AppServices.prefs.userName);
    _email = TextEditingController(text: AppServices.prefs.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    context.read<AppState>().setUserName(_name.text.trim());
    await AppServices.prefs.setUserName(_name.text.trim());
    await AppServices.prefs.setEmail(_email.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pad = NfLayout.pagePad(context);
    final initials = _initials(_name.text.isEmpty ? state.userName : _name.text);

    return Scaffold(
      backgroundColor: AppTheme.labBg,
      body: NfAmbientBackdrop(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                pinned: true,
                title: Text(
                  'Account',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Profile hero
                    NfGlassCard(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppTheme.bronzeSoft, AppTheme.bronzeDeep],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.bronze.withValues(alpha: 0.35),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.labBg,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _name.text.trim().isEmpty
                                ? 'Your profile'
                                : _name.text.trim(),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Say “hey bot” anytime',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel('Profile'),
                    NfGlassCard(
                      child: Column(
                        children: [
                          TextField(
                            controller: _name,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Display name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              onPressed: _saving ? null : _save,
                              child: Text(_saving ? 'Saving…' : 'Save profile'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel('Coach'),
                    NfGlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: state.voiceEnabled,
                            activeThumbColor: AppTheme.labBg,
                            activeTrackColor: AppTheme.bronze,
                            secondary: const Icon(Icons.record_voice_over_outlined,
                                color: AppTheme.bronze),
                            title: const Text('Bot voice replies'),
                            subtitle: const Text('Speak answers out loud'),
                            onChanged: (v) async {
                              state.setVoiceEnabled(v);
                              await AppServices.prefs.setVoiceEnabled(v);
                            },
                          ),
                          const Divider(height: 1, color: AppTheme.labBorder),
                          SwitchListTile(
                            value: AppServices.prefs.handsFree,
                            activeThumbColor: AppTheme.labBg,
                            activeTrackColor: AppTheme.bronze,
                            secondary: const Icon(Icons.hearing_outlined,
                                color: AppTheme.bronze),
                            title: const Text('Hands-free'),
                            subtitle: const Text('Listen again after each reply'),
                            onChanged: (v) async {
                              await AppServices.prefs.setHandsFree(v);
                              setState(() {});
                            },
                          ),
                          const Divider(height: 1, color: AppTheme.labBorder),
                          SwitchListTile(
                            value: state.quietHours,
                            activeThumbColor: AppTheme.labBg,
                            activeTrackColor: AppTheme.bronze,
                            secondary: const Icon(Icons.bedtime_outlined,
                                color: AppTheme.bronze),
                            title: const Text('Quiet hours'),
                            subtitle: Text(
                              state.isInQuietHours
                                  ? 'Active now — Bot won’t initiate'
                                  : 'Bot won’t initiate after 21:00',
                            ),
                            onChanged: state.setQuietHours,
                          ),
                          const Divider(height: 1, color: AppTheme.labBorder),
                          _RowTile(
                            icon: Icons.record_voice_over,
                            title: 'Coach voice',
                            value: state.coach.name,
                            onTap: () => _pickCoachVoice(state),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel('Goals'),
                    NfGlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _RowTile(
                            icon: Icons.flag_outlined,
                            title: 'Fitness goal',
                            value: state.profile.goal.label,
                            onTap: () => _pickGoal(state),
                          ),
                          const Divider(height: 1, color: AppTheme.labBorder),
                          _RowTile(
                            icon: Icons.fitness_center_outlined,
                            title: 'Training',
                            value:
                                '${state.trainingFrequency}d · ${state.trainingExperience}',
                            onTap: () => _pickTraining(state),
                          ),
                          const Divider(height: 1, color: AppTheme.labBorder),
                          _RowTile(
                            icon: Icons.home_work_outlined,
                            title: 'Equipment',
                            value: state.equipmentProfile == 'gym'
                                ? 'Gym'
                                : 'Home',
                            onTap: () => state.setEquipmentProfile(
                              state.equipmentProfile == 'gym' ? 'home' : 'gym',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel('Connections'),
                    NfGlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _RowTile(
                            icon: Icons.watch_outlined,
                            title: 'Watch',
                            value: state.watchConnected
                                ? (state.watchName ?? 'Connected')
                                : 'Not linked',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  appBar: AppBar(title: const Text('Watch')),
                                  body: const WatchConnectScreen(),
                                ),
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: AppTheme.labBorder),
                          _RowTile(
                            icon: Icons.shield_outlined,
                            title: 'Permissions',
                            value: 'Camera, mic, motion, location',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PermissionCenterScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel('About'),
                    NfGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NFL BOT',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Wellness coaching only — not medical advice. '
                            'Bot uses your real logs. Version 1.0.0',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'NB';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _pickCoachVoice(AppState state) async {
    final picked = await showModalBottomSheet<CoachVoice>(
      context: context,
      backgroundColor: AppTheme.labCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text('Coach voice', style: Theme.of(ctx).textTheme.titleMedium),
            for (final persona in CoachPersona.all)
              ListTile(
                title: Text(persona.name),
                subtitle: Text(persona.tagline),
                trailing: state.coachVoice == persona.voice
                    ? const Icon(Icons.check, color: AppTheme.bronze)
                    : null,
                onTap: () => Navigator.pop(ctx, persona.voice),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) await state.setCoachVoice(picked);
  }

  Future<void> _pickGoal(AppState state) async {
    final g = await showModalBottomSheet<FitnessGoal>(
      context: context,
      backgroundColor: AppTheme.labCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text('Fitness goal',
                style: Theme.of(ctx).textTheme.titleMedium),
            for (final goal in FitnessGoal.values)
              ListTile(
                title: Text(goal.label),
                trailing: state.profile.goal == goal
                    ? const Icon(Icons.check, color: AppTheme.bronze)
                    : null,
                onTap: () => Navigator.pop(ctx, goal),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (g != null) await state.saveProfile(state.profile.copyWith(goal: g));
  }

  Future<void> _pickTraining(AppState state) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.labCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Training', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text('Days per week: ${state.trainingFrequency}'),
                Slider(
                  value: state.trainingFrequency.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  activeColor: AppTheme.bronze,
                  onChanged: (v) => state.setTrainingFrequency(v.round()),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final e in ['Beginner', 'Intermediate', 'Advanced'])
                      ChoiceChip(
                        label: Text(e),
                        selected: state.trainingExperience == e,
                        onSelected: (_) => state.setTrainingExperience(e),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.bronze,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _RowTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.bronze),
      title: Text(title),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.labMuted),
      onTap: onTap,
    );
  }
}
