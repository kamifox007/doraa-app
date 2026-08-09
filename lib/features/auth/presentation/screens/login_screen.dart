import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/translation_service.dart';
import '../../../legal/screens/terms_acceptance_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({
    super.key,
    required this.email,
    required this.password,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onBack,
  });

  final String email;
  final String password;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider).tr;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
            ],
          ),
          const SizedBox(height: 16),
          Text(tr('login_title'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(tr('login_desc')),
          const SizedBox(height: 48),
          TextFormField(
            initialValue: email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: tr('email_label'),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            onChanged: onEmailChanged,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: tr('password_label'),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            onChanged: onPasswordChanged,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: onForgotPassword, child: Text(tr('forgot_password'))),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onLogin,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(tr('enter_btn'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TermsAcceptanceScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('تخطي - تجربة الواجهات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
      ),
    );
  }
}
