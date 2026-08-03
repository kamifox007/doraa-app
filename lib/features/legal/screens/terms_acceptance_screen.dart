import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/ride_flow.dart';
import '../../../widgets/auth_flow.dart';
import '../../../services/translation_service.dart';

class TermsAcceptanceScreen extends ConsumerStatefulWidget {
  const TermsAcceptanceScreen({super.key});

  @override
  ConsumerState<TermsAcceptanceScreen> createState() => _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends ConsumerState<TermsAcceptanceScreen> {
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _acceptedSafety = false;

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider).tr;
    
    return Scaffold(
      appBar: AppBar(title: Text(tr('terms_title'))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      tr('terms_section_1_title'),
                      tr('terms_section_1_desc'),
                    ),
                    _buildSection(
                      tr('terms_section_2_title'),
                      tr('terms_section_2_desc'),
                    ),
                    _buildSection(
                      tr('terms_section_3_title'),
                      tr('terms_section_3_desc'),
                    ),
                    _buildSection(
                      tr('terms_section_4_title'),
                      tr('terms_section_4_desc'),
                    ),
                    _buildSection(
                      tr('terms_section_5_title'),
                      tr('terms_section_5_desc'),
                    ),
                  ],
                ),
              ),
            ),
            _buildCheckbox(
              tr('terms_agree_1'),
              _acceptedTerms,
              (v) => setState(() => _acceptedTerms = v!),
            ),
            _buildCheckbox(
              tr('terms_agree_2'),
              _acceptedPrivacy,
              (v) => setState(() => _acceptedPrivacy = v!),
            ),
            _buildCheckbox(
              tr('terms_agree_3'),
              _acceptedSafety,
              (v) => setState(() => _acceptedSafety = v!),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canProceed() ? _acceptTerms : null,
                child: Text(tr('terms_accept_btn')),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthFlowScreen()));
              },
              child: Text(tr('terms_reject_btn'), style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 13)),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }

  bool _canProceed() => _acceptedTerms && _acceptedPrivacy && _acceptedSafety;

  Future<void> _acceptTerms() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({
              'terms_accepted': true,
              'terms_accepted_at': DateTime.now().toIso8601String(),
              'terms_version': '1.0',
            })
            .eq('id', user.id);
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RideFlowScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }
}
