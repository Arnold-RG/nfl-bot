import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../core/services/app_services.dart';
import '../home/presentation/widgets/components/ai_voice_orb.dart';
import '../live/coach_mark.dart';
import '../shared/nf_design.dart';

/// Opening beat — brand + new coach mark.
class PulseSplash extends StatefulWidget {
  final VoidCallback onFinished;
  const PulseSplash({super.key, required this.onFinished});

  @override
  State<PulseSplash> createState() => _PulseSplashState();
}

class _PulseSplashState extends State<PulseSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _go();
  }

  Future<void> _go() async {
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 1800)),
      AppServices.permissions.requestEssentialPermissions(),
    ]);
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.labBg,
      body: NfAmbientBackdrop(
        child: Center(
          child: AnimatedBuilder(
            animation: _intro,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(_intro.value.clamp(0, 1));
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CoachMark(
                        size: 128,
                        state: VoiceOrbState.listening,
                        pulse: 0.2 * t,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'NFL BOT',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: AppTheme.labInk,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your AI health coach',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Say “hey bot” anytime',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 36),
                      SizedBox(
                        width: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            backgroundColor: AppTheme.labBorder,
                            color: AppTheme.bronze,
                            value: t < 1 ? null : 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
