import 'package:flutter/material.dart';

import '../../core/services/app_services.dart';
import '../shared/app_ui.dart';

/// Product-level data permission center (§107).
/// OS permission prompts still happen when sensors are actually used.
class PermissionCenterScreen extends StatefulWidget {
  const PermissionCenterScreen({super.key});

  @override
  State<PermissionCenterScreen> createState() => _PermissionCenterScreenState();
}

class _PermissionCenterScreenState extends State<PermissionCenterScreen> {
  late bool steps;
  late bool walking;
  late bool running;
  late bool cycling;
  late bool heartRate;
  late bool sleep;
  late bool hrv;
  late bool gps;
  late bool food;

  @override
  void initState() {
    super.initState();
    final p = AppServices.prefs;
    steps = p.dataPerm('steps');
    walking = p.dataPerm('walking');
    running = p.dataPerm('running');
    cycling = p.dataPerm('cycling', fallback: false);
    heartRate = p.dataPerm('heart_rate');
    sleep = p.dataPerm('sleep');
    hrv = p.dataPerm('hrv', fallback: false);
    gps = p.dataPerm('gps', fallback: false);
    food = p.dataPerm('food');
  }

  Future<void> _set(String key, bool value, void Function(bool) local) async {
    local(value);
    await AppServices.prefs.setDataPerm(key, value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFL BOT data permissions')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text(
            'Choose what NFL BOT may use. You can change this anytime. '
            'Turning a toggle off keeps historical logs you already saved.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SectionLabel('Activity'),
          AppCard(
            child: Column(
              children: [
                _sw('Steps', steps, (v) => _set('steps', v, (x) => steps = x)),
                _sw('Walking', walking,
                    (v) => _set('walking', v, (x) => walking = x)),
                _sw('Running', running,
                    (v) => _set('running', v, (x) => running = x)),
                _sw('Cycling', cycling,
                    (v) => _set('cycling', v, (x) => cycling = x)),
              ],
            ),
          ),
          SectionLabel('Health'),
          AppCard(
            child: Column(
              children: [
                _sw('Heart rate', heartRate,
                    (v) => _set('heart_rate', v, (x) => heartRate = x)),
                _sw('Sleep', sleep, (v) => _set('sleep', v, (x) => sleep = x)),
                _sw('HRV', hrv, (v) => _set('hrv', v, (x) => hrv = x)),
              ],
            ),
          ),
          SectionLabel('Location'),
          AppCard(
            child: _sw('GPS', gps, (v) => _set('gps', v, (x) => gps = x)),
          ),
          SectionLabel('Nutrition'),
          AppCard(
            child: _sw(
                'Food data', food, (v) => _set('food', v, (x) => food = x)),
          ),
          SectionLabel('AI memory'),
          AppCard(
            child: SettingTile(
              icon: Icons.psychology_alt_outlined,
              title: 'Reset personalization',
              subtitle: 'Clears food dislikes, allergies memory, and training window prefs',
              onTap: () async {
                AppServices.health.memory.reset();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI personalization reset')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sw(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}
