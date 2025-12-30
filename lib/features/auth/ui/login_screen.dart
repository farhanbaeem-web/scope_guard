// lib/features/auth/ui/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../logic/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await AuthService.instance.signInWithEmail(
        email: _email.text.trim().toLowerCase(),
        password: _pass.text.trim(),
      );

      // Router redirect will auto-send user to dashboard
      if (mounted) context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyAuthError(e.toString()))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyAuthError(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('wrong-password') || s.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    }
    if (s.contains('user-not-found')) {
      return 'No account found for this email.';
    }
    if (s.contains('email-already-in-use')) {
      return 'This email is already registered. Try logging in.';
    }
    if (s.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (s.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    return 'Auth error: $raw';
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Welcome back';
    const subtitle = 'Log in to track scope creep and protect your income.';

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.shield_rounded,
                                color: AppColors.primary.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Scope Guard',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 220.ms)
                            .slideX(begin: -.03, end: 0),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        )
                            .animate()
                            .fadeIn(duration: 240.ms)
                            .slideY(begin: .08, end: 0),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.subtext),
                        )
                            .animate()
                            .fadeIn(duration: 240.ms)
                            .slideY(begin: .08, end: 0),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_rounded),
                            suffixIcon: _email.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear email',
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () => _email.clear(),
                                  ),
                          ),
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Email is required';
                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        )
                            .animate()
                            .fadeIn(duration: 220.ms)
                            .slideY(begin: .06, end: 0),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pass,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_rounded),
                            suffixIcon: IconButton(
                              tooltip:
                                  _obscure ? 'Show password' : 'Hide password',
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Password is required';
                            if (value.length < 6) {
                              return 'Minimum 6 characters';
                            }
                            return null;
                          },
                        )
                            .animate()
                            .fadeIn(duration: 220.ms)
                            .slideY(begin: .06, end: 0),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _submit,
                            icon: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.login_rounded),
                            label: const Text('Log in'),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 220.ms)
                            .slideY(begin: .05, end: 0),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed:
                                _loading ? null : () => context.go('/forgot'),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.subtext),
                            ),
                            TextButton(
                              onPressed:
                                  _loading ? null : () => context.go('/signup'),
                              child: const Text('Create one'),
                            ),
                          ],
                        ).animate().fadeIn(duration: 200.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
