import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../core/data/workout_database.dart';

/// Anatomical human demo — same interaction pattern as the reference:
/// large figure + muscle glow, carousel, sets, LOG SET.
class WorkoutAnatomyScreen extends StatefulWidget {
  final WorkoutPlan? plan;

  const WorkoutAnatomyScreen({super.key, this.plan});

  @override
  State<WorkoutAnatomyScreen> createState() => _WorkoutAnatomyScreenState();
}

class _WorkoutAnatomyScreenState extends State<WorkoutAnatomyScreen>
    with SingleTickerProviderStateMixin {
  late final List<Exercise> _moves;
  int _index = 0;
  int _loggedSets = 0;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _moves = widget.plan?.exercises ??
        [
          ...WorkoutDatabase.allExercises.take(6),
        ];
    // Prefer sprinter-style first if present
    final i = _moves.indexWhere(
      (e) => e.name.toLowerCase().contains('lunge'),
    );
    if (i >= 0) _index = i;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Exercise get _ex => _moves[_index];

  int get _setsTarget {
    if (_ex.reps > 0) return 4;
    return 3;
  }

  String get _setLabel {
    if (_ex.reps > 0) {
      return '$_setsTarget Sets × ${_ex.reps} reps'
          '${_ex.name.toLowerCase().contains('lunge') ? ', each side' : ''}';
    }
    return '$_setsTarget Sets × ${_ex.durationSec}s';
  }

  void _logSet() {
    setState(() {
      if (_loggedSets < _setsTarget) {
        _loggedSets++;
      } else {
        _loggedSets = 0;
        if (_index < _moves.length - 1) {
          _index++;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white54),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _AnatomyPainter(
                      exercise: _ex,
                      glow: 0.55 + _pulse.value * 0.45,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _moves.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final on = i == _index;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _index = i;
                      _loggedSets = 0;
                    }),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: on ? AppTheme.labMuscle : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _SilhouettePainter(pose: _moves[i].name),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF141414),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _ex.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _setLabel,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Edit',
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(_setsTarget, (i) {
                      final done = i < _loggedSets;
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? AppTheme.labMuscle
                              : const Color(0xFF2A2A2A),
                          border: Border.all(
                            color: done
                                ? AppTheme.labMuscle
                                : const Color(0xFF3A3A3A),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.labMuscle,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _logSet,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        _loggedSets >= _setsTarget ? 'NEXT MOVE' : 'LOG SET',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnatomyPainter extends CustomPainter {
  final Exercise exercise;
  final double glow;

  _AnatomyPainter({required this.exercise, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.52;
    final s = size.shortestSide * 0.0042;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(s, s);

    final body = Paint()..color = const Color(0xFFE8E8E8);
    final shade = Paint()..color = const Color(0xFFB8B8B8);
    final muscle = Paint()
      ..color = AppTheme.labMuscle.withValues(alpha: 0.55 + glow * 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final pose = exercise.name.toLowerCase();
    final isLunge = pose.contains('lunge') || pose.contains('sprinter');
    final isSquat = pose.contains('squat');
    final isPush = pose.contains('push');
    final isPlank = pose.contains('plank') || pose.contains('mountain');

    if (isPlank) {
      _drawPlank(canvas, body, shade, muscle);
    } else if (isPush) {
      _drawPush(canvas, body, shade, muscle);
    } else if (isSquat) {
      _drawSquat(canvas, body, shade, muscle);
    } else if (isLunge) {
      _drawLunge(canvas, body, shade, muscle);
    } else {
      _drawStand(canvas, body, shade, muscle);
    }

    canvas.restore();
  }

  void _drawLunge(Canvas c, Paint body, Paint shade, Paint muscle) {
    // Side-profile sprinter lunge
    // Torso
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-18, -70, 36, 70),
        const Radius.circular(10),
      ),
      body,
    );
    // Head
    c.drawCircle(const Offset(8, -88), 16, body);
    // Front leg (quad highlight)
    final front = Path()
      ..moveTo(0, 0)
      ..lineTo(55, 40)
      ..lineTo(70, 95)
      ..lineTo(55, 100)
      ..lineTo(40, 50)
      ..lineTo(-5, 10)
      ..close();
    c.drawPath(front, body);
    c.drawPath(front, muscle);
    // Back leg
    final back = Path()
      ..moveTo(0, 0)
      ..lineTo(-50, 20)
      ..lineTo(-85, 70)
      ..lineTo(-70, 78)
      ..lineTo(-35, 30)
      ..close();
    c.drawPath(back, shade);
    c.drawPath(back, muscle);
    // Arms
    c.drawLine(
      const Offset(10, -50),
      const Offset(60, -20),
      Paint()
        ..color = const Color(0xFFE8E8E8)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    c.drawLine(
      const Offset(-5, -45),
      const Offset(-45, -10),
      Paint()
        ..color = const Color(0xFFB8B8B8)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawSquat(Canvas c, Paint body, Paint shade, Paint muscle) {
    c.drawCircle(const Offset(0, -95), 16, body);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-20, -78, 40, 55),
        const Radius.circular(10),
      ),
      body,
    );
    final legs = Path()
      ..moveTo(-18, -25)
      ..lineTo(-45, 40)
      ..lineTo(-35, 95)
      ..lineTo(-15, 95)
      ..lineTo(-5, 20)
      ..lineTo(5, 20)
      ..lineTo(15, 95)
      ..lineTo(35, 95)
      ..lineTo(45, 40)
      ..lineTo(18, -25)
      ..close();
    c.drawPath(legs, body);
    c.drawPath(legs, muscle);
  }

  void _drawPush(Canvas c, Paint body, Paint shade, Paint muscle) {
    c.save();
    c.rotate(-0.9);
    c.drawCircle(const Offset(-40, -10), 14, body);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-25, -18, 90, 28),
        const Radius.circular(10),
      ),
      body,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-25, -18, 90, 28),
        const Radius.circular(10),
      ),
      muscle,
    );
    c.restore();
  }

  void _drawPlank(Canvas c, Paint body, Paint shade, Paint muscle) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-80, -12, 140, 24),
        const Radius.circular(12),
      ),
      body,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-80, -12, 140, 24),
        const Radius.circular(12),
      ),
      muscle,
    );
    c.drawCircle(const Offset(-95, -8), 12, body);
  }

  void _drawStand(Canvas c, Paint body, Paint shade, Paint muscle) {
    c.drawCircle(const Offset(0, -100), 16, body);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-18, -82, 36, 70),
        const Radius.circular(10),
      ),
      body,
    );
    c.drawLine(
      const Offset(-8, -10),
      const Offset(-20, 90),
      Paint()
        ..color = const Color(0xFFE8E8E8)
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );
    c.drawLine(
      const Offset(8, -10),
      const Offset(20, 90),
      Paint()
        ..color = const Color(0xFFE8E8E8)
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );
    c.drawLine(
      const Offset(-8, -10),
      const Offset(-20, 90),
      Paint()
        ..color = AppTheme.labMuscle.withValues(alpha: 0.4)
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(covariant _AnatomyPainter old) =>
      old.exercise.name != exercise.name || old.glow != glow;
}

class _SilhouettePainter extends CustomPainter {
  final String pose;

  _SilhouettePainter({required this.pose});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white70;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.translate(c.dx, c.dy);
    canvas.scale(0.35, 0.35);
    canvas.drawCircle(const Offset(0, -40), 10, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10, -28, 20, 30),
        const Radius.circular(4),
      ),
      p,
    );
    final ang = pose.toLowerCase().contains('lunge') ? 0.4 : 0.0;
    canvas.rotate(ang);
    canvas.drawLine(
      const Offset(-6, 5),
      const Offset(-14, 40),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(6, 5),
      const Offset(12, 40),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter old) => old.pose != pose;
}
