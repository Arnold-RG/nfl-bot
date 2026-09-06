import 'dart:math' as math;

import 'package:flutter/material.dart';

/// What the coach is doing right now. Drives the orb's colour and energy.
enum VoiceOrbState { idle, listening, thinking, speaking }

extension VoiceOrbStateLabel on VoiceOrbState {
  String get label => switch (this) {
    VoiceOrbState.idle => 'Tap to talk',
    VoiceOrbState.listening => 'Listening',
    VoiceOrbState.thinking => 'Thinking',
    VoiceOrbState.speaking => 'Speaking',
  };
}

/// Colour set for one orb state.
class _OrbPalette {
  final Color core;
  final Color spike;
  final Color accent;
  final Color rim;

  const _OrbPalette({
    required this.core,
    required this.spike,
    required this.accent,
    required this.rim,
  });

  static const _idle = _OrbPalette(
    core: Color(0xFF2F6BFF),
    spike: Color(0xFF3D7BFF),
    accent: Color(0xFF7C4DFF),
    rim: Color(0xFF6C4BFF),
  );
  static const _listening = _OrbPalette(
    core: Color(0xFF00E5FF),
    spike: Color(0xFF22D3EE),
    accent: Color(0xFF2F6BFF),
    rim: Color(0xFF00E5FF),
  );
  static const _thinking = _OrbPalette(
    core: Color(0xFF7C4DFF),
    spike: Color(0xFF8B5CF6),
    accent: Color(0xFFE040FB),
    rim: Color(0xFF9A6BFF),
  );
  static const _speaking = _OrbPalette(
    core: Color(0xFF4FA8FF),
    spike: Color(0xFF4FA8FF),
    accent: Color(0xFFFF2D9B),
    rim: Color(0xFFFF2D9B),
  );

  static _OrbPalette of(VoiceOrbState state) => switch (state) {
    VoiceOrbState.idle => _idle,
    VoiceOrbState.listening => _listening,
    VoiceOrbState.thinking => _thinking,
    VoiceOrbState.speaking => _speaking,
  };

  _OrbPalette lerpTo(_OrbPalette other, double t) => _OrbPalette(
    core: Color.lerp(core, other.core, t)!,
    spike: Color.lerp(spike, other.spike, t)!,
    accent: Color.lerp(accent, other.accent, t)!,
    rim: Color.lerp(rim, other.rim, t)!,
  );
}

/// The AI coach itself: a radial burst of light around a dark core with a
/// microphone at its centre. Replaces the old illustrated human trainer.
///
/// [amplitude] (0..1) is the live microphone or speech level, which makes the
/// burst breathe in time with the actual conversation rather than on a loop.
class AiVoiceOrb extends StatefulWidget {
  final double size;
  final VoiceOrbState state;
  final double amplitude;
  final VoidCallback? onTap;

  /// Hides the radiating spikes, for very small inline placements.
  final bool compact;

  const AiVoiceOrb({
    super.key,
    this.size = 120,
    this.state = VoiceOrbState.idle,
    this.amplitude = 0,
    this.onTap,
    this.compact = false,
  });

  @override
  State<AiVoiceOrb> createState() => _AiVoiceOrbState();
}

class _AiVoiceOrbState extends State<AiVoiceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  /// Smoothed amplitude, so a spiky microphone level does not make the orb
  /// jitter frame to frame.
  double _smoothedAmplitude = 0;

  _OrbPalette _palette = _OrbPalette.of(VoiceOrbState.idle);
  _OrbPalette _targetPalette = _OrbPalette.of(VoiceOrbState.idle);
  double _paletteBlend = 1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _palette = _OrbPalette.of(widget.state);
    _targetPalette = _palette;
    _ctrl.addListener(_tick);
  }

  @override
  void didUpdateWidget(AiVoiceOrb old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      _palette = _blended();
      _targetPalette = _OrbPalette.of(widget.state);
      _paletteBlend = 0;
    }
  }

  void _tick() {
    final target = widget.amplitude.clamp(0.0, 1.0);
    // Rise quickly to feel responsive, fall slowly so it does not flicker.
    final rate = target > _smoothedAmplitude ? 0.35 : 0.08;
    _smoothedAmplitude += (target - _smoothedAmplitude) * rate;
    if (_paletteBlend < 1) {
      _paletteBlend = math.min(1, _paletteBlend + 0.05);
    }
    setState(() {});
  }

  _OrbPalette _blended() => _palette.lerpTo(_targetPalette, _paletteBlend);

  @override
  void dispose() {
    _ctrl.removeListener(_tick);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orb = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(widget.size),
            painter: _OrbPainter(
              progress: _ctrl.value,
              amplitude: _smoothedAmplitude,
              palette: _blended(),
              state: widget.state,
              showSpikes: !widget.compact,
            ),
          ),
          _MicGlyph(
            size: widget.size * 0.26,
            palette: _blended(),
            pulsing: widget.state == VoiceOrbState.speaking,
            progress: _ctrl.value,
          ),
        ],
      ),
    );

    if (widget.onTap == null) return orb;

    return Semantics(
      button: true,
      label: 'AI coach — ${widget.state.label}',
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: orb,
      ),
    );
  }
}

/// Microphone at the centre, filled with the orb's own gradient.
class _MicGlyph extends StatelessWidget {
  final double size;
  final _OrbPalette palette;
  final bool pulsing;
  final double progress;

  const _MicGlyph({
    required this.size,
    required this.palette,
    required this.pulsing,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final pulse = pulsing
        ? 1 + 0.06 * math.sin(progress * math.pi * 2 * 9)
        : 1.0;

    return Transform.scale(
      scale: pulse,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(palette.spike, Colors.white, 0.35)!,
            palette.accent,
          ],
        ).createShader(rect),
        child: Icon(Icons.mic_rounded, size: size, color: Colors.white),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double progress;
  final double amplitude;
  final _OrbPalette palette;
  final VoiceOrbState state;
  final bool showSpikes;

  _OrbPainter({
    required this.progress,
    required this.amplitude,
    required this.palette,
    required this.state,
    required this.showSpikes,
  });

  /// Stable pseudo-random in 0..1, so each spike keeps its own character
  /// across frames instead of shimmering randomly.
  static double _hash(int i) {
    final v = math.sin(i * 12.9898) * 43758.5453;
    return (v - v.floorToDouble()).abs();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    // The dark core takes up the middle; the burst lives outside it.
    final coreRadius = radius * 0.36;

    _paintHalo(canvas, center, radius);
    if (showSpikes) _paintSpikes(canvas, center, coreRadius, radius);
    _paintCore(canvas, center, coreRadius);
  }

  void _paintHalo(Canvas canvas, Offset center, double radius) {
    final energy = 0.55 + amplitude * 0.45;
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.core.withValues(alpha: 0.42 * energy),
          palette.accent.withValues(alpha: 0.16 * energy),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, halo);
  }

  void _paintSpikes(
    Canvas canvas,
    Offset center,
    double coreRadius,
    double radius,
  ) {
    const count = 84;
    final rotation = progress * math.pi * 2 * 0.12;
    final span = radius - coreRadius;

    for (var i = 0; i < count; i++) {
      final seed = _hash(i);
      final angle = (i / count) * math.pi * 2 + rotation;

      // Each spike breathes on its own phase, then the live audio level
      // pushes them all outward together.
      final wave = math.sin(progress * math.pi * 2 * 3 + seed * math.pi * 2);
      final base = 0.35 + seed * 0.55;
      final reach = (base + wave * 0.12 + amplitude * 0.42).clamp(0.18, 1.0);

      final start = coreRadius * (1.02 + seed * 0.06);
      final end = coreRadius + span * reach;

      final p1 = center + Offset(math.cos(angle), math.sin(angle)) * start;
      final p2 = center + Offset(math.cos(angle), math.sin(angle)) * end;

      // Longer spikes read as brighter, which gives the burst depth.
      final intensity = (0.28 + reach * 0.62).clamp(0.0, 1.0);
      final color = Color.lerp(palette.spike, palette.accent, seed * 0.55)!;

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = color.withValues(alpha: 0.22 + intensity * 0.5)
          ..strokeWidth = 0.6 + seed * 1.1
          ..strokeCap = StrokeCap.round,
      );

      // Node dot at the tip, as in the reference art.
      if (seed > 0.28) {
        canvas.drawCircle(
          p2,
          (0.9 + seed * 1.4) * (radius / 120).clamp(0.55, 1.6),
          Paint()..color = color.withValues(alpha: 0.35 + intensity * 0.5),
        );
      }
    }
  }

  void _paintCore(Canvas canvas, Offset center, double coreRadius) {
    // Soft bloom behind the core so it sits in the light rather than on it.
    canvas.drawCircle(
      center,
      coreRadius * 1.28,
      Paint()
        ..color = palette.rim.withValues(alpha: 0.30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, coreRadius * 0.42),
    );

    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF141428), Color(0xFF080814)],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius)),
    );

    final rimWidth = coreRadius * 0.05;
    canvas.drawCircle(
      center,
      coreRadius - rimWidth / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rimWidth
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 2,
          transform: GradientRotation(progress * math.pi * 2),
          colors: [
            palette.rim.withValues(alpha: 0.15),
            palette.rim.withValues(alpha: 0.95),
            palette.accent.withValues(alpha: 0.85),
            palette.rim.withValues(alpha: 0.15),
          ],
          stops: const [0.0, 0.35, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius)),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.progress != progress ||
      old.amplitude != amplitude ||
      old.state != state ||
      old.palette.core != palette.core;
}

/// Full-width flowing wave ribbons used behind the orb on the live voice
/// screen. Kept separate from the orb so it can span the whole viewport.
class VoiceWaveField extends StatefulWidget {
  final VoiceOrbState state;
  final double amplitude;
  final double height;

  const VoiceWaveField({
    super.key,
    this.state = VoiceOrbState.idle,
    this.amplitude = 0,
    this.height = 320,
  });

  @override
  State<VoiceWaveField> createState() => _VoiceWaveFieldState();
}

class _VoiceWaveFieldState extends State<VoiceWaveField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _smoothed = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _ctrl.addListener(_tick);
  }

  void _tick() {
    final target = widget.amplitude.clamp(0.0, 1.0);
    final rate = target > _smoothed ? 0.25 : 0.06;
    _smoothed += (target - _smoothed) * rate;
    setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_tick);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _WaveFieldPainter(
            progress: _ctrl.value,
            amplitude: _smoothed,
            palette: _OrbPalette.of(widget.state),
          ),
        ),
      ),
    );
  }
}

class _WaveFieldPainter extends CustomPainter {
  final double progress;
  final double amplitude;
  final _OrbPalette palette;

  _WaveFieldPainter({
    required this.progress,
    required this.amplitude,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Two overlapping ribbons travelling in opposite directions produce the
    // moiré mesh in the reference image.
    _ribbon(
      canvas,
      size,
      color: palette.spike,
      direction: 1,
      verticalBias: 0.42,
      seedPhase: 0,
    );
    _ribbon(
      canvas,
      size,
      color: palette.accent,
      direction: -1,
      verticalBias: 0.58,
      seedPhase: 1.7,
    );
  }

  void _ribbon(
    Canvas canvas,
    Size size, {
    required Color color,
    required int direction,
    required double verticalBias,
    required double seedPhase,
  }) {
    const lines = 22;
    const samples = 56;
    final baseY = size.height * verticalBias;
    final travel = progress * math.pi * 2 * direction;
    final swell = size.height * (0.10 + amplitude * 0.22);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    for (var j = 0; j < lines; j++) {
      final t = j / (lines - 1);
      // Fan the lines apart so the band has thickness and an inner glow.
      final spread = (t - 0.5) * 2;
      final phase = travel + seedPhase + t * 1.15;

      final path = Path();
      for (var i = 0; i <= samples; i++) {
        final x = size.width * (i / samples);
        final u = i / samples;

        final y =
            baseY +
            math.sin(u * math.pi * 2.1 + phase) * swell * (0.55 + t * 0.7) +
            math.sin(u * math.pi * 3.7 - phase * 0.6) * swell * 0.28 +
            spread * size.height * 0.055;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      // Fade the outermost lines so the ribbon has soft edges.
      final edgeFade = 1 - (spread.abs() * 0.75);
      paint.color = color.withValues(
        alpha: (0.05 + 0.18 * edgeFade) * (0.6 + amplitude * 0.6),
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveFieldPainter old) =>
      old.progress != progress ||
      old.amplitude != amplitude ||
      old.palette.core != palette.core;
}
