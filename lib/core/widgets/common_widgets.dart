import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Petrol header block with the signature `0 0 30 30` bottom radius.
class TealHeader extends StatelessWidget {
  const TealHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(22, 20, 22, 24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: p.headerBlock,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(bottom: false, child: child),
    );
  }
}

/// Soft white card. `0 1px 2px rgba(0,0,0,.04)` shadow per the brief.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 18,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: card,
    );
  }
}

/// Full-width primary button. Petrol by default; copper for signup/FAB CTAs.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.copper = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool copper;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bg = !enabled
        ? const Color(0xFFCDCBC3)
        : (copper ? AppColors.copper : AppColors.petrol);
    final fg = !enabled
        ? const Color(0xFF8C8A82)
        : (copper ? AppColors.ink : AppColors.paper);
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onPressed : null,
          child: Center(child: Text(label, style: AppType.button(fg))),
        ),
      ),
    );
  }
}

/// Rounded pill (999px radius).
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.onTap,
    this.border,
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.paper,
        borderRadius: BorderRadius.circular(999),
        border: border != null ? Border.all(color: border!, width: 1.2) : null,
      ),
      child: child,
    );
    if (onTap == null) return pill;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: pill,
    );
  }
}

/// Section header used above lists ("Readings", etc).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Text(text, style: AppType.title(p.primaryText, size: 17)),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}
