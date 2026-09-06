import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/engines/activity_engine.dart';
import '../../core/providers/app_state.dart';
import '../../core/utils/pairing_link.dart';
import '../coach/coach_hub_screen.dart';
import '../home/glass_stage_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../plate/plate_screen.dart';
import '../progress/progress_hub_screen.dart';
import '../train/train_screen.dart';

/// Glass AI Stage shell — Concept C frosted dock.
///
/// Page indices: 0 Home · 1 Train · 2 Track · 3 Coach
/// Nav slot 2 is the Add action (does not switch pages).
class NflBotShell extends StatefulWidget {
  const NflBotShell({super.key});

  @override
  State<NflBotShell> createState() => _NflBotShellState();
}

class _NflBotShellState extends State<NflBotShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = PairingLink.fromCurrentLocation() != null ? 1 : 0;
  }

  int get _navIndex {
    if (_index <= 1) return _index;
    if (_index == 2) return 3;
    return 4;
  }

  void _selectNav(int i) {
    if (i == 2) {
      _openAdd();
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

  void _openFromGlass(int legacyTab) {
    // GlassStage still speaks legacy: 1 Train, 2 Nutrition, 3 Progress, 4 Coach
    switch (legacyTab) {
      case 1:
        setState(() => _index = 1);
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NutritionScreen()),
        );
      case 3:
        setState(() => _index = 2);
      case 4:
        setState(() => _index = 3);
      default:
        setState(() => _index = 0);
    }
  }

  void _openAdd() {
    final state = context.read<AppState>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12181F),
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restaurant_outlined,
                  color: AppTheme.electric),
              title: const Text('Log food',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NutritionScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_walk_rounded,
                  color: AppTheme.electric),
              title: const Text('Log walk',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                state.logActivity(
                  type: ActivityType.walk,
                  minutes: 20,
                  steps: 2200,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center_rounded,
                  color: AppTheme.gravlVolt),
              title: const Text('Start workout',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _index = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppTheme.electric),
              title: const Text('Scan meal',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlateScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      GlassStageScreen(onOpenTab: _openFromGlass),
      const TrainScreen(),
      const ProgressScreen(),
      const CoachHubScreen(),
    ];

    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFF05070D),
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: NavigationBar(
                  height: 68,
                  backgroundColor: Colors.transparent,
                  indicatorColor: AppTheme.electric.withValues(alpha: 0.22),
                  selectedIndex: _navIndex,
                  onDestinationSelected: _selectNav,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.fitness_center_outlined),
                      selectedIcon: Icon(Icons.fitness_center_rounded),
                      label: 'Train',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.add_circle_outline),
                      selectedIcon:
                          Icon(Icons.add_circle, color: AppTheme.electric),
                      label: 'Add',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.insights_outlined),
                      selectedIcon: Icon(Icons.insights_rounded),
                      label: 'Track',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.graphic_eq_outlined),
                      selectedIcon: Icon(Icons.graphic_eq_rounded),
                      label: 'Coach',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
