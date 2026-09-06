import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/providers/app_state.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/services/voice_coach_service.dart';
import '../../../../core/utils/pairing_link.dart';
import '../widgets/components/ai_voice_orb.dart';
import '../widgets/components/live_coach_orb.dart';
import '../widgets/screens/chat_screen.dart';
import '../widgets/screens/food_screen.dart';
import '../widgets/screens/home_dashboard.dart';
import '../widgets/screens/intelligence_screen.dart';
import '../widgets/screens/live_voice_screen.dart';
import '../widgets/screens/watch_hub_screen.dart';
import '../widgets/screens/workout_screen.dart';

/// Primary navigation. Uses a bottom bar on phones and a side rail on
/// tablets and desktop so the layout stays usable at any window size.
class AppShell extends StatefulWidget {
  final VoiceCoachService voiceService;

  const AppShell({super.key, required this.voiceService});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = PairingLink.fromCurrentLocation() != null ? 1 : 0;

  static const _coachTabIndex = 5;
  static const _railBreakpoint = 900.0;
  static const _extendedRailBreakpoint = 1180.0;

  late final List<Widget> _pages = [
    const HomeDashboard(),
    const WatchHubScreen(),
    const IntelligenceScreen(),
    const FoodScreen(),
    const WorkoutScreen(),
    ChatScreen(voiceService: widget.voiceService),
  ];

  static const _destinations = <_Destination>[
    _Destination(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _Destination(Icons.watch_outlined, Icons.watch_rounded, 'Watch'),
    _Destination(Icons.insights_outlined, Icons.insights_rounded, 'Insights'),
    _Destination(Icons.restaurant_outlined, Icons.restaurant_rounded, 'Food'),
    _Destination(
      Icons.fitness_center_outlined,
      Icons.fitness_center_rounded,
      'Workout',
    ),
    _Destination(
      Icons.graphic_eq_outlined,
      Icons.graphic_eq_rounded,
      'Coach',
    ),
  ];

  void _openCoachTab() => setState(() => _selectedIndex = _coachTabIndex);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final width = MediaQuery.sizeOf(context).width;
        final useRail = width >= _railBreakpoint;

        final body = Stack(
          children: [
            IndexedStack(index: _selectedIndex, children: _pages),
            if (_selectedIndex != _coachTabIndex)
              FloatingCoachOrb(
                message: state.coachMessage,
                anchorAboveNavBar: !useRail,
                onOpenTranscript: _openCoachTab,
              ),
          ],
        );

        if (useRail) {
          return Scaffold(
            body: Row(
              children: [
                _Rail(
                  selectedIndex: _selectedIndex,
                  extended: width >= _extendedRailBreakpoint,
                  destinations: _destinations,
                  onSelected: (i) => setState(() => _selectedIndex = i),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          body: body,
          bottomNavigationBar: _BottomBar(
            selectedIndex: _selectedIndex,
            destinations: _destinations,
            alertCount: AppServices.intelligence.actionableAlertCount,
            onSelected: (i) => setState(() => _selectedIndex = i),
          ),
        );
      },
    );
  }
}

class _Destination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _Destination(this.icon, this.selectedIcon, this.label);
}

class _Rail extends StatelessWidget {
  final int selectedIndex;
  final bool extended;
  final List<_Destination> destinations;
  final ValueChanged<int> onSelected;

  const _Rail({
    required this.selectedIndex,
    required this.extended,
    required this.destinations,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      extended: extended,
      backgroundColor: Theme.of(context).navigationBarTheme.backgroundColor,
      indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.18),
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 10),
        child: LiveCoachOrb(size: extended ? 68 : 50),
      ),
      destinations: [
        for (final d in destinations)
          NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int selectedIndex;
  final List<_Destination> destinations;
  final int alertCount;
  final ValueChanged<int> onSelected;

  const _BottomBar({
    required this.selectedIndex,
    required this.destinations,
    required this.alertCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).navigationBarTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.dividerColor,
          ),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        height: 70,
        onDestinationSelected: onSelected,
        destinations: [
          for (var i = 0; i < destinations.length; i++)
            NavigationDestination(
              icon: _maybeBadge(i, Icon(destinations[i].icon)),
              selectedIcon: _maybeBadge(i, Icon(destinations[i].selectedIcon)),
              label: destinations[i].label,
            ),
        ],
      ),
    );
  }

  /// Surfaces unread health alerts on the Insights tab.
  Widget _maybeBadge(int index, Widget icon) {
    const insightsIndex = 2;
    if (index != insightsIndex || alertCount == 0) return icon;
    return Badge(
      label: Text('$alertCount'),
      backgroundColor: const Color(0xFFFF5252),
      child: icon,
    );
  }
}

/// Always-available voice coach. Tapping opens the live conversation; the
/// orb itself shows whether the coach is listening, thinking, or speaking.
class FloatingCoachOrb extends StatefulWidget {
  final String message;
  final bool anchorAboveNavBar;
  final VoidCallback onOpenTranscript;

  const FloatingCoachOrb({
    super.key,
    this.message = '',
    this.anchorAboveNavBar = true,
    required this.onOpenTranscript,
  });

  @override
  State<FloatingCoachOrb> createState() => _FloatingCoachOrbState();
}

class _FloatingCoachOrbState extends State<FloatingCoachOrb> {
  bool _showBubble = false;
  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;
    final voice = AppServices.voice;

    return Positioned(
      right: 16,
      bottom: widget.anchorAboveNavBar ? 88 + bottomInset : 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showBubble && widget.message.isNotEmpty && !_minimized)
            Container(
              constraints: BoxConstraints(maxWidth: size.width * 0.72),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.inverseSurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                widget.message,
                style: TextStyle(
                  color: scheme.onInverseSurface,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          Material(
            color: Colors.transparent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_minimized) ...[
                  _CoachChip(
                    icon: Icons.forum_outlined,
                    tooltip: 'Open transcript',
                    onTap: widget.onOpenTranscript,
                  ),
                  _CoachChip(
                    icon: Icons.chat_bubble_outline_rounded,
                    tooltip: 'Last coach message',
                    onTap: () => setState(() => _showBubble = !_showBubble),
                  ),
                ],
                _CoachChip(
                  icon: _minimized
                      ? Icons.expand_less_rounded
                      : Icons.remove_rounded,
                  tooltip: _minimized ? 'Show coach' : 'Minimize',
                  onTap: () => setState(() => _minimized = !_minimized),
                ),
                const SizedBox(width: 4),
                ListenableBuilder(
                  listenable: voice,
                  builder: (context, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: AiVoiceOrb(
                          size: _minimized ? 52 : 70,
                          state: voice.state,
                          amplitude: voice.amplitude,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LiveVoiceScreen(),
                            ),
                          ),
                        ),
                      ),
                      if (!_minimized && voice.state != VoiceOrbState.idle)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            voice.state.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachChip extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CoachChip({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: isDark ? AppTheme.darkCard : Colors.white,
        shape: const CircleBorder(),
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}
