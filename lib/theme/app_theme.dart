import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Palette ────────────────────────────────────────────────
  static const Color primaryRose    = Color(0xFFC06080);
  static const Color darkRose       = Color(0xFF8A3A56);
  static const Color lightRose      = Color(0xFFF7D6E4);
  static const Color gold           = Color(0xFFC9A96E);
  static const Color softGold       = Color(0xFFF5ECD7);
  static const Color bgStart        = Color(0xFFFFF8FB);
  static const Color bgEnd          = Color(0xFFFCE8F3);
  static const Color textDark       = Color(0xFF2D1420);
  static const Color textMedium     = Color(0xFF7A4E5E);
  static const Color textLight      = Color(0xFFB08090);
  static const Color cardBg         = Color(0xFFFFFFFF);
  static const Color dividerColor   = Color(0xFFEDD5E2);
  static const Color errorRed       = Color(0xFFD03060);

  // ─── Gradient Helpers ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [darkRose, primaryRose],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [bgStart, bgEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFC9A96E), Color(0xFFE8C88A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Theme ────────────────────────────────────────────────────────
  static ThemeData get light {
    final textTheme = GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 40, fontWeight: FontWeight.w700, color: textDark),
      displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 32, fontWeight: FontWeight.w700, color: textDark),
      displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 26, fontWeight: FontWeight.w700, color: textDark),
      headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 24, fontWeight: FontWeight.w700, color: textDark),
      headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
      headlineSmall: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
      titleLarge: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
      titleMedium: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w500, color: textDark),
      titleSmall: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w600, color: textMedium),
      bodyLarge: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w400, color: textDark),
      bodyMedium: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w400, color: textMedium),
      bodySmall: GoogleFonts.poppins(
          fontSize: 11, fontWeight: FontWeight.w400, color: textLight),
      labelLarge: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600, color: cardBg),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryRose,
        onPrimary: Colors.white,
        primaryContainer: lightRose,
        onPrimaryContainer: darkRose,
        secondary: gold,
        onSecondary: Colors.white,
        secondaryContainer: softGold,
        onSecondaryContainer: Color(0xFF7A5A20),
        tertiary: Color(0xFF9B72AA),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFF3E8FC),
        onTertiaryContainer: Color(0xFF5C3570),
        error: errorRed,
        onError: Colors.white,
        errorContainer: Color(0xFFFCE4EC),
        onErrorContainer: Color(0xFF8B1040),
        surface: cardBg,
        onSurface: textDark,
        surfaceContainerHighest: Color(0xFFF5E8EF),
        onSurfaceVariant: textMedium,
        outline: dividerColor,
        outlineVariant: Color(0xFFEDD5E2),
        shadow: Colors.black12,
        scrim: Colors.black54,
        inverseSurface: textDark,
        onInverseSurface: Colors.white,
        inversePrimary: lightRose,
      ),
      scaffoldBackgroundColor: bgStart,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        iconTheme: const IconThemeData(color: textDark),
        actionsIconTheme: const IconThemeData(color: primaryRose),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: dividerColor, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgEnd,
        selectedColor: primaryRose,
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: dividerColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRose,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryRose,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryRose,
          side: const BorderSide(color: primaryRose),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryRose,
          textStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFF0F7),
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
          borderSide: const BorderSide(color: primaryRose, width: 1.5),
        ),
        labelStyle: GoogleFonts.poppins(color: textLight, fontSize: 13),
        hintStyle: GoogleFonts.poppins(color: textLight, fontSize: 13),
        prefixIconColor: textLight,
        suffixIconColor: textLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryRose,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBg,
        indicatorColor: lightRose,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
                fontSize: 10, fontWeight: FontWeight.w600, color: primaryRose);
          }
          return GoogleFonts.poppins(
              fontSize: 10, fontWeight: FontWeight.w400, color: textLight);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryRose, size: 22);
          }
          return const IconThemeData(color: textLight, size: 22);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textDark,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
