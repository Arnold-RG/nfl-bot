import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../features/home/presentation/widgets/components/ai_voice_orb.dart';

/// Mic orb with live listening / speaking rings.
class VoiceArtwork extends StatefulWidget {
  final double size;
  final double pulse;
  final VoiceOrbState state;

  const VoiceArtwork({
    super.key,
    required this.size,
    this.pulse = 0,
    this.state = VoiceOrbState.idle,
  });

  @override
  State<VoiceArtwork> createState() => _VoiceArtworkState();
}

class _VoiceArtworkState extends State<VoiceArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _smooth = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _ctrl.addListener(_tick);
  }

  void _tick() {
    final target = widget.pulse.clamp(0.0, 1.0);
    _smooth += (target - _smooth) * 0.18;
    setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_tick);
    _ctrl.dispose();
    super.dispose();
  }

  Color get _accent {
    switch (widget.state) {
      case VoiceOrbState.listening:
        return const Color(0xFF22E38A);
      case VoiceOrbState.thinking:
        return const Color(0xFF60A5FA);
      case VoiceOrbState.speaking:
        return AppTheme.electric;
      case VoiceOrbState.idle:
        return AppTheme.electric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _ctrl.value;
    final live = widget.state != VoiceOrbState.idle;
    final energy = live ? (0.22 + _smooth * 0.78) : (0.08 + _smooth * 0.2);
    final breath = 1.0 + math.sin(t * math.pi * 2) * (0.012 + energy * 0.028);
    final ringBoost = energy;

    return SizedBox(
      width: widget.size * 1.38,
      height: widget.size * 1.38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer live rings — expand with voice energy.
          for (var i = 0; i < 3; i++)
            _PulseRing(
              size: widget.size *
                  (1.08 + i * 0.12 + ringBoost * (0.06 + i * 0.04)),
              opacity: (0.28 - i * 0.07) * (0.35 + ringBoost),
              color: _accent,
              phase: (t + i * 0.22) % 1.0,
              active: live || _smooth > 0.05,
            ),
          // Soft ambient wash behind the mic.
          Container(
            width: widget.size * 1.05,
            height: widget.size * 1.05,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.18 + energy * 0.28),
                  blurRadius: 28 + energy * 36,
                  spreadRadius: 2 + energy * 6,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: breath,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _accent.withValues(alpha: 0.22 + energy * 0.45),
                  width: 2.5 + energy * 1.5,
                ),
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            _accent.withValues(alpha: 0.45),
                            AppTheme.navy,
                          ],
                          stops: const [0.15, 1],
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.mic,
                        size: widget.size * 0.42,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.22),
                          ],
                          stops: const [0.62, 1],
                        ),
                      ),
                    ),
                    if (live)
                      Align(
                        alignment: const Alignment(-0.35, -0.45),
                        child: Container(
                          width: widget.size * 0.22,
                          height: widget.size * 0.14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.18 + energy * 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Tiny waveform ticks under the orb when live.
          if (live || _smooth > 0.08)
            Positioned(
              bottom: widget.size * 0.02,
              child: _MiniWave(
                amplitude: energy,
                color: _accent,
                width: widget.size * 0.55,
              ),
            ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  final double size;
  final double opacity;
  final Color color;
  final double phase;
  final bool active;

  const _PulseRing({
    required this.size,
    required this.opacity,
    required this.color,
    required this.phase,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final expand = active ? 1 + phase * 0.08 : 1.0;
    return Opacity(
      opacity: (opacity * (1 - phase * 0.65)).clamp(0.0, 1.0),
      child: Transform.scale(
        scale: expand,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.85),
              width: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniWave extends StatelessWidget {
  final double amplitude;
  final Color color;
  final double width;

  const _MiniWave({
    required this.amplitude,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 18,
      child: CustomPaint(
        painter: _WavePainter(amplitude: amplitude, color: color),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double amplitude;
  final Color color;

  _WavePainter({required this.amplitude, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55 + amplitude * 0.35)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final mid = size.height / 2;
    final path = Path();
    const bars = 11;
    for (var i = 0; i < bars; i++) {
      final x = size.width * (i / (bars - 1));
      final n = math.sin(i * 1.7 + amplitude * 8);
      final h = (4 + amplitude * 10) * (0.35 + n.abs());
      path.moveTo(x, mid - h);
      path.lineTo(x, mid + h);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.amplitude != amplitude || oldDelegate.color != color;
}
