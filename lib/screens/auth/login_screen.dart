// -----------------------------------------------------------------------------
// LOGIN SCREEN
//
// KEY CONCEPTS:
//   • `ConsumerStatefulWidget` = a StatefulWidget that also gives us `ref`
//     for Riverpod access. Needed here because we hold text controllers +
//     an "obscure password" toggle — state that survives widget rebuilds.
//   • `TextEditingController` owns the text inside a TextFormField. We
//     `dispose()` them to prevent memory leaks (they hold listeners).
//   • `GlobalKey<FormState>` lets us call `.validate()` on the Form to run
//     every field's validator at once.
//   • `ref.read(authProvider.notifier).login(...)` — use `.read` (not
//     `.watch`) when you just want to CALL a method; watch is for reading
//     state that should rebuild the widget when it changes.
//   • The router redirects automatically when `auth.isAuthenticated` flips,
//     so this screen never has to call `context.go('/home')` on success.
// ----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Controllers wire the TextFields to Dart strings we can read from.
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  // Toggle for the show/hide password eye icon.
  bool _obscure    = true;
  // Handle to the Form so we can trigger validate() from the login button.
  final _formKey   = GlobalKey<FormState>();

  // Lifecycle hook: called when this widget leaves the tree. Freeing the
  // controllers here avoids leaking the underlying listeners.
  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // Called by the Sign In button. Validate first, then delegate to the
  // AuthNotifier — any error will land in `auth.error` and be rendered above.
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
  }

  // `build` runs on every state change (setState) AND whenever a watched
  // provider updates. That's how the loading spinner and error banner appear
  // without us doing anything manually — we just watch `authProvider`.
  @override
  Widget build(BuildContext context) {
    final auth  = ref.watch(authProvider);
    // final theme = Theme.of(context);

    return Scaffold(
      // Always maroon top half — the form card is always white
      backgroundColor: AppTheme.maroon,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Branding header (on maroon background) ──────────────────────
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus_rounded,
                      color: Colors.white, size: 64),
                  SizedBox(height: 12),
                  Text('USTMS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Student Transport App',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),

            // ── Form card (always white regardless of app theme) ─────────────
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary, // always dark on white
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Only render the error banner when there's an error to show.
                    // Dart's `if` inside a widget list is a "collection if".
                    if (auth.error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDAD6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          auth.error!,
                          style: const TextStyle(color: Color(0xFF690005)),
                        ),
                      ),

                    // Email field — force light theme decoration
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 15),
                      cursorColor: AppTheme.maroon,
                      decoration: _inputDeco(
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                      ),
                      validator: (v) =>
                          v!.contains('@') ? null : 'Enter a valid email',
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 15),
                      cursorColor: AppTheme.maroon,
                      decoration: _inputDeco(
                        label: 'Password',
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          v!.length >= 6 ? null : 'Password too short',
                    ),
                    const SizedBox(height: 24),

                    // Sign In button — disabled (onPressed: null) while a login
                    // request is in flight, and swaps its label for a spinner.
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _login,
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Sign In'),
                    ),

                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/forgot-password'),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(color: AppTheme.maroon),
                        ),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text(
                          "Don't have an account? Register",
                          style: TextStyle(color: AppTheme.maroon),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Force a light-mode input decoration so the form card is always readable
  /// regardless of the app's current dark/light theme mode.
  InputDecoration _inputDeco({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary),
      hintStyle: const TextStyle(color: AppTheme.textHint),
      prefixIcon: Icon(icon, color: AppTheme.textSecondary),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F2F2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD0C8C8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD0C8C8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.maroon, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
