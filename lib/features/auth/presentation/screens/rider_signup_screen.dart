import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/auth_providers.dart';
import '../../../../widgets/glass_container.dart';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 48),
            const Icon(Icons.person_add_alt_1_rounded, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            const Text('حساب جديد (راكبة)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'الاسم', prefixIcon: Icon(Icons.person), filled: true, fillColor: Colors.white),
                    onSaved: (val) => _firstName = val!,
                    validator: (val) => val!.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'اللقب', prefixIcon: Icon(Icons.person_outline), filled: true, fillColor: Colors.white),
                    onSaved: (val) => _lastName = val!,
                    validator: (val) => val!.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'رقم الهاتف (+213)', prefixIcon: Icon(Icons.phone), filled: true, fillColor: Colors.white),
                    keyboardType: TextInputType.phone,
                    onSaved: (val) => _phone = val!,
                    validator: (val) => val!.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock), filled: true, fillColor: Colors.white),
                    obscureText: true,
                    onSaved: (val) => _password = val!,
                    validator: (val) => val!.length < 6 ? 'كلمة المرور قصيرة' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
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
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                      ),
                      child: const Text('تسجيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  TextButton(onPressed: widget.onBack, child: const Text('رجوع', style: TextStyle(color: Colors.white))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
