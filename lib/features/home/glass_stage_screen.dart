import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/engines/body_engine.dart';
import '../../core/providers/app_state.dart';
import '../../core/services/app_services.dart';
import '../../features/home/presentation/widgets/components/ai_voice_orb.dart';
import '../account/account_screen.dart';
import '../live/brand_mark.dart';
import '../train/train_screen.dart';

/// Concept C — Glass AI Stage: frosted cards + live mic orb (exact product face).
class GlassStageScreen extends StatefulWidget {
  final ValueChanged<int>? onOpenTab;

  const GlassStageScreen({super.key, this.onOpenTab});

  @override
  State<GlassStageScreen> createState() => _GlassStageScreenState();
}

class _GlassStageScreenState extends State<GlassStageScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bg;

  @override
  void initState() {
    super.initState();
    _bg = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _bg.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    // Open the live Coach stage — mic + voice session live there.
    widget.onOpenTab?.call(4);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final day = BodyEngine.snapshot(state);
    final voice = AppServices.voice;
    final status = switch (voice.state) {
      VoiceOrbState.listening => 'Listening',
      VoiceOrbState.thinking => 'Thinking',
      VoiceOrbState.speaking => 'Speaking',
      VoiceOrbState.idle => 'Tap mic to talk',
    };
    final brief = day.coachBrief;
    final upperReady = day.muscles
            .where((m) =>
                m.name == 'Chest' ||
                m.name == 'Back' ||
                m.name == 'Shoulders' ||
                m.name == 'Arms')
            .map((m) => m.percent)
            .fold<int>(0, (a, b) => a + b) ~/
        4;
    final upperLabel = upperReady >= 70 ? 'READY' : 'RECOVERING';

    return AnimatedBuilder(
      animation: Listenable.merge([_bg, voice]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF05070D),
          body: Stack(
            children: [
              Positioned.fill(child: _Atmosphere(t: _bg.value)),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AccountScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.menu_rounded,
                                color: Colors.white70),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: Colors.white,
                                    ),
                                    children: [
                                      TextSpan(text: 'GLASS '),
                                      TextSpan(
                                        text: 'AI',
                                        style: TextStyle(
                                          color: AppTheme.electric,
                                        ),
                                      ),
                                      TextSpan(text: ' STAGE'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.graphic_eq_rounded,
                                      size: 14,
                                      color: voice.state == VoiceOrbState.idle
                                          ? Colors.white38
                                          : AppTheme.electric,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: voice.state == VoiceOrbState.idle
                                            ? Colors.white54
                                            : AppTheme.electric,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => widget.onOpenTab?.call(4),
                            icon: const Icon(Icons.auto_awesome_rounded,
                                color: AppTheme.electric),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final micSize = (box.maxWidth * 0.46).clamp(150.0, 200.0);
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Concentric guide rings behind mic.
                              CustomPaint(
                                size: Size(box.maxWidth, box.maxHeight),
                                painter: _OrbitPainter(
                                  progress: _bg.value,
                                  accent: AppTheme.electric
                                      .withValues(alpha: 0.12),
                                ),
                              ),
                              // Top-left health
                              Positioned(
                                top: 8,
                                left: 12,
                                child: _GlassMetric(
                                  icon: Icons.favorite_rounded,
                                  label: 'HEALTH SCORE',
                                  value: '${day.healthScore}/100',
                                  progress: day.healthScore / 100,
                                  onTap: () => widget.onOpenTab?.call(3),
                                ),
                              ),
                              // Top-right steps
                              Positioned(
                                top: 8,
                                right: 12,
                                child: _GlassMetric(
                                  icon: Icons.directions_walk_rounded,
                                  label: 'STEPS',
                                  value:
                                      '${NumberFormat.decimalPattern().format(day.steps)}/${NumberFormat.compact().format(day.stepGoal)}',
                                  progress: (day.steps / day.stepGoal)
                                      .clamp(0.0, 1.0),
                                  onTap: () => widget.onOpenTab?.call(3),
                                ),
                              ),
                              // Live mic
                              GestureDetector(
                                onTap: _toggleMic,
                                child: VoiceArtwork(
                                  size: micSize,
                                  pulse: voice.amplitude,
                                  state: voice.state == VoiceOrbState.idle
                                      ? VoiceOrbState.listening
                                      : voice.state,
                                ),
                              ),
                              // Bottom-left protein
                              Positioned(
                                bottom: 88,
                                left: 12,
                                child: _GlassMetric(
                                  icon: Icons.local_drink_rounded,
                                  label: 'PROTEIN',
                                  value:
                                      '${day.proteinG.toStringAsFixed(0)}/${day.proteinGoal.toStringAsFixed(0)}g',
                                  progress: (day.proteinG / day.proteinGoal)
                                      .clamp(0.0, 1.0),
                                  onTap: () => widget.onOpenTab?.call(2),
                                ),
                              ),
                              // Bottom-right upper body
                              Positioned(
                                bottom: 88,
                                right: 12,
                                child: _GlassMetric(
                                  icon: Icons.fitness_center_rounded,
                                  label: 'UPPER BODY',
                                  value: upperLabel,
                                  valueColor: upperReady >= 70
                                      ? AppTheme.electric
                                      : AppTheme.amber,
                                  subtitle: '$upperReady% RECOVERY',
                                  progress: upperReady / 100,
                                  onTap: () {
                                    state.generateWorkout(
                                      focus: 'Upper',
                                      minutes: day.workoutMinutes,
                                    );
                                    widget.onOpenTab?.call(1);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const TrainSessionLauncher(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Coach bubble
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 12,
                                child: _CoachBubble(
                                  text: brief.isEmpty
                                      ? "You're recovered. Train upper body today."
                                      : brief,
                                  onOpen: () => widget.onOpenTab?.call(4),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Atmosphere extends StatelessWidget {
  final double t;
  const _Atmosphere({required this.t});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(math.sin(t * math.pi * 2) * 0.15, -0.2),
          radius: 1.2,
          colors: const [
            Color(0xFF122018),
            Color(0xFF080B12),
            Color(0xFF05070D),
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: CustomPaint(painter: _BokehPainter(t: t)),
    );
  }
}

class _BokehPainter extends CustomPainter {
  final double t;
  _BokehPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    for (var i = 0; i < 18; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = 18 + rnd.nextDouble() * 40;
      final paint = Paint()
        ..color = AppTheme.electric.withValues(
          alpha: 0.03 + 0.04 * math.sin((t + i) * math.pi * 2),
        );
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BokehPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _OrbitPainter extends CustomPainter {
  final double progress;
  final Color accent;
  _OrbitPainter({required this.progress, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 - 20);
    final paint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(c, 70.0 + i * 38, paint);
    }
    final sweep = Paint()
      ..color = AppTheme.electric.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: 148),
      progress * math.pi * 2,
      1.2,
      false,
      sweep,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _GlassMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double progress;
  final String? subtitle;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _GlassMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
    this.subtitle,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 148,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.07),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 14, color: AppTheme.electric),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? Colors.white,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.white12,
                    color: AppTheme.electric,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoachBubble extends StatelessWidget {
  final String text;
  final VoidCallback onOpen;

  const _CoachBubble({required this.text, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Material(
          color: Colors.white.withValues(alpha: 0.08),
          child: InkWell(
            onTap: onOpen,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.electric.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.graphic_eq_rounded,
                        color: AppTheme.electric, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: onOpen,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.electric,
                      foregroundColor: AppTheme.navy,
                      fixedSize: const Size(40, 40),
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
