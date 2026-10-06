import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// NFL BOT — calm charcoal + warm bronze. One accent, clear hierarchy.
class AppTheme {
  // Surfaces — near-black charcoal, not muddy brown
  static const Color labBg = Color(0xFF0C0C0B);
  static const Color labCard = Color(0xFF161614);
  static const Color labLift = Color(0xFF1C1C1A);
  static const Color labInk = Color(0xFFF4F1EC);
  static const Color labMuted = Color(0xFF8A857C);
  static const Color labBorder = Color(0xFF2A2926);

  // Brand — warm bronze, used sparingly
  static const Color bronze = Color(0xFFC4A484);
  static const Color bronzeDeep = Color(0xFF9A7A58);
  static const Color bronzeSoft = Color(0xFFD9C4A8);
  static const Color copper = Color(0xFFC9966A);

  // Functional accents
  static const Color labWater = Color(0xFF7A9EAE);
  static const Color labMuscle = Color(0xFF6BA3E0);
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
  static const Color errorColor = Color(0xFFD96B5F);

  static const Color darkBg = navy;
  static const Color darkSurface = navyLift;
  static const Color darkCard = navyCard;

  static const Color ink = navy;
  static const Color inkLift = navyLift;
  static const Color card = navyCard;
  static const Color cyan = bronze;
  static const Color magenta = copper;
  static const Color mist = labMuted;

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;

  static TextTheme _textTheme(Brightness brightness) {
    final base = labInk;
    final muted = labMuted;
    final display = GoogleFonts.outfit(
      color: base,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.6,
      height: 1.15,
    );
    final body = GoogleFonts.inter(color: base, height: 1.45, letterSpacing: -0.1);

    return TextTheme(
      displayLarge: display.copyWith(fontSize: 36, fontWeight: FontWeight.w700),
      displayMedium: display.copyWith(fontSize: 30, fontWeight: FontWeight.w700),
      displaySmall: display.copyWith(fontSize: 26, fontWeight: FontWeight.w600),
      headlineMedium: display.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
      titleLarge: display.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
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
        letterSpacing: 0.6,
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
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: labCard,
        elevation: 0,
        height: 68,
        indicatorColor: bronze.withValues(alpha: 0.16),
        overlayColor: WidgetStatePropertyAll(
          bronze.withValues(alpha: 0.06),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final on = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            color: on ? bronzeSoft : labMuted,
            fontSize: 11,
            fontWeight: on ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: -0.1,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final on = states.contains(WidgetState.selected);
          return IconThemeData(
            color: on ? bronzeSoft : labMuted,
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
          borderSide: const BorderSide(color: bronze, width: 1.2),
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
