import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../providers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  String _phone = '';
  String _otp = '';
  String _newPassword = '';
  int _step = 0;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark premium background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFFD700)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            // Animated Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.lock_reset_rounded, size: 60, color: Color(0xFFFFD700)),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fade(),
            
            const SizedBox(height: 16),
            
            const Text(
              'استعادة كلمة المرور', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 32),
            
            // Main Container for the form steps
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey<int>(_step),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _step == 0 
                    ? _buildPhoneStep() 
                    : _step == 1 
                        ? _buildOtpStep() 
                        : _buildPasswordStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      key: const ValueKey('phone_step'),
      children: [
        const Text(
          'أدخل رقم هاتفك لتلقي رمز التحقق', 
          style: TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildTextField(
          label: 'رقم الهاتف (+213)',
          icon: Icons.phone_iphone_rounded,
          keyboardType: TextInputType.phone,
          onChanged: (val) => _phone = val,
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          text: 'إرسال الكود',
          onPressed: () async {
            var p = _phone.trim();
            if (p.isEmpty) return;
            if (p.startsWith('0')) p = p.substring(1);
            if (!p.startsWith('+213')) p = '+213$p';
            _phone = p;
            
            await ref.read(authProvider.notifier).signInWithOtp(phone: _phone);
            setState(() => _step = 1);
          },
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey('otp_step'),
      children: [
        const Text(
          'أدخل الكود المكون من 6 أرقام المرسل إليك', 
          style: TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 24, 
            letterSpacing: 8, 
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: 'الكود (OTP)',
            labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16, letterSpacing: 0),
            prefixIcon: const Icon(Icons.dialpad_rounded, color: Color(0xFFFFD700)),
            filled: true,
            fillColor: const Color(0xFF121212),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
            ),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: (val) => _otp = val,
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          text: 'تأكيد الرمز',
          onPressed: () async {
            if (_otp.length != 6) return;
            await ref.read(authProvider.notifier).verifyOtp(phone: _phone, token: _otp);
            setState(() => _step = 2);
          },
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      key: const ValueKey('password_step'),
      children: [
        const Text(
          'تعيين كلمة مرور جديدة لحسابك', 
          style: TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          style: const TextStyle(color: Colors.white),
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'كلمة المرور الجديدة',
            labelStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFFD700)),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey.shade500),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: const Color(0xFF121212),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
            ),
          ),
          onChanged: (val) => _newPassword = val,
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          text: 'حفظ وتسجيل الدخول',
          onPressed: () async {
            if (_newPassword.length < 6) return;
            await Supabase.instance.client.auth.updateUser(UserAttributes(password: _newPassword));
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تغيير كلمة المرور بنجاح!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                backgroundColor: Color(0xFFFFD700),
              )
            );
            widget.onBack();
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    required void Function(String) onChanged,
  }) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(icon, color: const Color(0xFFFFD700)),
        filled: true,
        fillColor: const Color(0xFF121212),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildPrimaryButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700), // Gold
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.5),
        ),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
