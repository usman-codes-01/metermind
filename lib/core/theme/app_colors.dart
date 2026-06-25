import 'package:flutter/material.dart';

/// Centralised colour palette for MeterMind ("Deep Calm").
///
/// Exact values are taken from the design brief. Light and dark surfaces are
/// grouped into [AppPalette] so the [ThemeData] (and bespoke widgets) can read
/// the right set for the active brightness.
class AppColors {
  AppColors._();

  // Brand constants — identical across light & dark.
  static const Color paper = Color(0xFFF2F0EA);
  static const Color petrol = Color(0xFF0E3B3A);
  static const Color ink = Color(0xFF15302F);
  static const Color copper = Color(0xFFE0A33C);
  static const Color alert = Color(0xFFC8463A);
  static const Color white = Color(0xFFFFFFFF);

  // Dark-mode surfaces.
  static const Color darkBg = Color(0xFF0A1F1E);
  static const Color darkCard = Color(0xFF12302E);
  static const Color darkRaised = Color(0xFF16403D);
  static const Color darkText = Color(0xFFEAF0EC);
  static const Color darkAlert = Color(0xFFE8675A);

  // Secondary-text alphas applied over [ink].
  static Color inkSecondary = ink.withAlpha(0xE0); // ~88%
  static Color inkFaint = ink.withAlpha(0xCC); // ~80%

  static const AppPalette light = AppPalette(
    background: paper,
    card: white,
    raised: paper,
    headerBlock: petrol,
    primaryText: ink,
    secondaryText: Color(0xCC15302F),
    alert: alert,
    onHeader: paper,
  );

  static const AppPalette dark = AppPalette(
    background: darkBg,
    card: darkCard,
    raised: darkRaised,
    headerBlock: darkCard,
    primaryText: darkText,
    secondaryText: Color(0xCCEAF0EC),
    alert: darkAlert,
    onHeader: darkText,
  );
}

/// Resolved set of surface/text colours for a given brightness.
class AppPalette {
  const AppPalette({
    required this.background,
    required this.card,
    required this.raised,
    required this.headerBlock,
    required this.primaryText,
    required this.secondaryText,
    required this.alert,
    required this.onHeader,
  });

  final Color background;
  final Color card;
  final Color raised;
  final Color headerBlock;
  final Color primaryText;
  final Color secondaryText;
  final Color alert;
  final Color onHeader;
}

/// Convenience accessor: `context.palette`.
extension PaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).brightness == Brightness.dark
          ? AppColors.dark
          : AppColors.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
