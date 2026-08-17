import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/translation_service.dart';

class PhoneOtpScreen extends ConsumerWidget {
  const PhoneOtpScreen({
    super.key,
    required this.phone,
    required this.onPhoneChanged,
    required this.onOtpChanged,
    required this.onSubmit,
    required this.onVerify,
    required this.onBack,
  });

  final String phone;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onOtpChanged;
  final VoidCallback onSubmit;
  final VoidCallback onVerify;
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
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
            const SizedBox(height: 16),
            
            // Animated Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.mark_email_read_rounded, size: 64, color: Color(0xFFFFD700)),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fade(),
            
            const SizedBox(height: 32),
            
            Text(
              tr('confirm_phone_title'), 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ), 
              textAlign: TextAlign.center,
            ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 12),
            
            Text(
              tr('confirm_phone_desc'), 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16, height: 1.5),
            ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 48),
            
            // Phone Field
            TextFormField(
              initialValue: phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
              decoration: InputDecoration(
                labelText: tr('phone_label'),
                labelStyle: TextStyle(color: Colors.grey.shade500, letterSpacing: 0),
                hintText: '+213 551 23 45 67',
                hintStyle: TextStyle(color: Colors.grey.shade700),
                prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Color(0xFFFFD700)),
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
              onChanged: onPhoneChanged,
            ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 24),
            
            // Send Code Button
            ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: const Color(0xFFFFD700),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: const Color(0xFFFFD700).withValues(alpha: 0.5), width: 1),
                ),
              ),
              child: Text(tr('send_code_btn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 40),
            
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade800)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.dialpad_rounded, color: Colors.grey.shade600, size: 20),
                ),
                Expanded(child: Divider(color: Colors.grey.shade800)),
              ],
            ).animate().fade(delay: 500.ms),
            
            const SizedBox(height: 40),
            
            // OTP Field
            TextFormField(
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32, 
                letterSpacing: 16, 
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
              ),
              decoration: InputDecoration(
                labelText: tr('otp_label'),
                labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16, letterSpacing: 0),
                counterText: '',
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                ),
              ),
              onChanged: onOtpChanged,
            ).animate().fade(delay: 600.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 24),
            
            // Verify Button
            ElevatedButton(
              onPressed: onVerify,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700), // Gold
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.5),
              ),
              child: Text(tr('verify_code_btn'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ).animate().fade(delay: 700.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 24),
          ],
      ),
    );
  }
}
