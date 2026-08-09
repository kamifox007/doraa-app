import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/translation_service.dart';

class EmailPasswordScreen extends ConsumerStatefulWidget {
  const EmailPasswordScreen({
    super.key,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onConfirmPasswordChanged,
    required this.onNext,
    required this.onBack,
  });

  final String email;
  final String password;
  final String confirmPassword;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onConfirmPasswordChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<EmailPasswordScreen> createState() => _EmailPasswordScreenState();
}

class _EmailPasswordScreenState extends ConsumerState<EmailPasswordScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    double strength = 0.0;
    if (password.length >= 8) strength += 0.35;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.35;
    if (RegExp(r'\d').hasMatch(password)) strength += 0.30;
    return strength;
  }

  Color _getStrengthColor(double strength) {
    if (strength <= 0.35) return Colors.red;
    if (strength <= 0.70) return Colors.orange;
    return Colors.green;
  }

  String _getStrengthText(double strength, String Function(String) tr) {
    if (strength <= 0.35) return tr('weak') != 'weak' ? tr('weak') : 'ضعيفة';
    if (strength <= 0.70) return tr('medium') != 'medium' ? tr('medium') : 'متوسطة';
    return tr('strong') != 'strong' ? tr('strong') : 'قوية';
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider).tr;
    final strength = _calculatePasswordStrength(widget.password);
    final passwordsMatch = widget.password.isNotEmpty && widget.password == widget.confirmPassword;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
          ],
        ),
        const Icon(Icons.lock_person_rounded, size: 80, color: Color(0xFFE91E63)),
        const SizedBox(height: 32),
        Text(tr('setup_password_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(tr('setup_password_desc'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        TextFormField(
          initialValue: widget.email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: tr('email_optional'),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          onChanged: widget.onEmailChanged,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: widget.password,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: tr('password_label'),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          onChanged: widget.onPasswordChanged,
        ),
        if (widget.password.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: strength,
                  backgroundColor: Colors.grey.shade200,
                  color: _getStrengthColor(strength),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getStrengthText(strength, tr),
                style: TextStyle(color: _getStrengthColor(strength), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          initialValue: widget.confirmPassword,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: tr('confirm_password_label'),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          onChanged: widget.onConfirmPasswordChanged,
        ),
        if (widget.confirmPassword.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                passwordsMatch ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: passwordsMatch ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                passwordsMatch ? (tr('passwords_match') != 'passwords_match' ? tr('passwords_match') : 'كلمتا المرور متطابقتان') : (tr('passwords_mismatch') != 'passwords_mismatch' ? tr('passwords_mismatch') : 'كلمتا المرور غير متطابقتين'),
                style: TextStyle(color: passwordsMatch ? Colors.green : Colors.red, fontSize: 12),
              ),
            ],
          ),
        ],
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            if (widget.password.isNotEmpty && widget.password != widget.confirmPassword) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr('passwords_mismatch') != 'passwords_mismatch' ? tr('passwords_mismatch') : 'تنبيه: كلمتا المرور غير متطابقتين'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            widget.onNext();
          },
          child: Text(tr('continue_registration')),
        ),
      ],
    );
  }
}
