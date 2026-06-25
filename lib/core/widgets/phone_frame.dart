import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centres the app inside a 390×830 portrait phone frame (42px radius) so the
/// editorial layout reads the same on web/desktop previews.
///
/// On real handsets (Android/iOS) — and on any window too small to hold the
/// frame — this is a pass-through: the app fills the screen using the device's
/// true metrics so `SafeArea`, sizing and scrolling all behave normally.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  static const double width = 390;
  static const double height = 830;
  static const double radius = 42;

  @override
  Widget build(BuildContext context) {
    // Real handsets: let the app own the whole screen with real device metrics.
    final isHandset = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    // Wide previews (web/desktop) only get the frame when there's room for it.
    final screen = MediaQuery.sizeOf(context);
    final fits = screen.width >= width && screen.height >= height;

    if (isHandset || !fits) return child;

    return Container(
      color: const Color(0xFFDED9CE), // calm stage behind the device
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 40,
                offset: Offset(0, 18),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: MediaQuery(
            // Fixed logical size so child layouts are deterministic.
            data: MediaQuery.of(context).copyWith(
              size: const Size(width, height),
              devicePixelRatio: 1,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
