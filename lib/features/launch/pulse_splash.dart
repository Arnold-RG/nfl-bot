import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../core/services/app_services.dart';
import '../live/brand_mark.dart';
import '../home/presentation/widgets/components/ai_voice_orb.dart';
import '../shared/nf_design.dart';

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
      duration: const Duration(milliseconds: 900),
    )..forward();
    _go();
  }

  Future<void> _go() async {
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 1600)),
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
              final t = Curves.easeOutBack.transform(_intro.value.clamp(0, 1));
              return Opacity(
                opacity: _intro.value.clamp(0, 1),
                child: Transform.scale(
                  scale: 0.85 + t * 0.15,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const VoiceArtwork(
                        size: 140,
                        state: VoiceOrbState.listening,
                        pulse: 0.25,
                      ),
                      const SizedBox(height: 22),
                      Text('NFL BOT', style: theme.textTheme.displaySmall),
                      const SizedBox(height: 8),
                      Text(
                        'Say “hey bot” — your live AI coach.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 28),
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppTheme.bronze,
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
