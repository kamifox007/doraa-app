import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/translation_service.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key, required this.onNext, required this.onBack});
  final VoidCallback onNext;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            
            // Animated Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.verified_user_rounded, size: 60, color: Color(0xFFFFD700)),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fade(),
            
            const SizedBox(height: 32),
            
            Text(
              tr('verify_identity_title'), 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ), 
              textAlign: TextAlign.center,
            ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 8),
            
            Text(
              'نرجو رفع المستندات المطلوبة بوضوح لضمان التحقق', 
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
              textAlign: TextAlign.center,
            ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 32),
            
            Container(
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
                  _buildDocumentItem(
                    icon: Icons.badge_rounded,
                    title: tr('id_card_img'),
                    subtitle: tr('upload_clear_img'),
                  ).animate().fade(delay: 300.ms).slideX(begin: 0.1, end: 0),
                  
                  Divider(color: Colors.grey.shade800, height: 1, indent: 64),
                  
                  _buildDocumentItem(
                    icon: Icons.drive_eta_rounded,
                    title: tr('driving_license'),
                    subtitle: tr('drivers_only'),
                  ).animate().fade(delay: 400.ms).slideX(begin: 0.1, end: 0),
                  
                  Divider(color: Colors.grey.shade800, height: 1, indent: 64),
                  
                  _buildDocumentItem(
                    icon: Icons.face_retouching_natural_rounded,
                    title: tr('live_selfie'),
                    subtitle: tr('verify_face_match'),
                  ).animate().fade(delay: 500.ms).slideX(begin: 0.1, end: 0),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700), // Gold
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.5),
              ),
              child: Text(tr('skip_demo_btn'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ).animate().fade(delay: 600.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: const Color(0xFFFFD700)),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFFFD700), size: 20),
      ),
    );
  }
}
