import 'package:flutter/material.dart';

/// Bundled-font helpers. These replace `GoogleFonts.*` calls so text
/// renders instantly offline — google_fonts downloads fonts at runtime
/// on first use, which stalled the splash/logo screen on cold start.
class AppFonts {
  AppFonts._();

  /// Serif display face (titles, headings, big Anywaa words).
  /// Mirrors the GoogleFonts.playfairDisplay signature used in the app.
  static TextStyle playfair({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    TextBaseline? textBaseline,
    TextDecoration? decoration,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
  }) {
    return TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      textBaseline: textBaseline,
      decoration: decoration,
      shadows: shadows,
      fontFeatures: fontFeatures,
    );
  }

  /// Sans UI face. Mirrors GoogleFonts.nunitoTextTheme.
  static TextTheme nunitoTextTheme(TextTheme textTheme) {
    return textTheme.apply(fontFamily: 'Nunito');
  }
}
