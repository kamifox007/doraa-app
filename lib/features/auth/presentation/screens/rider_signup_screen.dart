import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../providers/auth_providers.dart';

class RiderSignupScreen extends ConsumerStatefulWidget {
  const RiderSignupScreen({super.key, required this.onNext, required this.onBack});
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<RiderSignupScreen> createState() => _RiderSignupScreenState();
}

class _RiderSignupScreenState extends ConsumerState<RiderSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _phone = '';
  String _password = '';
  String _firstName = '';
  String _lastName = '';

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
        child: Form(
          key: _formKey,
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
                child: const Icon(Icons.person_add_alt_1_rounded, size: 60, color: Color(0xFFFFD700)),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fade(),
              
              const SizedBox(height: 16),
              
              const Text('حساب جديد (راكبة)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))
                  .animate().slideY(begin: 0.2, end: 0).fade(delay: 100.ms),
              
              const SizedBox(height: 32),
              
              Container(
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
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'الاسم',
                      icon: Icons.person,
                      onSaved: (val) => _firstName = val!,
                      validator: (val) => val!.isEmpty ? 'مطلوب' : null,
                    ).animate().slideY(begin: 0.2, end: 0).fade(delay: 200.ms),
                    
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      label: 'اللقب',
                      icon: Icons.person_outline,
                      onSaved: (val) => _lastName = val!,
                      validator: (val) => val!.isEmpty ? 'مطلوب' : null,
                    ).animate().slideY(begin: 0.2, end: 0).fade(delay: 300.ms),
                    
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      label: 'رقم الهاتف (+213)',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      onSaved: (val) => _phone = val!,
                      validator: (val) => val!.isEmpty ? 'مطلوب' : null,
                    ).animate().slideY(begin: 0.2, end: 0).fade(delay: 400.ms),
                    
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      label: 'كلمة المرور',
                      icon: Icons.lock,
                      obscureText: true,
                      onSaved: (val) => _password = val!,
                      validator: (val) => val!.length < 6 ? 'كلمة المرور قصيرة' : null,
                    ).animate().slideY(begin: 0.2, end: 0).fade(delay: 500.ms),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 5,
                          shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        ),
                        child: const Text('تسجيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ).animate().slideY(begin: 0.2, end: 0).fade(delay: 600.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    required void Function(String?) onSaved,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(icon, color: const Color(0xFFFFD700)),
        filled: true,
        fillColor: const Color(0xFF121212), // Darker field background inside the container
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
        ),
      ),
      onSaved: onSaved,
      validator: validator,
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      var p = _phone.trim();
      if (p.startsWith('0')) p = p.substring(1);
      if (!p.startsWith('+213')) p = '+213$p';

      final reg = ref.read(registrationProvider.notifier);
      reg.updatePhone(p);
      reg.updatePassword(_password);
      reg.updateFullName('$_firstName $_lastName');
      reg.updateRole('rider');

      await ref.read(authProvider.notifier).signUpWithPhonePassword(phone: p, password: _password);
      widget.onNext();
    }
  }
}
