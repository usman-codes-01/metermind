import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../readings/readings_cubit.dart';
import '../../shell/main_shell.dart';
import 'auth_page.dart';
import 'biometric_lock.dart';

/// Shows the login screen when signed out, and the app (loading this user's
/// data) when signed in. Reacts live to sign-in / sign-out.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        final user = snapshot.data;
        if (user == null) return const AuthPage();
        // Fingerprint lock over the session, then the app. Keyed by uid so a
        // different user re-locks and reloads.
        return BiometricLock(
          key: ValueKey(user.uid),
          child: const _SignedInApp(),
        );
      },
    );
  }
}

class _SignedInApp extends StatefulWidget {
  const _SignedInApp();

  @override
  State<_SignedInApp> createState() => _SignedInAppState();
}

class _SignedInAppState extends State<_SignedInApp> {
  @override
  void initState() {
    super.initState();
    // Load this user's readings once we're signed in.
    context.read<ReadingsCubit>().load();
  }

  @override
  Widget build(BuildContext context) => const MainShell();
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.petrol,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.copper),
      ),
    );
  }
}
