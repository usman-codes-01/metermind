import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Builds the light & dark [ThemeData]. Most bespoke surfaces read [AppColors]
/// / `context.palette` directly, but this gives Material widgets sane defaults.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _base(Brightness.light, AppColors.light);
  static ThemeData dark() => _base(Brightness.dark, AppColors.dark);

  static ThemeData _base(Brightness brightness, AppPalette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.petrol,
      brightness: brightness,
      primary: AppColors.petrol,
      secondary: AppColors.copper,
      surface: p.card,
      error: p.alert,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      fontFamily: 'HankenGrotesk',
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            fontFamily: 'HankenGrotesk',
            bodyColor: p.primaryText,
            displayColor: p.primaryText,
          ),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
    );
  }
}
