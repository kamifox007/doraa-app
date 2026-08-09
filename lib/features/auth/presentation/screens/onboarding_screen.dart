import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/translation_service.dart';
import '../../../../widgets/glass_container.dart';
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
        'icon': Icons.security_rounded,
        'title': tr('onboarding_title_1'),
        'desc': tr('onboarding_desc_1'),
      },
      {
        'icon': Icons.car_rental_rounded,
        'title': tr('onboarding_title_2'),
        'desc': tr('onboarding_desc_2'),
      },
      {
        'icon': Icons.wallet_rounded,
        'title': tr('onboarding_title_3'),
        'desc': tr('onboarding_desc_3'),
      },
    ];

    return Column(
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
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
                    GlassContainer(
                      padding: const EdgeInsets.all(40),
                      borderRadius: 100,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                        ),
                        child: Icon(page['icon'], size: 70, color: const Color(0xFFE91E63)),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      page['title'],
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      page['desc'],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
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
                color: _currentPage == index ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
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
                    child: Text(tr('next_btn'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: widget.onNext,
                    child: Text(tr('signup_btn'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: widget.onLogin,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      tr('login_btn'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TermsAcceptanceScreen()));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('تخطي - تجربة الواجهات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
