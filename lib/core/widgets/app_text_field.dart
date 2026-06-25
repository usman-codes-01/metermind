import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Calm, banking-app input. 14px radius, soft fill, mono option for the
/// bill-reference / meter fields.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.mono = false,
    this.helper,
    this.suffix,
    this.inputFormatters,
    this.onChanged,
    this.onSurfaceDark = false,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final bool mono;
  final String? helper;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  /// When the field sits on a petrol surface (e.g. Add Reading card).
  final bool onSurfaceDark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final labelColor = onSurfaceDark ? AppColors.paper.withAlpha(0xCC) : p.secondaryText;
    final textColor = onSurfaceDark ? AppColors.paper : p.primaryText;
    final fill = onSurfaceDark ? Colors.white.withAlpha(0x14) : p.background;

    final textStyle = mono
        ? AppType.mono(textColor, size: 16)
        : AppType.body(textColor, size: 15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppType.caption(labelColor, size: 10.5)
                .copyWith(letterSpacing: 0.8)),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: textStyle,
          cursorColor: AppColors.copper,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: textStyle.copyWith(
                color: textColor.withAlpha(0x66), letterSpacing: mono ? 1 : 0),
            filled: true,
            fillColor: fill,
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: onSurfaceDark
                  ? BorderSide(color: Colors.white.withAlpha(0x1A))
                  : BorderSide(color: AppColors.ink.withAlpha(0x12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.copper, width: 1.5),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(helper!, style: AppType.caption(labelColor, size: 11)),
        ],
      ],
    );
  }
}
