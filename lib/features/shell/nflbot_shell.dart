import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_theme.dart';
import '../../core/models/coach_persona.dart';
import '../account/account_screen.dart';
import '../activity/map_track_screen.dart';
import '../coach/coach_hub_screen.dart';
import '../home/fuel_home_screen.dart';
import '../live/live_bot_character.dart';
import '../nutrition/nutrition_screen.dart';
import '../plate/plate_screen.dart';
import '../progress/progress_hub_screen.dart';
import '../home/presentation/widgets/components/ai_voice_orb.dart';
import '../shared/nf_design.dart';
import '../train/train_screen.dart';
import '../train/workout_anatomy_screen.dart';
import '../wellness/extras_screens.dart';
import '../wellness/progress_photos_screen.dart';
import '../wellness/water_screen.dart';

/// Adaptive shell: Today · Diary · Add · Bot · You
class NflBotShell extends StatefulWidget {
  const NflBotShell({super.key});

  @override
  State<NflBotShell> createState() => _NflBotShellState();
}

class _NflBotShellState extends State<NflBotShell> {
  int _index = 0;

  int get _navIndex {
    if (_index <= 1) return _index;
    if (_index == 2) return 3;
    return 4;
  }

  void _selectNav(int i) {
    HapticFeedback.selectionClick();
    if (i == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PlateScreen()),
      );
      return;
    }
    setState(() {
      if (i <= 1) {
        _index = i;
      } else if (i == 3) {
        _index = 2;
      } else {
        _index = 3;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = NfLayout.isWide(context);
    final pages = [
      FuelHomeScreen(
        onOpenDiary: () => setState(() => _index = 1),
        onOpenBody: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProgressScreen()),
          );
        },
        onOpenBot: () => setState(() => _index = 2),
      ),
      const NutritionScreen(),
      const CoachHubScreen(),
      const _YouHub(),
    ];

    final nav = NavigationBar(
      selectedIndex: _navIndex,
      onDestinationSelected: _selectNav,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Today',
        ),
        const NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded),
          label: 'Diary',
        ),
        const NavigationDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle),
          label: 'Add',
        ),
        NavigationDestination(
          icon: SizedBox(
            width: 28,
            height: 28,
            child: LiveBotCharacter(
              size: 26,
              showGlow: false,
              state: _navIndex == 3
                  ? VoiceOrbState.listening
                  : VoiceOrbState.idle,
            ),
          ),
          selectedIcon: SizedBox(
            width: 30,
            height: 30,
            child: LiveBotCharacter(
              size: 28,
              showGlow: false,
              state: VoiceOrbState.speaking,
              pulse: 0.4,
            ),
          ),
          label: 'Bot',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'You',
        ),
      ],
    );

    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        backgroundColor: AppTheme.labBg,
        body: wide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: switch (_navIndex) {
                      0 => 0,
                      1 => 1,
                      3 => 2,
                      _ => 3,
                    },
                    onDestinationSelected: (i) {
                      final map = [0, 1, 3, 4];
                      _selectNav(map[i.clamp(0, 3)]);
                    },
                    backgroundColor: AppTheme.labLift,
                    indicatorColor: AppTheme.bronze.withValues(alpha: 0.2),
                    labelType: NavigationRailLabelType.all,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: Text('Today'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.menu_book_outlined),
                        selectedIcon: Icon(Icons.menu_book_rounded),
                        label: Text('Diary'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.smart_toy_outlined),
                        selectedIcon: Icon(Icons.smart_toy_rounded),
                        label: Text('Bot'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person_rounded),
                        label: Text('You'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1, color: AppTheme.labBorder),
                  Expanded(
                    child: IndexedStack(index: _index, children: pages),
                  ),
                ],
              )
            : IndexedStack(index: _index, children: pages),
        bottomNavigationBar: wide ? null : nav,
        floatingActionButton: wide
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PlateScreen()),
                  );
                },
                backgroundColor: AppTheme.bronze,
                foregroundColor: AppTheme.labBg,
                icon: const Icon(Icons.add),
                label: const Text('Scan meal'),
              )
            : null,
      ),
    );
  }
}

class _YouHub extends StatelessWidget {
  const _YouHub();

  @override
  Widget build(BuildContext context) {
    final pad = NfLayout.pagePad(context);
    return Scaffold(
      backgroundColor: AppTheme.labBg,
      body: NfAmbientBackdrop(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 40),
            children: [
              Text(
                'You',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.labInk,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Account, vitals, training, and Bot.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _tile(
                context,
                Icons.settings_outlined,
                'Account',
                'Preferences & privacy',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                ),
              ),
              _tile(
                context,
                Icons.monitor_heart_outlined,
                'Readiness',
                'Sleep · water · steps score',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReadinessScreen()),
                ),
              ),
              _tile(
                context,
                Icons.mood_outlined,
                'Mood check-in',
                'Tell Bot how you feel',
                () => MoodCheckSheet.show(context),
              ),
              _tile(
                context,
                Icons.notifications_active_outlined,
                'Reminders',
                'Water, meals, quiet hours',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RemindersScreen()),
                ),
              ),
              _tile(
                context,
                Icons.photo_library_outlined,
                'Progress photos',
                'Check-in timeline',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProgressPhotosScreen(),
                  ),
                ),
              ),
              _tile(
                context,
                Icons.insights_outlined,
                'Weekly recap',
                'Calories & streak overview',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WeeklyRecapScreen()),
                ),
              ),
              _tile(
                context,
                Icons.water_drop_rounded,
                'Water',
                'Daily and workout hydration',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WaterScreen()),
                ),
              ),
              _tile(
                context,
                Icons.map_rounded,
                'Map & steps',
                'GPS route + step tracking',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapTrackScreen()),
                ),
              ),
              _tile(
                context,
                Icons.fitness_center_rounded,
                'Train',
                'Workouts when you are ready',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrainScreen()),
                ),
              ),
              _tile(
                context,
                Icons.accessibility_new_rounded,
                'Form demos',
                'Human anatomy workout guides',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WorkoutAnatomyScreen(),
                  ),
                ),
              ),
              _tile(
                context,
                Icons.monitor_weight_outlined,
                'Body',
                'Check-ins stay empty until you add them',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProgressScreen()),
                ),
              ),
              const SizedBox(height: 12),
              NfGlassCard(
                child: Text(
                  'Wake Bot anytime by saying “${CoachPersona.wakePhrase}”. '
                  'Bot never invents your numbers — only your logs count.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.labInk,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NfGlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.bronze.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.bronzeSoft),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.labMuted),
          ],
        ),
      ),
    );
  }
}
