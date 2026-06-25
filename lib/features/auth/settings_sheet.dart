import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../readings/readings_cubit.dart';
import 'biometric_pref.dart';

/// Settings bottom sheet: fingerprint-lock on/off + sign out.
Future<void> showSettings(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _biometric = true;

  @override
  void initState() {
    super.initState();
    BiometricPref.isEnabled().then((v) {
      if (mounted) setState(() => _biometric = v);
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _biometric = value);
    await BiometricPref.setEnabled(value);
  }

  Future<void> _signOut() async {
    final cubit = context.read<ReadingsCubit>();
    Navigator.of(context).pop();
    cubit.reset();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.secondaryText.withAlpha(0x55),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Settings', style: AppType.title(p.primaryText, size: 20)),
            const SizedBox(height: 18),
            // Fingerprint toggle.
            Row(
              children: [
                Icon(Icons.fingerprint_rounded, color: AppColors.copper, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fingerprint unlock',
                          style: AppType.label(p.primaryText, size: 14)),
                      const SizedBox(height: 2),
                      Text('Ask for fingerprint each time you open the app.',
                          style: AppType.caption(p.secondaryText, size: 11.5)),
                    ],
                  ),
                ),
                Switch(
                  value: _biometric,
                  activeTrackColor: AppColors.copper,
                  onChanged: _toggleBiometric,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: p.secondaryText.withAlpha(0x22)),
            const SizedBox(height: 8),
            // Sign out.
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _signOut,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: p.alert, size: 20),
                    const SizedBox(width: 12),
                    Text('Sign out', style: AppType.label(p.alert, size: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
