import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../providers/auth_providers.dart';
import '../../../../widgets/glass_container.dart';

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 48),
          const Icon(Icons.lock_reset, size: 80, color: Colors.white),
          const SizedBox(height: 16),
          const Text('استعادة كلمة المرور', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 32),
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: _step == 0 ? _buildPhoneStep() : _step == 1 ? _buildOtpStep() : _buildPasswordStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(labelText: 'رقم الهاتف (+213)', prefixIcon: Icon(Icons.phone), filled: true, fillColor: Colors.white),
          keyboardType: TextInputType.phone,
          onChanged: (val) => _phone = val,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: () async {
              var p = _phone.trim();
              if (p.startsWith('0')) p = p.substring(1);
              if (!p.startsWith('+213')) p = '+213$p';
              _phone = p;
              
              await ref.read(authProvider.notifier).signInWithOtp(phone: _phone);
              setState(() => _step = 1);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
            child: const Text('إرسال الكود', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        TextButton(onPressed: widget.onBack, child: const Text('رجوع', style: TextStyle(color: Colors.white))),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        const Text('أدخل الكود المرسل إليك', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(labelText: 'الكود (OTP)', prefixIcon: Icon(Icons.message), filled: true, fillColor: Colors.white),
          keyboardType: TextInputType.number,
          onChanged: (val) => _otp = val,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).verifyOtp(phone: _phone, token: _otp);
              setState(() => _step = 2);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
            child: const Text('تأكيد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        const Text('تعيين كلمة مرور جديدة', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة', prefixIcon: Icon(Icons.lock), filled: true, fillColor: Colors.white),
          obscureText: true,
          onChanged: (val) => _newPassword = val,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.auth.updateUser(UserAttributes(password: _newPassword));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')));
              widget.onBack();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
            child: const Text('حفظ وتسجيل الدخول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
