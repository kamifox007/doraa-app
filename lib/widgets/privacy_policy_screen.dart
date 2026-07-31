import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider).tr;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5FF),
      appBar: AppBar(
        title: Text(tr('privacy_policy_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE91E63),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('privacy_policy_and_terms'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
              ),
              const SizedBox(height: 16),
              Text(
                tr('privacy_policy_intro'),
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 20),
              
              _SectionTitle(tr('privacy_section_1_title')),
              Text(
                tr('privacy_section_1_body'),
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 20),

              _SectionTitle(tr('privacy_section_2_title')),
              Text(
                tr('privacy_section_2_body'),
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 20),

              _SectionTitle(tr('privacy_section_3_title')),
              Text(
                tr('privacy_section_3_body'),
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 20),
              
              _SectionTitle(tr('privacy_section_4_title')),
              Text(
                tr('privacy_section_4_body'),
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 20),
              
              Text(
                tr('privacy_policy_agreement'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }
}
