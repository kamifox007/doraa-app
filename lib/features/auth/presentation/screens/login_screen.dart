import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark premium background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: onBack, 
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFFD700)),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo or Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(Icons.lock_person_rounded, size: 60, color: Color(0xFFFFD700)),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fade(),
              
              const SizedBox(height: 32),
              
              Text(
                tr('login_title'), 
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ).animate().slideY(begin: 0.2, end: 0).fade(delay: 100.ms),
              
              const SizedBox(height: 8),
              
              Text(
                tr('login_desc'),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                textAlign: TextAlign.center,
              ).animate().slideY(begin: 0.2, end: 0).fade(delay: 200.ms),
              
              const SizedBox(height: 48),
              
              // Email Field
              TextFormField(
                initialValue: email,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: tr('email_label'),
                  labelStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFFD700)),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                  ),
                ),
                onChanged: onEmailChanged,
              ).animate().slideY(begin: 0.2, end: 0).fade(delay: 300.ms),
              
              const SizedBox(height: 16),
              
              // Password Field
              TextFormField(
                initialValue: password,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: tr('password_label'),
                  labelStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFFD700)),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                  ),
                ),
                onChanged: onPasswordChanged,
              ).animate().slideY(begin: 0.2, end: 0).fade(delay: 400.ms),
              
              const SizedBox(height: 8),
              
              Align(
                alignment: Alignment.centerLeft, // Or right depending on RTL
                child: TextButton(
                  onPressed: onForgotPassword, 
                  child: Text(
                    tr('forgot_password'),
                    style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                  ),
                ),
              ).animate().fade(delay: 500.ms),
              
              const SizedBox(height: 32),
              
              // Login Button
              ElevatedButton(
                onPressed: onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700), // Gold
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.5),
                ),
                child: Text(tr('enter_btn'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ).animate().slideY(begin: 0.2, end: 0).fade(delay: 600.ms),
              
              const SizedBox(height: 16),
              
              // Skip Button
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TermsAcceptanceScreen()));
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.grey.shade400,
                ),
                child: const Text('تخطي - تجربة الواجهات', style: TextStyle(fontSize: 16, decoration: TextDecoration.underline)),
              ).animate().fade(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}
