import 'dart:math' as math;

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
    if (w >= 1100) return 680;
    if (w >= 700) return 520;
    return w;
  }
}

/// Quiet elevated panel — flat, bordered, no heavy glass blur.
class NfGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;

  const NfGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.gradient,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.labBorder),
        color: gradient == null ? (color ?? AppTheme.labCard) : null,
        gradient: gradient,
      ),
      child: child,
    );

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        splashColor: AppTheme.bronze.withValues(alpha: 0.08),
        highlightColor: AppTheme.bronze.withValues(alpha: 0.04),
        child: body,
      ),
    );
  }
}

/// Soft ambient wash behind hero surfaces — restrained, not neon.
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
          top: -120,
          right: -40,
          child: _blob(AppTheme.bronze.withValues(alpha: 0.07), 280),
        ),
        Positioned(
          bottom: 80,
          left: -100,
          child: _blob(AppTheme.copper.withValues(alpha: 0.05), 300),
        ),
        child,
      ],
    );
  }

  Widget _blob(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 100, spreadRadius: 24),
          ],
        ),
      ),
    );
  }
}

/// Compact metric chip.
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.labLift,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.labBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.labInk,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Section label used across hubs.
class NfSectionLabel extends StatelessWidget {
  final String text;

  const NfSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.labMuted,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}

/// Clean list row for hubs — no per-row glass cards.
class NfListRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const NfListRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.labLift,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: AppTheme.labBorder),
                    ),
                    child: Icon(icon, size: 20, color: AppTheme.bronzeSoft),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppTheme.labInk,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.labMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 54),
      ],
    );
  }
}

/// Grouped panel wrapping list rows.
class NfGroup extends StatelessWidget {
  final List<Widget> children;

  const NfGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.labCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.labBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(children: children),
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
      duration: const Duration(milliseconds: 420),
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
            offset: Offset(0, (1 - t) * 12),
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
    final s = 0.94 + math.sin(progress * math.pi) * 0.06;
    return Transform.scale(
      scale: s,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
        ),
      ),
    );
  }
}
