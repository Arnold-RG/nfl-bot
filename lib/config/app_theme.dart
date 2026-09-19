import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// NFL BOT — professional dark bronze system.
class AppTheme {
  // Core surfaces
  static const Color labBg = Color(0xFF0A0908);
  static const Color labCard = Color(0xFF171311);
  static const Color labLift = Color(0xFF1F1915);
  static const Color labInk = Color(0xFFF7F1EA);
  static const Color labMuted = Color(0xFF9C8B7A);
  static const Color labBorder = Color(0xFF2C241E);

  // Brand bronze
  static const Color bronze = Color(0xFFC9A27A);
  static const Color bronzeDeep = Color(0xFFA67B52);
  static const Color bronzeSoft = Color(0xFFE2C4A4);
  static const Color copper = Color(0xFFD4A06A);

  // Functional accents that still fit the palette
  static const Color labWater = Color(0xFF6B9EAE); // cool teal for water only
  static const Color labMuscle = Color(0xFF4FA3FF); // anatomy highlight
  static const Color labOrange = bronze;
  static const Color labGreen = Color(0xFF8FA876);
  static const Color labBlue = bronzeDeep;
  static const Color labPink = copper;

  static const Color navy = labBg;
  static const Color navyLift = labLift;
  static const Color navyCard = labCard;
  static const Color electric = bronze;
  static const Color electricDark = bronzeDeep;
  static const Color amber = copper;
  static const Color white = labInk;

  static const Color pacerBlue = bronzeDeep;
  static const Color pacerBlueSoft = bronze;
  static const Color pacerOrange = copper;
  static const Color pacerGreen = labGreen;
  static const Color gravlVolt = copper;

  static const Color primaryColor = bronze;
  static const Color primaryLight = bronzeSoft;
  static const Color primaryDark = bronzeDeep;
  static const Color secondaryColor = copper;
  static const Color accentColor = copper;

  static const Color backgroundColor = labBg;
  static const Color surfaceColor = labCard;
  static const Color textDark = labInk;
  static const Color textLight = labMuted;
  static const Color dividerColor = labBorder;

  static const Color successColor = labGreen;
  static const Color warningColor = copper;
  static const Color errorColor = Color(0xFFE05A4E);

  static const Color darkBg = navy;
  static const Color darkSurface = navyLift;
  static const Color darkCard = navyCard;

  static const Color ink = navy;
  static const Color inkLift = navyLift;
  static const Color card = navyCard;
  static const Color cyan = bronze;
  static const Color magenta = copper;
  static const Color mist = labMuted;

  static TextTheme _textTheme(Brightness brightness) {
    final base = labInk;
    final muted = labMuted;
    final display = GoogleFonts.syne(
      color: base,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    );
    final body = GoogleFonts.dmSans(color: base, height: 1.4);

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
        color: bronze,
      ),
      labelMedium: body.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: bronze,
      brightness: Brightness.dark,
      primary: bronze,
      secondary: copper,
      surface: labLift,
    ).copyWith(onPrimary: labBg, onSurface: labInk, outline: labMuted);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: labBg,
      cardColor: labCard,
      textTheme: _textTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: labBg,
        elevation: 0,
        foregroundColor: labInk,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.syne(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: labInk,
        ),
      ),
      cardTheme: CardThemeData(
        color: labCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: labBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: bronze,
          foregroundColor: labBg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: labInk,
          side: const BorderSide(color: labBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: labLift,
        indicatorColor: bronze.withValues(alpha: 0.2),
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final on = states.contains(WidgetState.selected);
          return GoogleFonts.dmSans(
            color: on ? bronzeSoft : labMuted,
            fontSize: 11,
            fontWeight: on ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final on = states.contains(WidgetState.selected);
          return IconThemeData(color: on ? bronzeSoft : labMuted, size: 24);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: labLift,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: labBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: labBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: bronze, width: 1.4),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme;
}
