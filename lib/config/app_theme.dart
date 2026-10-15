import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Elvora — warm clay ground, ember orange accent, sand ink.
/// Fitness / nutrition palette (not purple).
class AppTheme {
  // Surfaces — warm clay
  static const Color labBg = Color(0xFF1A120C);
  static const Color labCard = Color(0xFF241A12);
  static const Color labLift = Color(0xFF2E2116);
  static const Color labInk = Color(0xFFF3D9B1);
  static const Color labMuted = Color(0xFFB89A78);
  static const Color labBorder = Color(0xFF3D2C1E);

  // Brand — ember + sand
  static const Color bronze = Color(0xFFE08A45);
  static const Color bronzeDeep = Color(0xFFC46A2E);
  static const Color bronzeSoft = Color(0xFFF3D9B1);
  static const Color copper = Color(0xFFE8A06A);
  static const Color sand = Color(0xFFF3D9B1);
  static const Color clay = Color(0xFF1A120C);
  static const Color ember = Color(0xFFE08A45);

  // Functional accents (warm-adjacent, still readable)
  static const Color labWater = Color(0xFF7BA8B8);
  static const Color labMuscle = Color(0xFFE08A45);
  static const Color labOrange = ember;
  static const Color labGreen = Color(0xFF9BB87A);
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
  static const Color errorColor = Color(0xFFE07A6A);

  static const Color darkBg = navy;
  static const Color darkSurface = navyLift;
  static const Color darkCard = navyCard;

  static const Color ink = navy;
  static const Color inkLift = navyLift;
  static const Color card = navyCard;
  static const Color cyan = bronze;
  static const Color magenta = copper;
  static const Color mist = labMuted;

  static const double radiusSm = 14;
  static const double radiusMd = 18;
  static const double radiusLg = 24;

  static TextTheme _textTheme(Brightness brightness) {
    final base = labInk;
    final muted = labMuted;
    final display = GoogleFonts.syne(
      color: base,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.7,
      height: 1.12,
    );
    final body = GoogleFonts.dmSans(
      color: base,
      height: 1.45,
      letterSpacing: -0.1,
    );

    return TextTheme(
      displayLarge: display.copyWith(fontSize: 36, fontWeight: FontWeight.w800),
      displayMedium: display.copyWith(fontSize: 30, fontWeight: FontWeight.w800),
      displaySmall: display.copyWith(fontSize: 26, fontWeight: FontWeight.w700),
      headlineMedium: display.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
      titleLarge: display.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
      titleMedium: body.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: body.copyWith(fontSize: 16),
      bodyMedium: body.copyWith(fontSize: 14, color: muted),
      bodySmall: body.copyWith(fontSize: 12, color: muted),
      labelLarge: body.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: bronzeSoft,
        letterSpacing: 0.2,
      ),
      labelMedium: body.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: muted,
      ),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: bronze,
      brightness: Brightness.dark,
      primary: bronze,
      secondary: copper,
      surface: labCard,
    ).copyWith(
      onPrimary: labBg,
      onSurface: labInk,
      outline: labBorder,
      surfaceContainerHighest: labLift,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: labBg,
      cardColor: labCard,
      dividerColor: labBorder,
      textTheme: _textTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: labBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: labInk,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.syne(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: labInk,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: labCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: labBorder, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: bronze,
          foregroundColor: labBg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: labInk,
          side: const BorderSide(color: labBorder),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: bronzeSoft,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: labCard.withValues(alpha: 0.96),
        elevation: 0,
        height: 70,
        indicatorColor: bronze.withValues(alpha: 0.18),
        overlayColor: WidgetStatePropertyAll(
          bronze.withValues(alpha: 0.08),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final on = states.contains(WidgetState.selected);
          return GoogleFonts.dmSans(
            color: on ? bronzeSoft : labMuted,
            fontSize: 11,
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: -0.1,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final on = states.contains(WidgetState.selected);
          return IconThemeData(
            color: on ? bronze : labMuted,
            size: 22,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: labLift,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: labBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: labBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: bronze, width: 1.4),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: labMuted,
        textColor: labInk,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: labBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme;
}
