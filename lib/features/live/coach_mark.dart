import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_theme.dart';
import '../home/presentation/widgets/components/ai_voice_orb.dart';

/// New AI coach symbol — geometric signal mark (not a cartoon character).
/// Outer ring + core diamond + reactive voice arcs.
class CoachMark extends StatefulWidget {
  final double size;
  final double pulse;
  final VoiceOrbState state;
  final bool showGlow;
  final VoidCallback? onTap;

  const CoachMark({
    super.key,
    required this.size,
    this.pulse = 0,
    this.state = VoiceOrbState.idle,
    this.showGlow = true,
    this.onTap,
  });

  @override
  State<CoachMark> createState() => _CoachMarkState();
}

class _CoachMarkState extends State<CoachMark>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _spin;
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _sync(widget.state);
  }

  @override
  void didUpdateWidget(covariant CoachMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _sync(widget.state);
  }

  void _sync(VoiceOrbState state) {
    switch (state) {
      case VoiceOrbState.speaking:
        if (!_wave.isAnimating) _wave.repeat(reverse: true);
        if (_spin.isAnimating) _spin.stop();
      case VoiceOrbState.thinking:
        _wave.stop();
        _wave.value = 0.35;
        if (!_spin.isAnimating) _spin.repeat();
      case VoiceOrbState.listening:
        if (!_wave.isAnimating) {
          _wave.duration = const Duration(milliseconds: 1400);
          _wave.repeat(reverse: true);
        }
        if (_spin.isAnimating) _spin.stop();
      case VoiceOrbState.idle:
        _wave.stop();
        _wave.value = 0.15;
        if (_spin.isAnimating) {
          _spin.animateTo(0, duration: const Duration(milliseconds: 400));
        }
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _spin.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_breath, _spin, _wave]),
          builder: (context, _) {
            return CustomPaint(
              painter: _CoachMarkPainter(
                breath: _breath.value,
                spin: _spin.value,
                wave: _wave.value,
                pulse: widget.pulse,
                state: widget.state,
                showGlow: widget.showGlow,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CoachMarkPainter extends CustomPainter {
  final double breath;
  final double spin;
  final double wave;
  final double pulse;
  final VoiceOrbState state;
  final bool showGlow;

  _CoachMarkPainter({
    required this.breath,
    required this.spin,
    required this.wave,
    required this.pulse,
    required this.state,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    if (showGlow) {
      final glow = Paint()
        ..color = AppTheme.bronze.withValues(alpha: 0.12 + breath * 0.08)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35);
      canvas.drawCircle(c, r * (0.92 + pulse * 0.08), glow);
    }

    // Outer ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, r * 0.045)
      ..color = AppTheme.labBorder;
    canvas.drawCircle(c, r * 0.88, ringPaint);

    final accentRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, r * 0.05)
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.bronze.withValues(alpha: 0.85);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(spin * math.pi * 2);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.88),
      -math.pi / 2,
      math.pi * (0.55 + breath * 0.2),
      false,
      accentRing,
    );
    canvas.restore();

    // Voice arcs
    final arcStrength = switch (state) {
      VoiceOrbState.speaking => 0.55 + wave * 0.45 + pulse * 0.3,
      VoiceOrbState.listening => 0.25 + wave * 0.35 + pulse * 0.2,
      VoiceOrbState.thinking => 0.2 + breath * 0.15,
      VoiceOrbState.idle => 0.12 + breath * 0.08,
    };
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, r * 0.035)
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.bronzeSoft.withValues(alpha: 0.55 + arcStrength * 0.35);

    for (var i = 0; i < 3; i++) {
      final rr = r * (0.42 + i * 0.12);
      final sweep = (0.4 + arcStrength * 0.5) * math.pi;
      final start = -math.pi / 2 - sweep / 2 + (i - 1) * 0.08;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: rr),
        start,
        sweep,
        false,
        arcPaint,
      );
    }

    // Core diamond (coach sigil)
    final coreR = r * (0.22 + breath * 0.02 + pulse * 0.03);
    final path = Path()
      ..moveTo(c.dx, c.dy - coreR)
      ..lineTo(c.dx + coreR * 0.72, c.dy)
      ..lineTo(c.dx, c.dy + coreR)
      ..lineTo(c.dx - coreR * 0.72, c.dy)
      ..close();

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.bronzeSoft,
          AppTheme.bronze,
          AppTheme.bronzeDeep,
        ],
      ).createShader(Rect.fromCircle(center: c, radius: coreR));
    canvas.drawPath(path, fill);

    // Inner spark
    final spark = Paint()..color = AppTheme.labBg.withValues(alpha: 0.55);
    canvas.drawCircle(c, coreR * 0.28, spark);

    // Status dot
    final statusColor = switch (state) {
      VoiceOrbState.speaking => AppTheme.labGreen,
      VoiceOrbState.listening => AppTheme.bronze,
      VoiceOrbState.thinking => AppTheme.copper,
      VoiceOrbState.idle => AppTheme.labMuted,
    };
    canvas.drawCircle(
      Offset(c.dx + r * 0.62, c.dy - r * 0.62),
      math.max(2.5, r * 0.055),
      Paint()..color = statusColor,
    );
  }

  @override
  bool shouldRepaint(covariant _CoachMarkPainter old) =>
      old.breath != breath ||
      old.spin != spin ||
      old.wave != wave ||
      old.pulse != pulse ||
      old.state != state ||
      old.showGlow != showGlow;
}
