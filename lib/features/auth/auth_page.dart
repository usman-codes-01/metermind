import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/common_widgets.dart';

/// Email + password sign in / sign up. Ties each user's data to their account
/// so it comes back after a reinstall or on another device.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isLogin = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      if (_isLogin) {
        await auth.signInWithEmailAndPassword(email: email, password: password);
      } else {
        await auth.createUserWithEmailAndPassword(
            email: email, password: password);
      }
      // AuthGate reacts to the sign-in automatically — nothing else to do.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _messageFor(e.code));
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'That email already has an account — try signing in.';
      case 'weak-password':
        return 'Password is too weak (use at least 6 characters).';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and retry.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled in Firebase yet.';
      default:
        return 'Could not sign in ($code).';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          TealHeader(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.copper,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.bolt_rounded,
                          color: AppColors.ink, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text('MeterMind',
                        style: AppType.title(AppColors.paper, size: 22)),
                  ],
                ),
                const SizedBox(height: 18),
                Text(_isLogin ? 'Welcome back' : 'Create your account',
                    style: AppType.displayLg(AppColors.paper)
                        .copyWith(fontSize: 26)),
                const SizedBox(height: 4),
                Text(
                  'Sign in so your readings stay safe and come back on any device.',
                  style: AppType.body(AppColors.paper.withAlpha(0xCC), size: 13),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Password',
                    hint: 'At least 6 characters',
                    controller: _password,
                    obscure: true,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _ErrorBox(message: _error!),
                  ],
                  const SizedBox(height: 22),
                  BigButton(
                    label: _busy
                        ? 'Please wait…'
                        : (_isLogin ? 'Sign in' : 'Create account'),
                    copper: true,
                    enabled: !_busy,
                    onPressed: _busy ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _isLogin = !_isLogin;
                        _error = null;
                      }),
              child: Text.rich(
                TextSpan(
                  text: _isLogin
                      ? "Don't have an account?  "
                      : 'Already have an account?  ',
                  style: AppType.body(p.secondaryText, size: 13),
                  children: [
                    TextSpan(
                      text: _isLogin ? 'Create one' : 'Sign in',
                      style: AppType.label(AppColors.copper, size: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final alert = context.palette.alert;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: alert.withAlpha(0x1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alert.withAlpha(0x55)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: alert, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Text(message,
                style: AppType.label(alert, size: 12.5).copyWith(height: 1.25)),
          ),
        ],
      ),
    );
  }
}
