import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/translation_service.dart';
import '../../../legal/screens/terms_acceptance_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onNext, required this.onLogin});
  final VoidCallback onNext;
  final VoidCallback onLogin;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider).tr;
    final List<Map<String, dynamic>> pages = [
      {
        'image': 'assets/images/onboarding_security.png',
        'title': tr('onboarding_title_1'),
        'desc': tr('onboarding_desc_1'),
      },
      {
        'image': 'assets/images/onboarding_ride.png',
        'title': tr('onboarding_title_2'),
        'desc': tr('onboarding_desc_2'),
      },
      {
        'image': 'assets/images/onboarding_cash.png',
        'title': tr('onboarding_title_3'),
        'desc': tr('onboarding_desc_3'),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark premium background
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.topLeft,
              child: _currentPage < pages.length - 1
                  ? TextButton(
                      onPressed: widget.onNext,
                      child: Text(
                        tr('skip'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700), // Gold color
                        ),
                      ),
                    ).animate().fade()
                  : null,
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image with Animation
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.2), // Gold glow
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(200),
                            child: Image.asset(
                              page['image'],
                              width: 280,
                              height: 280,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                        .animate(key: ValueKey(index)) // Animate every time page changes
                        .scale(duration: 600.ms, curve: Curves.easeOutBack)
                        .fade(duration: 500.ms),
                        
                        const SizedBox(height: 48),
                        
                        // Title with Animation
                        Text(
                          page['title'],
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFD700), // Gold
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate(key: ValueKey('title_$index'))
                        .slideY(begin: 0.5, end: 0, duration: 500.ms)
                        .fade(duration: 500.ms),
                        
                        const SizedBox(height: 16),
                        
                        // Description with Animation
                        Text(
                          page['desc'],
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade400,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate(key: ValueKey('desc_$index'))
                        .slideY(begin: 0.5, end: 0, duration: 600.ms)
                        .fade(duration: 600.ms),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Page Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 10,
                  width: _currentPage == index ? 30 : 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? const Color(0xFFFFD700) : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  if (_currentPage < pages.length - 1)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(tr('next_btn'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ).animate().fade()
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: widget.onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(tr('signup_btn'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ).animate().slideY(begin: 0.5, end: 0).fade(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: widget.onLogin,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFD700), width: 2),
                          foregroundColor: const Color(0xFFFFD700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          tr('login_btn'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ).animate().slideY(begin: 0.5, end: 0).fade(delay: 100.ms),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TermsAcceptanceScreen()));
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade500,
                        ),
                        child: const Text('تخطي - تجربة الواجهات', style: TextStyle(fontSize: 16, decoration: TextDecoration.underline)),
                      ),
                    ).animate().fade(delay: 200.ms),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
