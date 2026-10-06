import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_theme.dart';
import '../../core/models/coach_persona.dart';
import '../account/account_screen.dart';
import '../activity/map_track_screen.dart';
import '../coach/coach_hub_screen.dart';
import '../home/fuel_home_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../plate/plate_screen.dart';
import '../progress/progress_hub_screen.dart';
import '../home/presentation/widgets/components/ai_voice_orb.dart';
import '../live/coach_mark.dart';
import '../shared/nf_design.dart';
import '../train/train_screen.dart';
import '../train/workout_anatomy_screen.dart';
import '../wellness/body_coach_screen.dart';
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
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
            child: CoachMark(
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
            child: CoachMark(
              size: 28,
              showGlow: false,
              state: VoiceOrbState.speaking,
              pulse: 0.4,
            ),
          ),
          label: 'Coach',
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.labBg,
      body: NfAmbientBackdrop(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(pad, 8, pad, 40),
            children: [
              Text(
                'You',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppTheme.labInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Health, training, and account.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              const NfSectionLabel('Coach'),
              NfGroup(
                children: [
                  NfListRow(
                    icon: Icons.favorite_outline_rounded,
                    title: 'Body Coach',
                    subtitle: 'Goals, meals, and gym from your food',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BodyCoachScreen(),
                      ),
                    ),
                  ),
                  NfListRow(
                    icon: Icons.monitor_heart_outlined,
                    title: 'Readiness',
                    subtitle: 'Sleep · water · steps',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReadinessScreen(),
                      ),
                    ),
                  ),
                  NfListRow(
                    icon: Icons.mood_outlined,
                    title: 'Mood check-in',
                    subtitle: 'Tell Bot how you feel',
                    onTap: () => MoodCheckSheet.show(context),
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const NfSectionLabel('Training'),
              NfGroup(
                children: [
                  NfListRow(
                    icon: Icons.fitness_center_rounded,
                    title: 'Train',
                    subtitle: 'Workouts when you are ready',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TrainScreen()),
                    ),
                  ),
                  NfListRow(
                    icon: Icons.accessibility_new_rounded,
                    title: 'Form demos',
                    subtitle: 'Anatomy workout guides',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkoutAnatomyScreen(),
                      ),
                    ),
                  ),
                  NfListRow(
                    icon: Icons.map_outlined,
                    title: 'Map & steps',
                    subtitle: 'GPS route and step tracking',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MapTrackScreen(),
                      ),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const NfSectionLabel('Body'),
              NfGroup(
                children: [
                  NfListRow(
                    icon: Icons.water_drop_outlined,
                    title: 'Water',
                    subtitle: 'Daily hydration',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WaterScreen()),
                    ),
                  ),
                  NfListRow(
                    icon: Icons.monitor_weight_outlined,
                    title: 'Progress',
                    subtitle: 'Body check-ins',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProgressScreen(),
                      ),
                    ),
                  ),
                  NfListRow(
                    icon: Icons.photo_library_outlined,
                    title: 'Progress photos',
                    subtitle: 'Check-in timeline',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProgressPhotosScreen(),
                      ),
                    ),
                  ),
                  NfListRow(
                    icon: Icons.insights_outlined,
                    title: 'Weekly recap',
                    subtitle: 'Calories and streak overview',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WeeklyRecapScreen(),
                      ),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const NfSectionLabel('Settings'),
              NfGroup(
                children: [
                  NfListRow(
                    icon: Icons.notifications_active_outlined,
                    title: 'Reminders',
                    subtitle: 'Water, meals, quiet hours',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RemindersScreen(),
                      ),
                    ),
                  ),
                  NfListRow(
                    icon: Icons.settings_outlined,
                    title: 'Account',
                    subtitle: 'Preferences and privacy',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountScreen(),
                      ),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Wake Bot anytime with “${CoachPersona.wakePhrase}”. '
                'Bot never invents numbers — only your logs count.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
