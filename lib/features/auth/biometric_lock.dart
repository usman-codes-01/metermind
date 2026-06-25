import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/common_widgets.dart';
import 'biometric_pref.dart';

/// Fingerprint / biometric lock over the already-signed-in session. Shows a
/// lock screen until the user passes biometric (or device PIN) auth. If the
/// device has no biometrics set up, it transparently lets the user through —
/// it never traps them out of their own data.
class BiometricLock extends StatefulWidget {
  const BiometricLock({super.key, required this.child});

  final Widget child;

  @override
  State<BiometricLock> createState() => _BiometricLockState();
}

class _BiometricLockState extends State<BiometricLock> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _unlocked = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      // Respect the user's on/off setting first.
      if (!await BiometricPref.isEnabled()) {
        setState(() {
          _unlocked = true;
          _checking = false;
        });
        return;
      }
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported && !canCheck) {
        // No biometric hardware / nothing enrolled → don't lock the user out.
        setState(() {
          _unlocked = true;
          _checking = false;
        });
        return;
      }
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock MeterMind',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow device PIN/pattern as a fallback
        ),
      );
      setState(() {
        _unlocked = ok;
        _checking = false;
      });
    } on PlatformException catch (_) {
      // Biometrics unavailable/errored — fall through rather than trap the user.
      setState(() {
        _unlocked = true;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;

    return Scaffold(
      backgroundColor: AppColors.petrol,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(0x14),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(Icons.fingerprint_rounded,
                    color: AppColors.copper, size: 48),
              ),
              const SizedBox(height: 24),
              Text('MeterMind is locked',
                  style: AppType.title(AppColors.paper, size: 20)),
              const SizedBox(height: 8),
              Text(
                'Unlock with your fingerprint to see your readings.',
                textAlign: TextAlign.center,
                style: AppType.body(AppColors.paper.withAlpha(0xCC), size: 13.5),
              ),
              const SizedBox(height: 30),
              BigButton(
                label: _checking ? 'Checking…' : 'Unlock',
                copper: true,
                enabled: !_checking,
                onPressed: _checking ? null : _check,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: Text('Sign out instead',
                    style: AppType.label(AppColors.paper.withAlpha(0xCC))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
