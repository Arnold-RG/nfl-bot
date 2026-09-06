import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// NFL BOT design language: deep navy + electric green + calm white.
class AppTheme {
  static const Color navy = Color(0xFF0B1220);
  static const Color navyLift = Color(0xFF121A2B);
  static const Color navyCard = Color(0xFF182235);
  static const Color electric = Color(0xFF22E38A);
  static const Color electricDark = Color(0xFF12B76A);
  static const Color amber = Color(0xFFF5A524);
  static const Color white = Color(0xFFF7F9FC);

  /// Pacer-inspired metric accents (Home / activity).
  static const Color pacerBlue = Color(0xFF3B82F6);
  static const Color pacerBlueSoft = Color(0xFF93C5FD);
  static const Color pacerOrange = Color(0xFFF97316);
  static const Color pacerGreen = Color(0xFF22C55E);

  /// Gravl-inspired volt accent for Train.
  static const Color gravlVolt = Color(0xFFC8F542);

  static const Color primaryColor = pacerBlue;
  static const Color primaryLight = electric;
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondaryColor = electric;
  static const Color accentColor = amber;

  static const Color backgroundColor = Color(0xFFF2F4F8);
  static const Color surfaceColor = Colors.white;
  static const Color textDark = Color(0xFF0B1220);
  static const Color textLight = Color(0xFF667085);
  static const Color dividerColor = Color(0xFFE4E7EC);

  static const Color successColor = electricDark;
  static const Color warningColor = amber;
  static const Color errorColor = Color(0xFFEF4444);

  static const Color darkBg = navy;
  static const Color darkSurface = navyLift;
  static const Color darkCard = navyCard;

  // Legacy aliases
  static const Color ink = navy;
  static const Color inkLift = navyLift;
  static const Color card = navyCard;
  static const Color cyan = electric;
  static const Color magenta = Color(0xFFFB7185);
  static const Color mist = Color(0xFF93A0B8);

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.light ? textDark : white;
    final muted = brightness == Brightness.light ? textLight : mist;
    final display = GoogleFonts.plusJakartaSans(
      color: base,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.35,
    );
    final body = GoogleFonts.inter(color: base, height: 1.4);

    return TextTheme(
      displayLarge: display.copyWith(fontSize: 34),
      displayMedium: display.copyWith(fontSize: 28),
      displaySmall: display.copyWith(fontSize: 24),
      headlineMedium: display.copyWith(fontSize: 22),
      titleLarge: display.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: body.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: body.copyWith(fontSize: 16),
      bodyMedium: body.copyWith(fontSize: 14, color: muted),
      bodySmall: body.copyWith(fontSize: 12, color: muted),
      labelLarge: body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      labelMedium: body.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
    );
  }

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: electricDark,
      surface: surfaceColor,
    ).copyWith(onPrimary: Colors.white, onSurface: textDark, outline: dividerColor);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: _textTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: textDark,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        height: 70,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final on = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            color: on ? primaryColor : textLight,
            fontSize: 11,
            fontWeight: on ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final on = states.contains(WidgetState.selected);
          return IconThemeData(color: on ? primaryColor : textLight, size: 24);
        }),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: dividerColor),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: const BorderSide(color: dividerColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerColor: dividerColor,
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: electric,
      brightness: Brightness.dark,
      primary: electric,
      secondary: amber,
      surface: navyLift,
    ).copyWith(onPrimary: navy, onSurface: white, outline: Colors.white12);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: navy,
      cardColor: navyCard,
      textTheme: _textTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: navy,
        elevation: 0,
        foregroundColor: white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: white,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navyLift,
        elevation: 0,
        height: 70,
        indicatorColor: electric.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final on = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            color: on ? electric : mist,
            fontSize: 11,
            fontWeight: on ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: navyCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: electric,
          foregroundColor: navy,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: navyCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: electric, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: navyCard,
        contentTextStyle: GoogleFonts.inter(color: white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
