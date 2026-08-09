import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
          Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
            ],
          ),
          const Icon(Icons.phone_android_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 32),
          Text(tr('confirm_phone_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(tr('confirm_phone_desc'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          TextFormField(
            initialValue: phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: tr('phone_label'),
              hintText: '+213 551 23 45 67',
              prefixIcon: const Icon(Icons.phone),
            ),
            onChanged: onPhoneChanged,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onSubmit, child: Text(tr('send_code_btn'))),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          TextFormField(
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: tr('otp_label'),
              counterText: '',
            ),
            onChanged: onOtpChanged,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onVerify,
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary),
            child: Text(tr('verify_code_btn')),
          ),
        ],
    );
  }
}
