import 'package:flutter/material.dart';
import 'package:doraa/services/translation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider).tr;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(tr('privacy_policy_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF121212),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('privacy_policy_and_terms'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
              ),
              const SizedBox(height: 16),
              Text(
                tr('privacy_policy_intro'),
                style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.white),
              ),
              const SizedBox(height: 20),
              
              _SectionTitle(tr('privacy_section_1_title')),
              Text(
                tr('privacy_section_1_body'),
                style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.white),
              ),
              const SizedBox(height: 20),

              _SectionTitle(tr('privacy_section_2_title')),
              Text(
                tr('privacy_section_2_body'),
                style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.white),
              ),
              const SizedBox(height: 20),

              _SectionTitle(tr('privacy_section_3_title')),
              Text(
                tr('privacy_section_3_body'),
                style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.white),
              ),
              const SizedBox(height: 20),
              
              _SectionTitle(tr('privacy_section_4_title')),
              Text(
                tr('privacy_section_4_body'),
                style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.white),
              ),
              const SizedBox(height: 20),
              
              Text(
                tr('privacy_policy_agreement'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
      ),
    );
  }
}

