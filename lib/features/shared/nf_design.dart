import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

/// Responsive gutters and max content width for phone / tablet / desktop.
class NfLayout {
  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;

  static double pagePad(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1100) return 40;
    if (w >= 700) return 28;
    return 20;
  }

  static double maxContent(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1100) return 720;
    if (w >= 700) return 560;
    return w;
  }
}

/// Frosted bronze panel used across the product.
class NfGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const NfGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final body = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.labBorder.withValues(alpha: 0.9)),
            gradient: gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.labLift.withValues(alpha: 0.92),
                    AppTheme.labCard.withValues(alpha: 0.88),
                  ],
                ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: body,
      ),
    );
  }
}

/// Soft ambient mesh behind hero surfaces.
class NfAmbientBackdrop extends StatelessWidget {
  final Widget child;

  const NfAmbientBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppTheme.labBg),
        Positioned(
          top: -80,
          right: -60,
          child: _blob(AppTheme.bronze.withValues(alpha: 0.14), 220),
        ),
        Positioned(
          bottom: 120,
          left: -80,
          child: _blob(AppTheme.copper.withValues(alpha: 0.1), 260),
        ),
        child,
      ],
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 20)],
      ),
    );
  }
}

/// Animated streak / metric chip.
class NfMetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const NfMetricPill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.bronze;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.labMuted,
                      fontSize: 10,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.labInk,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Entrance fade + slide for list sections.
class NfReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const NfReveal({super.key, required this.child, this.delayMs = 0});

  @override
  State<NfReveal> createState() => _NfRevealState();
}

class _NfRevealState extends State<NfReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Subtle breathing ring for focus states.
class NfPulseRing extends StatelessWidget {
  final double size;
  final Color color;
  final double progress;

  const NfPulseRing({
    super.key,
    required this.size,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final s = 0.92 + math.sin(progress * math.pi) * 0.08;
    return Transform.scale(
      scale: s,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        ),
      ),
    );
  }
}
