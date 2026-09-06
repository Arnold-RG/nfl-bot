import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared layout helpers so screens look correct in light and dark mode.
class AppLayout {
  static const double screenPadding = 20;
  static const double bottomNavClearance = 100;

  static Color subtitleColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

  static TextStyle subtitleStyle(BuildContext context) => GoogleFonts.dmSans(
        fontSize: 14,
        color: subtitleColor(context),
      );

  static TextStyle screenTitleStyle(BuildContext context) => GoogleFonts.syne(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.4,
      );

  static BoxDecoration cardDecoration(BuildContext context, {double radius = 20}) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(radius),
      border: isLight
          ? null
          : Border.all(color: Colors.white.withValues(alpha: 0.08)),
      boxShadow: isLight
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    );
  }

  static BoxDecoration accentCardDecoration(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return BoxDecoration(
      color: primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: primary.withValues(alpha: 0.25)),
    );
  }
}
