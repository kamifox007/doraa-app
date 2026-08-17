import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/translation_service.dart';
import '../../../../services/app_config.dart';
import '../../../legal/screens/terms_acceptance_screen.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider).tr;
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark premium background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Animated Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, size: 100, color: Color(0xFFFFD700)),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fade(),
              
              const SizedBox(height: 48),
              
              Text(
                tr('request_received_title'), 
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.5,
                ), 
                textAlign: TextAlign.center,
              ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 16),
              
              Text(
                tr('request_received_desc'),
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.6, color: Colors.grey.shade400, fontSize: 16),
              ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 48),
              
              // Loading Indicator
              const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD700), strokeWidth: 3),
              ).animate().fade(delay: 500.ms),
              
              if (!AppConfig.isSupabaseConfigured) ...[
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TermsAcceptanceScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700), // Gold
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.5),
                  ),
                  child: const Text('دخول لتجربة التطبيق (وضع تجريبي)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ).animate().fade(delay: 700.ms).slideY(begin: 0.2, end: 0),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
