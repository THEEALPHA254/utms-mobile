import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ctrls = {
    'first_name': TextEditingController(),
    'last_name': TextEditingController(),
    'email': TextEditingController(),
    'phone_number': TextEditingController(),
    'admission_number': TextEditingController(),
    'student_id': TextEditingController(),
    'faculty': TextEditingController(),
    'password': TextEditingController(),
  };
  final bool _obscure = true;
  int _step = 0;

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).register({
      for (final e in _ctrls.entries) e.key: e.value.text.trim(),
    });
  }

  Widget _field(String key, String label, {TextInputType? type, bool obscure = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _ctrls[key],
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label),
        validator: validator ?? (v) => v!.trim().isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/login')),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Stepper header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: List.generate(2, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i <= _step ? theme.colorScheme.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _step == 0 ? 'Personal Info' : 'University Details',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    if (auth.error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(auth.error!, style: TextStyle(color: theme.colorScheme.error)),
                      ),

                    if (_step == 0) ...[
                      _field('first_name', 'First Name'),
                      _field('last_name', 'Last Name'),
                      _field('email', 'Email Address', type: TextInputType.emailAddress,
                          validator: (v) => v!.contains('@') ? null : 'Invalid email'),
                      _field('phone_number', 'Phone Number (e.g. 07XXXXXXXX)', type: TextInputType.phone),
                      _field('password', 'Password', obscure: _obscure,
                          validator: (v) => v!.length >= 8 ? null : 'Minimum 8 characters'),
                    ] else ...[
                      _field('admission_number', 'Admission Number'),
                      _field('student_id', 'Student ID'),
                      _field('faculty', 'Faculty / Department'),
                    ],

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: _step == 0
                  ? ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) setState(() => _step = 1);
                      },
                      child: const Text('Next'),
                    )
                  : ElevatedButton(
                      onPressed: auth.isLoading ? null : _register,
                      child: auth.isLoading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Create Account'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
