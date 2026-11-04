import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Brand accent tokens (readable on both light and dark surfaces) ───────────
const kGreen    = Color(0xFF1F4D3A); // forest green (solid surfaces, buttons)
const kGreenMid = Color(0xFF2D6A4F);
const kGold     = Color(0xFFC9993A);
const kRust     = Color(0xFFA8472A); // terracotta, play buttons

// ── Legacy light tokens (kept for const contexts; new code uses context.c) ───
const kBg       = Color(0xFFF6EFE3); // sand
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

// ── Semantic, theme-aware palette ────────────────────────────────────────────
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.card,
    required this.text,
    required this.textSub,
    required this.border,
    required this.accent,
  });

  final Color bg;      // scaffold background
  final Color card;    // raised surface (cards, panels)
  final Color text;    // primary text
  final Color textSub; // secondary / muted text
  final Color border;  // hairlines, dividers
  final Color accent;  // readable brand green for icons / labels

  static const AppColors light = AppColors(
    bg: Color(0xFFF6EFE3),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF1B1F1C),
    textSub: Color(0xFF5B625D),
    border: Color(0xFFE4DACB),
    accent: Color(0xFF1F4D3A),
  );

  static const AppColors dark = AppColors(
    bg: Color(0xFF101512),
    card: Color(0xFF1B221D),
    text: Color(0xFFECEAE4),
    textSub: Color(0xFFA7B0A8),
    border: Color(0xFF2C352E),
    accent: Color(0xFF7FB896),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? card,
    Color? text,
    Color? textSub,
    Color? border,
    Color? accent,
  }) =>
      AppColors(
        bg: bg ?? this.bg,
        card: card ?? this.card,
        text: text ?? this.text,
        textSub: textSub ?? this.textSub,
        border: border ?? this.border,
        accent: accent ?? this.accent,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSub: Color.lerp(textSub, other.textSub, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

/// Convenience accessor: `context.c.text`, `context.c.card`, …
extension AppColorsX on BuildContext {
  AppColors get c =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}

// ── Shared decoration helpers (theme-aware) ──────────────────────────────────
BoxDecoration cardDeco(BuildContext context,
        {Color? color, bool shadow = true, double radius = 18}) =>
    BoxDecoration(
      color: color ?? context.c.card,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadow ? const [kShadowSoft] : null,
    );

BoxDecoration gridCellDeco(BuildContext context,
        {required bool learned, Color? accentColor}) =>
    BoxDecoration(
      color: learned
          ? (accentColor ?? context.c.accent).withValues(alpha: 0.10)
          : context.c.card,
      borderRadius: BorderRadius.circular(18),
      border: learned
          ? Border.all(
              color: (accentColor ?? context.c.accent).withValues(alpha: 0.4))
          : null,
      boxShadow: const [kShadowSoft],
    );

BoxDecoration detailCardDeco(BuildContext context,
        {required bool learned}) =>
    BoxDecoration(
      color: learned
          ? context.c.accent.withValues(alpha: 0.08)
          : context.c.card,
      borderRadius: BorderRadius.circular(22),
      border: learned ? Border.all(color: context.c.accent, width: 1.5) : null,
      boxShadow: const [kShadowCard],
    );

// ── Theme ─────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static TextTheme _textTheme({required Color text, required Color textSub}) {
    final sans = GoogleFonts.nunitoTextTheme(
      TextTheme(
        displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: text),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: text),
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: text),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: text),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: text),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: text),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: text),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text),
        bodyLarge: TextStyle(fontSize: 16, color: text),
        bodyMedium: TextStyle(fontSize: 14, color: textSub),
        bodySmall: TextStyle(fontSize: 12, color: textSub),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
      ),
    );

    // Serif display face for titles and the big Anywaa words.
    return sans.copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 40, fontWeight: FontWeight.w700, color: text),
      displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 32, fontWeight: FontWeight.w700, color: text),
      headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 28, fontWeight: FontWeight.w700, color: text),
      headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 24, fontWeight: FontWeight.w700, color: text),
    );
  }

  static ThemeData _build(AppColors c, Brightness brightness) {
    final textTheme = _textTheme(text: c.text, textSub: c.textSub);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kGreen,
        brightness: brightness,
        surface: c.card,
        primary: kGreen,
      ),
      textTheme: textTheme,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: c.text,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: c.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
          foregroundColor: c.accent,
          side: BorderSide(color: c.accent),
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
          foregroundColor: c.accent,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.card,
        selectedItemColor: c.accent,
        unselectedItemColor: c.textSub,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold, fontSize: 19, color: c.text,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: c.textSub, height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: kGreen,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.border,
      ),
      dividerTheme: DividerThemeData(
        color: c.border, thickness: 1, space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.accent,
        titleTextStyle: textTheme.titleSmall?.copyWith(color: c.text),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: c.textSub),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : c.textSub),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? kGreenMid : c.border),
        // Without this, Material 3 paints the off-state track outline from the
        // green seed color, so the toggle reads as "green" on a light surface
        // while looking fine in dark mode. Keep it neutral instead.
        trackOutlineColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.transparent : c.border),
      ),
    );
  }

  static ThemeData get data => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);
}
