import 'package:shared_preferences/shared_preferences.dart';

/// On-device preference for the fingerprint lock (per device, not per account —
/// biometrics are device-specific). Defaults to ON.
class BiometricPref {
  BiometricPref._();

  static const _key = 'biometric_lock_enabled';

  static Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? true;

  static Future<void> setEnabled(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_key, value);
}
