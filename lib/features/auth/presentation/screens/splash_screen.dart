import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/translation_service.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider).tr;
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark premium background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Premium Gold Logo Image
              Image.asset(
                'assets/images/dzdora_premium_logo.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              )
              .animate()
              .fade(duration: 800.ms)
              .scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 24),
              
              // Animated DZdora Text
              Text(
                'DZdora',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFFD700), // Gold color
                      letterSpacing: 4,
                    ),
              )
              .animate()
              .fade(delay: 600.ms, duration: 500.ms)
              .slideY(begin: 0.5, end: 0)
              .shimmer(delay: 1200.ms, duration: 1500.ms, color: Colors.white70), // Shimmer effect
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                tr('splash_subtitle'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey.shade400,
                    ),
              ).animate().fade(delay: 1000.ms),
              
              const SizedBox(height: 64),
              
              // Let's go Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700), // Gold button
                    foregroundColor: Colors.black, // Black text on gold
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onNext,
                  child: Text(tr('lets_go'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ).animate().fade(delay: 1400.ms).slideY(begin: 0.5, end: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
