import 'package:flutter/material.dart';

/// Typography system. Fonts are bundled as local variable TTFs (see pubspec) so
/// they render on the very first frame with no network fetch.
///
/// - Archivo (700–900): display, big numbers, buttons, titles. Tight tracking.
/// - Hanken Grotesk (400/600): UI labels and body.
/// - Spline Sans Mono (500/600): meter digits and numbers (odometer feel).
class AppType {
  AppType._();

  static const String _display = 'Archivo';
  static const String _ui = 'HankenGrotesk';
  static const String _mono = 'SplineSansMono';

  static TextStyle displayLg(Color color) => TextStyle(
        fontFamily: _display,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.03 * 34,
        color: color,
      );

  static TextStyle title(Color color, {double size = 20}) => TextStyle(
        fontFamily: _display,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * size,
        color: color,
      );

  static TextStyle button(Color color) => TextStyle(
        fontFamily: _display,
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01 * 16,
        color: color,
      );

  // ---- Hanken Grotesk (UI / body) ----
  static TextStyle body(Color color, {double size = 14}) => TextStyle(
        fontFamily: _ui,
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color,
      );

  static TextStyle label(Color color, {double size = 13}) => TextStyle(
        fontFamily: _ui,
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle caption(Color color, {double size = 11}) => TextStyle(
        fontFamily: _ui,
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
      );

  // ---- Spline Sans Mono (digits / numbers) ----
  static TextStyle mono(Color color,
          {double size = 16, FontWeight weight = FontWeight.w600}) =>
      TextStyle(
        fontFamily: _mono,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: 0.5,
        color: color,
      );
}
