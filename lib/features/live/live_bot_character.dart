import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_theme.dart';
import '../home/presentation/widgets/components/ai_voice_orb.dart';

/// Premium live cartoon Bot — spring motion, lip-sync mouth, reactive eyes.
class LiveBotCharacter extends StatefulWidget {
  static const asset = 'assets/branding/bot.jpg';

  final double size;
  final double pulse;
  final VoiceOrbState state;
  final bool showGlow;
  final VoidCallback? onTap;

  const LiveBotCharacter({
    super.key,
    required this.size,
    this.pulse = 0,
    this.state = VoiceOrbState.idle,
    this.showGlow = true,
    this.onTap,
  });

  @override
  State<LiveBotCharacter> createState() => _LiveBotCharacterState();
}

class _LiveBotCharacterState extends State<LiveBotCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _life;
  late final AnimationController _talk;
  late final AnimationController _spin;
  late final AnimationController _blink;
  late final AnimationController _jump;
  late final AnimationController _look;
  double _smoothPulse = 0;
  double _lookX = 0;
  double _lookY = 0;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _life = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _talk = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );

    _jump = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    _look = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _life.addListener(_tick);
    _scheduleBlink();
    _scheduleGlance();
    _scheduleIdleHop();
    _syncState(widget.state);
  }

  void _scheduleBlink() {
    Future.delayed(Duration(milliseconds: 1800 + _rng.nextInt(3200)), () async {
      if (!mounted) return;
      // Double-blink occasionally
      await _blink.forward(from: 0);
      await _blink.reverse();
      if (_rng.nextBool() && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 90));
        if (!mounted) return;
        await _blink.forward(from: 0);
        await _blink.reverse();
      }
      _scheduleBlink();
    });
  }

  void _scheduleGlance() {
    Future.delayed(Duration(milliseconds: 2600 + _rng.nextInt(4000)), () {
      if (!mounted) return;
      setState(() {
        _lookX = (_rng.nextDouble() - 0.5) * 1.4;
        _lookY = (_rng.nextDouble() - 0.5) * 0.8;
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _lookX = 0;
          _lookY = 0;
        });
      });
      _scheduleGlance();
    });
  }

  void _scheduleIdleHop() {
    Future.delayed(Duration(milliseconds: 4200 + _rng.nextInt(3500)), () {
      if (!mounted) return;
      if (widget.state == VoiceOrbState.idle ||
          widget.state == VoiceOrbState.listening) {
        _playJump();
      }
      _scheduleIdleHop();
    });
  }

  void _playJump() {
    if (_jump.isAnimating) return;
    HapticFeedback.selectionClick();
    _jump.forward(from: 0).whenComplete(() {
      if (mounted) _jump.value = 0;
    });
  }

  @override
  void didUpdateWidget(covariant LiveBotCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _syncState(widget.state);
      if (widget.state == VoiceOrbState.speaking ||
          widget.state == VoiceOrbState.listening) {
        _playJump();
      }
      if (widget.state == VoiceOrbState.thinking) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _syncState(VoiceOrbState state) {
    switch (state) {
      case VoiceOrbState.speaking:
        if (!_talk.isAnimating) {
          _talk.duration = const Duration(milliseconds: 130);
          _talk.repeat(reverse: true);
        }
        if (_spin.isAnimating) {
          _spin.animateTo(0, duration: const Duration(milliseconds: 380));
        }
      case VoiceOrbState.thinking:
        _talk.stop();
        _talk.value = 0;
        if (!_spin.isAnimating) _spin.repeat();
      case VoiceOrbState.listening:
        _talk.stop();
        _talk.value = 0.05;
        if (_spin.isAnimating) {
          _spin.stop();
          _spin.value = 0;
        }
      case VoiceOrbState.idle:
        _talk.stop();
        _talk.value = 0;
        if (_spin.isAnimating) {
          _spin.animateTo(0, duration: const Duration(milliseconds: 450));
        }
    }
  }

  void _tick() {
    final target = widget.pulse.clamp(0.0, 1.0);
    _smoothPulse += (target - _smoothPulse) * 0.32;
    setState(() {});
  }

  @override
  void dispose() {
    _life.removeListener(_tick);
    _life.dispose();
    _talk.dispose();
    _spin.dispose();
    _blink.dispose();
    _jump.dispose();
    _look.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final speaking = widget.state == VoiceOrbState.speaking;

    return GestureDetector(
      onTap: () {
        _playJump();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_life, _talk, _spin, _blink, _jump, _look]),
        builder: (context, _) {
          final life = Curves.easeInOut.transform(_life.value);
          final talk = speaking ? _talk.value : 0.0;
          final pulse = speaking
              ? (0.4 + _smoothPulse * 0.6).clamp(0.0, 1.0)
              : _smoothPulse;

          final jumpT = Curves.easeOutCubic.transform(_jump.value);
          final jumpY = math.sin(jumpT * math.pi) * (size * 0.14);
          final squash = 1.0 - math.sin(jumpT * math.pi) * 0.07;
          final stretch = 1.0 + math.sin(jumpT * math.pi) * 0.09;

          final hop = math.sin(life * math.pi) * (size * 0.022) + jumpY;

          final headYaw = widget.state == VoiceOrbState.thinking
              ? math.sin(_spin.value * math.pi * 2) * 0.48
              : math.sin(life * math.pi * 2) * 0.14 +
                  math.sin(_look.value * math.pi) * 0.06;

          final headPitch = speaking
              ? math.sin(talk * math.pi) * 0.1 + pulse * 0.05
              : (widget.state == VoiceOrbState.listening
                  ? -0.08 + math.sin(life * math.pi * 2) * 0.035
                  : math.sin(life * math.pi) * 0.05);

          final bodySway = math.sin(life * math.pi * 2) * 0.035;
          final mouthOpen = speaking
              ? (0.2 + talk * 0.85 + pulse * 0.4).clamp(0.0, 1.0)
              : 0.0;
          final armWave = speaking
              ? math.sin(talk * math.pi * 2) * 0.45
              : math.sin(life * math.pi * 2) * 0.1;

          // Phoneme-ish mouth shapes while speaking
          final mouthWide = speaking ? (0.55 + talk * 0.45) : 0.7;

          final boxW = widget.showGlow ? size * 1.2 : size * 1.02;
          final boxH = widget.showGlow ? size * 1.42 : size * 1.12;

          return SizedBox(
            width: boxW,
            height: boxH,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (widget.showGlow) ...[
                  _AuraField(
                    size: size * 1.35,
                    state: widget.state,
                    life: life,
                    energy: 0.25 + pulse * 0.75,
                  ),
                  Positioned(
                    bottom: size * 0.01,
                    child: Opacity(
                      opacity: (0.45 + pulse * 0.3) * (1 - jumpT * 0.4),
                      child: Container(
                        width: size * (0.4 - jumpT * 0.12),
                        height: 9,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: AppTheme.bronze.withValues(alpha: 0.25),
                              blurRadius: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                Transform.translate(
                  offset: Offset(0, -hop),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..scaleByDouble(
                        stretch * (1 + bodySway.abs() * 0.02),
                        squash,
                        1,
                        1,
                      ),
                    child: CustomPaint(
                      size: Size(size, size * 1.18),
                      painter: _CartoonBotPainter(
                        headYaw: headYaw + bodySway,
                        headPitch: headPitch,
                        mouthOpen: mouthOpen,
                        mouthWide: mouthWide,
                        armWave: armWave,
                        eyeBlink: _blink.value,
                        lookX: _lookX,
                        lookY: _lookY,
                        listening: widget.state == VoiceOrbState.listening,
                        speaking: speaking,
                        thinking: widget.state == VoiceOrbState.thinking,
                        pulse: pulse,
                        life: life,
                        chestGlow: speaking ||
                            widget.state == VoiceOrbState.listening,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AuraField extends StatelessWidget {
  final double size;
  final VoiceOrbState state;
  final double life;
  final double energy;

  const _AuraField({
    required this.size,
    required this.state,
    required this.life,
    required this.energy,
  });

  @override
  Widget build(BuildContext context) {
    final accent = switch (state) {
      VoiceOrbState.speaking => AppTheme.bronzeSoft,
      VoiceOrbState.listening => AppTheme.bronze,
      VoiceOrbState.thinking => AppTheme.copper,
      VoiceOrbState.idle => AppTheme.bronzeDeep,
    };

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AuraPainter(
          progress: life,
          energy: energy,
          color: accent,
          rings: state == VoiceOrbState.speaking ? 3 : 2,
        ),
      ),
    );
  }
}

class _AuraPainter extends CustomPainter {
  final double progress;
  final double energy;
  final Color color;
  final int rings;

  _AuraPainter({
    required this.progress,
    required this.energy,
    required this.color,
    required this.rings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < rings; i++) {
      final t = (progress + i / rings) % 1.0;
      final r = size.shortestSide * (0.28 + t * 0.28);
      final alpha = (1 - t) * (0.18 + energy * 0.22);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = color.withValues(alpha: alpha),
      );
    }
    canvas.drawCircle(
      c,
      size.shortestSide * 0.32,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          size.shortestSide * 0.4,
          [
            color.withValues(alpha: 0.22 * energy),
            color.withValues(alpha: 0),
          ],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _AuraPainter old) =>
      old.progress != progress ||
      old.energy != energy ||
      old.color != color ||
      old.rings != rings;
}

class _CartoonBotPainter extends CustomPainter {
  final double headYaw;
  final double headPitch;
  final double mouthOpen;
  final double mouthWide;
  final double armWave;
  final double eyeBlink;
  final double lookX;
  final double lookY;
  final bool listening;
  final bool speaking;
  final bool thinking;
  final double pulse;
  final double life;
  final bool chestGlow;

  _CartoonBotPainter({
    required this.headYaw,
    required this.headPitch,
    required this.mouthOpen,
    required this.mouthWide,
    required this.armWave,
    required this.eyeBlink,
    required this.lookX,
    required this.lookY,
    required this.listening,
    required this.speaking,
    required this.thinking,
    required this.pulse,
    required this.life,
    required this.chestGlow,
  });

  static const _skin = Color(0xFFE08A45);
  static const _skinLight = Color(0xFFF2B07A);
  static const _skinDeep = Color(0xFFC46A32);
  static const _face = Color(0xFFB85A28);
  static const _joint = Color(0xFF2E241F);
  static const _base = Color(0xFF3F2C22);
  static const _glow = Color(0xFFFFF6D0);
  static const _ear = Color(0xFF6E6056);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final bodyTop = size.height * 0.50;
    final bodyH = size.height * 0.46;
    final bodyW = size.width * 0.50;

    _drawArm(canvas, Offset(cx - bodyW * 0.58, bodyTop + bodyH * 0.26),
        left: true);
    _drawArm(canvas, Offset(cx + bodyW * 0.58, bodyTop + bodyH * 0.26),
        left: false);

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, bodyTop + bodyH * 0.44),
        width: bodyW,
        height: bodyH,
      ),
      Radius.circular(bodyW * 0.4),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_skinLight, _skin, _base],
          stops: [0.0, 0.52, 1.0],
        ).createShader(bodyRect.outerRect),
    );

    // Specular
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - bodyW * 0.12, bodyTop + bodyH * 0.18),
        width: bodyW * 0.35,
        height: bodyH * 0.18,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.1),
    );

    final chest = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, bodyTop + bodyH * 0.36),
        width: bodyW * 0.46,
        height: bodyH * 0.26,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      chest,
      Paint()..color = _skinLight.withValues(alpha: 0.92),
    );

    // Chest LED
    final ledAlpha = chestGlow ? 0.55 + pulse * 0.45 : 0.2 + life * 0.15;
    canvas.drawCircle(
      Offset(cx, bodyTop + bodyH * 0.36),
      bodyW * 0.06,
      Paint()
        ..color = _glow.withValues(alpha: ledAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      Offset(cx, bodyTop + bodyH * 0.36),
      bodyW * 0.035,
      Paint()..color = _glow.withValues(alpha: ledAlpha),
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(
          cx - bodyW * 0.5,
          bodyTop + bodyH * 0.70,
          bodyW,
          bodyH * 0.30,
        ),
        bottomLeft: Radius.circular(bodyW * 0.4),
        bottomRight: Radius.circular(bodyW * 0.4),
      ),
      Paint()..color = _base,
    );

    final neckY = bodyTop - size.height * 0.015;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, neckY),
          width: size.width * 0.13,
          height: size.height * 0.075,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = _joint,
    );

    // Head
    canvas.save();
    final headC = Offset(cx, size.height * 0.27);
    canvas.translate(headC.dx, headC.dy);
    canvas.rotate(headYaw * 0.55);
    canvas.scale(1.0 - headYaw.abs() * 0.1, 1.0 + headPitch * 0.18);
    canvas.translate(0, headPitch * size.height * 0.055);
    canvas.translate(-headC.dx, -headC.dy);

    final headW = size.width * 0.74;
    final headH = size.height * 0.43;
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: headC, width: headW, height: headH),
      Radius.circular(headW * 0.28),
    );

    canvas.drawRRect(
      headRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_skinLight, _skin, _skinDeep],
          stops: [0.0, 0.55, 1.0],
        ).createShader(headRect.outerRect),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(headC.dx - headW * 0.14, headC.dy - headH * 0.2),
          width: headW * 0.42,
          height: headH * 0.2,
        ),
        const Radius.circular(40),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );

    _drawEar(canvas, Offset(headC.dx - headW * 0.52, headC.dy), life);
    _drawEar(canvas, Offset(headC.dx + headW * 0.52, headC.dy), life);

    final face = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(headC.dx, headC.dy + headH * 0.02),
        width: headW * 0.64,
        height: headH * 0.64,
      ),
      Radius.circular(headW * 0.12),
    );
    canvas.drawRRect(face, Paint()..color = _face);

    // Inner face vignette
    canvas.drawRRect(
      face,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(headC.dx, headC.dy),
          headW * 0.35,
          [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.18),
          ],
        ),
    );

    final eyeY = headC.dy - headH * 0.02;
    final eyeR = headW * 0.058 * (1.0 - eyeBlink * 0.95);
    final eyeGlow = listening || speaking || thinking ? 1.0 : 0.72;
    for (final dx in [-headW * 0.145, headW * 0.145]) {
      final c = Offset(
        headC.dx + dx + lookX * headW * 0.035,
        eyeY + lookY * headH * 0.04,
      );
      canvas.drawCircle(
        c,
        eyeR * 2.1,
        Paint()
          ..color = _glow.withValues(alpha: 0.4 * eyeGlow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(c, eyeR, Paint()..color = _glow);
      // Pupil hint
      canvas.drawCircle(
        Offset(c.dx + lookX * 2, c.dy + lookY * 2),
        eyeR * 0.28,
        Paint()..color = const Color(0xFF5A3A10).withValues(alpha: 0.35),
      );
    }

    final mouthC = Offset(headC.dx, headC.dy + headH * 0.17);
    _drawMouth(canvas, mouthC, headW * 0.17 * mouthWide, mouthOpen);

    // Thinking dots above head
    if (thinking) {
      for (var i = 0; i < 3; i++) {
        final a = ((life * 3 + i) % 1.0);
        canvas.drawCircle(
          Offset(
            headC.dx + (i - 1) * headW * 0.12,
            headC.dy - headH * 0.62 - a * 8,
          ),
          3.5 + a * 2,
          Paint()..color = _glow.withValues(alpha: 0.4 + a * 0.5),
        );
      }
    }

    canvas.restore();
  }

  void _drawMouth(Canvas canvas, Offset c, double w, double open) {
    final stroke = Paint()
      ..color = _glow
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.8, w * 0.16)
      ..strokeCap = StrokeCap.round;

    if (open < 0.1) {
      final path = Path()
        ..moveTo(c.dx - w, c.dy)
        ..quadraticBezierTo(c.dx, c.dy + w * 0.6, c.dx + w, c.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = _glow.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke.strokeWidth + 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(path, stroke);
      return;
    }

    final oh = w * (0.28 + open * 1.05);
    final ow = w * (0.65 + open * 0.5);
    final oval = Rect.fromCenter(center: c, width: ow * 2, height: oh * 2);

    canvas.drawOval(
      oval.inflate(6),
      Paint()
        ..color = _glow.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawOval(oval, Paint()..color = _glow);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: ow * 1.15, height: oh * 1.05),
      Paint()..color = const Color(0xFF4A2A12).withValues(alpha: 0.65),
    );
    // Tongue hint when wide open
    if (open > 0.55) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy + oh * 0.25),
          width: ow * 0.7,
          height: oh * 0.35,
        ),
        Paint()..color = const Color(0xFFE07850).withValues(alpha: 0.55),
      );
    }
  }

  void _drawEar(Canvas canvas, Offset c, double life) {
    final wobble = math.sin(life * math.pi * 2) * 1.2;
    canvas.drawCircle(
      Offset(c.dx, c.dy + wobble),
      12,
      Paint()..color = _ear,
    );
    canvas.drawCircle(
      Offset(c.dx, c.dy + wobble),
      6.5,
      Paint()..color = _joint,
    );
    canvas.drawCircle(
      Offset(c.dx, c.dy + wobble),
      3,
      Paint()..color = _glow.withValues(alpha: 0.35 + pulse * 0.4),
    );
  }

  void _drawArm(Canvas canvas, Offset shoulder, {required bool left}) {
    canvas.save();
    canvas.translate(shoulder.dx, shoulder.dy);
    final angle = left ? -0.6 - armWave : 0.6 + armWave;
    canvas.rotate(angle);
    canvas.drawCircle(Offset.zero, 11, Paint()..color = _joint);
    final arm = RRect.fromRectAndRadius(
      Rect.fromLTWH(left ? -46 : 0, -10, 46, 20),
      const Radius.circular(11),
    );
    canvas.drawRRect(
      arm,
      Paint()
        ..shader = LinearGradient(
          colors: [_skinLight, _skin],
        ).createShader(arm.outerRect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CartoonBotPainter old) =>
      old.headYaw != headYaw ||
      old.headPitch != headPitch ||
      old.mouthOpen != mouthOpen ||
      old.mouthWide != mouthWide ||
      old.armWave != armWave ||
      old.eyeBlink != eyeBlink ||
      old.lookX != lookX ||
      old.lookY != lookY ||
      old.speaking != speaking ||
      old.listening != listening ||
      old.thinking != thinking ||
      old.pulse != pulse ||
      old.life != life ||
      old.chestGlow != chestGlow;
}
