import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Colour tokens ─────────────────────────────────────────────────────────────
const kBg       = Color(0xFFF6EFE3); // sand
const kGreen    = Color(0xFF1F4D3A); // forest green
const kGreenMid = Color(0xFF2D6A4F);
const kGold     = Color(0xFFC9993A);
const kRust     = Color(0xFFA8472A); // terracotta, play buttons
const kText     = Color(0xFF1B1F1C);
const kTextSub  = Color(0xFF5B625D);
const kTextMuted= Color(0xFF5B625D);
const kBorder   = Color(0xFFE4DACB);

// ── Shared shadows ─────────────────────────────────────────────────────────────
const kShadowSoft = BoxShadow(
  color: Color(0x0D000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

const kShadowCard = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 12,
  offset: Offset(0, 4),
);

const kShadowBtn = BoxShadow(
  color: Color(0x26000000),
  blurRadius: 10,
  offset: Offset(0, 4),
);

// ── Shared decoration helpers ─────────────────────────────────────────────────
BoxDecoration cardDeco({Color? color, bool shadow = true, double radius = 18}) =>
    BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadow ? const [kShadowSoft] : null,
    );

BoxDecoration gridCellDeco({required bool learned, Color? accentColor}) =>
    BoxDecoration(
      color: learned
          ? (accentColor ?? kGreen).withValues(alpha: 0.07)
          : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: learned
          ? Border.all(color: (accentColor ?? kGreen).withValues(alpha: 0.4))
          : null,
      boxShadow: const [kShadowSoft],
    );

BoxDecoration detailCardDeco({required bool learned}) => BoxDecoration(
      color: learned ? kGreen.withValues(alpha: 0.06) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: learned ? Border.all(color: kGreen, width: 1.5) : null,
      boxShadow: const [kShadowCard],
    );

// ── Theme ─────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get data {
    final sansTextTheme = GoogleFonts.nunitoTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: kText),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kText),
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kText),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kText),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kText),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kText),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText),
        bodyLarge: TextStyle(fontSize: 16, color: kText),
        bodyMedium: TextStyle(fontSize: 14, color: kTextSub),
        bodySmall: TextStyle(fontSize: 12, color: kTextSub),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
      ),
    );

    // Serif display face for titles and the big Anywaa words, matching the
    // new UI mockups. Body and labels stay on the rounded sans.
    final textTheme = sansTextTheme.copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 40, fontWeight: FontWeight.w700, color: kText),
      displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 32, fontWeight: FontWeight.w700, color: kText),
      headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 28, fontWeight: FontWeight.w700, color: kText),
      headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 24, fontWeight: FontWeight.w700, color: kText),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: kBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kGreen,
        surface: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: kText,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: kText,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kGreen,
          side: const BorderSide(color: kGreen),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kGreen,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: kGreen,
        unselectedItemColor: kTextSub,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold, fontSize: 19,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: kTextSub, height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: kGreen,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: kGreen,
        linearTrackColor: kBorder,
      ),
      dividerTheme: const DividerThemeData(
        color: kBorder, thickness: 1, space: 1,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: kTextMuted),
      ),
    );
  }
}
