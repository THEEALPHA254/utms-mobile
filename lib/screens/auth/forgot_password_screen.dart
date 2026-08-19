import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl    = TextEditingController();
  final _otpCtrl      = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  int  _step      = 1; // 1 = enter email, 2 = enter OTP + new password
  bool _loading   = false;
  bool _obscure   = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await apiService.forgotPassword(_emailCtrl.text.trim());
      setState(() { _step = 2; });
    } catch (e) {
      setState(() { _error = 'Failed to send code. Check your email and try again.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await apiService.resetPassword(
        email:       _emailCtrl.text.trim(),
        otp:         _otpCtrl.text.trim(),
        newPassword: _passwordCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully. Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/login');
      }
    } on Exception catch (e) {
      final msg = e.toString();
      setState(() {
        _error = msg.contains('Invalid') || msg.contains('expired')
            ? 'Invalid or expired code. Please try again.'
            : 'Failed to reset password. Please try again.';
      });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.maroon,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _step == 1 ? Icons.lock_reset_rounded : Icons.verified_outlined,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _step == 1 ? 'Forgot Password' : 'Enter Reset Code',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _step == 1
                        ? "We'll email you a 6-digit reset code"
                        : 'Check your email for the code',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Form card
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDAD6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFF690005)),
                        ),
                      ),

                    // Step 1: Email
                    if (_step == 1) ...[
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                        cursorColor: AppTheme.maroon,
                        decoration: _inputDeco(
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                        ),
                        validator: (v) =>
                            v != null && v.contains('@') ? null : 'Enter a valid email',
                      ),
                    ],

                    // Step 2: OTP + new password
                    if (_step == 2) ...[
                      TextFormField(
                        controller: _otpCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                        cursorColor: AppTheme.maroon,
                        decoration: _inputDeco(
                          label: '6-Digit Reset Code',
                          icon: Icons.pin_outlined,
                        ),
                        validator: (v) =>
                            v != null && v.length == 6 ? null : 'Enter the 6-digit code',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                        cursorColor: AppTheme.maroon,
                        decoration: _inputDeco(
                          label: 'New Password',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                            v != null && v.length >= 8 ? null : 'At least 8 characters',
                      ),
                    ],

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _loading ? null : (_step == 1 ? _requestOtp : _resetPassword),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(_step == 1 ? 'Send Reset Code' : 'Reset Password'),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_step == 2)
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => setState(() { _step = 1; _error = null; }),
                            child: const Text(
                              'Back',
                              style: TextStyle(color: AppTheme.maroon),
                            ),
                          ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text(
                            'Back to Sign In',
                            style: TextStyle(color: AppTheme.maroon),
                          ),
                        ),
                      ],
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
      counterText: '',
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
