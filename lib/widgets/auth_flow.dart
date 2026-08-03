import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../providers/auth_providers.dart';
import '../services/app_config.dart';
import '../services/validation_service.dart';

import '../widgets/glass_container.dart';
import '../services/translation_service.dart';
import '../features/legal/screens/terms_acceptance_screen.dart';

class AuthFlowScreen extends ConsumerStatefulWidget {
  const AuthFlowScreen({super.key});

  @override
  ConsumerState<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends ConsumerState<AuthFlowScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(page, duration: const Duration(milliseconds: 600), curve: Curves.fastOutSlowIn);
  }

  @override
  Widget build(BuildContext context) {
    final registration = ref.watch(registrationProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFCE4EC), Color(0xFFF3E5F5), Colors.white],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (!AppConfig.isSupabaseConfigured)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'وضع تجريبي: يمكنك الاستمرار في تصفح الواجهات بدون Supabase.',
                          style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Prevent manual swiping
                  children: [
                    SplashScreen(onNext: () => _goToPage(1)),
                    OnboardingScreen(
                      onNext: () => _goToPage(3), // Skipped phone OTP step for easier testing
                      onLogin: () => _goToPage(8),
                    ),
                    PhoneOtpScreen(
                      phone: registration.phone,
                      onPhoneChanged: (value) => ref.read(registrationProvider.notifier).updatePhone(value),
                      onOtpChanged: (value) => ref.read(registrationProvider.notifier).updateOtp(value),
                      onSubmit: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final tr = ref.read(translationProvider).tr;
                        if (!AppConfig.isSupabaseConfigured) {
                          messenger.showSnackBar(SnackBar(content: Text(tr('demo_mode_skip'))));
                          return;
                        }
                        if (!ValidationService.isValidAlgerianPhone(registration.phone)) {
                          messenger.showSnackBar(SnackBar(content: Text(tr('invalid_phone'))));
                          return;
                        }
                        await ref.read(authProvider.notifier).signInWithOtp(phone: registration.phone);
                        if (!mounted) return;
                        messenger.showSnackBar(SnackBar(content: Text(ref.read(authProvider).message ?? tr('sent_success'))));
                      },
                      onVerify: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final tr = ref.read(translationProvider).tr;
                        if (!AppConfig.isSupabaseConfigured) {
                          _goToPage(3);
                          return;
                        }
                        if (!ValidationService.isValidAlgerianPhone(registration.phone)) {
                          messenger.showSnackBar(SnackBar(content: Text(tr('invalid_phone'))));
                          return;
                        }
                        if (registration.otp.length != 6) {
                          messenger.showSnackBar(SnackBar(content: Text(tr('invalid_otp_length'))));
                          return;
                        }
                        await ref.read(authProvider.notifier).verifyOtp(phone: registration.phone, token: registration.otp);
                        if (!mounted) return;
                        messenger.showSnackBar(SnackBar(content: Text(ref.read(authProvider).message ?? 'تم التحقق')));
                        if (ref.read(authProvider).status == AuthStatus.authenticated) {
                          _goToPage(3);
                        }
                      },
                      onBack: () => _goToPage(1),
                    ),
                    EmailPasswordScreen(
                      email: registration.email,
                      password: registration.password,
                      confirmPassword: registration.confirmPassword,
                      onEmailChanged: (value) => ref.read(registrationProvider.notifier).updateEmail(value),
                      onPasswordChanged: (value) => ref.read(registrationProvider.notifier).updatePassword(value),
                      onConfirmPasswordChanged: (value) => ref.read(registrationProvider.notifier).updateConfirmPassword(value),
                      onNext: () async {
                        if (!AppConfig.isSupabaseConfigured) {
                          _goToPage(4);
                          return;
                        }
                        if (!ValidationService.isValidEmail(registration.email)) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('البريد غير صالح')));
                          return;
                        }
                        if (!ValidationService.isValidPassword(registration.password)) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور يجب أن تكون 8 أحرف وتحتوي على رقم وحرف كبير')));
                          return;
                        }
                        if (registration.password != registration.confirmPassword) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمتا المرور غير متطابقتين')));
                          return;
                        }
                        await ref.read(authProvider.notifier).signUp(email: registration.email, password: registration.password);
                        if (!mounted) return;
                        if (ref.read(authProvider).status == AuthStatus.authenticated) {
                          _goToPage(4);
                        }
                      },
                      onBack: () => _goToPage(2),
                    ),
                    PersonalInfoScreen(
                      fullName: registration.fullName,
                      wilaya: registration.wilaya,
                      role: registration.role,
                      onNameChanged: (value) => ref.read(registrationProvider.notifier).updateFullName(value),
                      onWilayaChanged: (value) => ref.read(registrationProvider.notifier).updateWilaya(value),
                      onRoleChanged: (value) => ref.read(registrationProvider.notifier).updateRole(value),
                      onNext: () {
                        if (AppConfig.isSupabaseConfigured) {
                          if (!ValidationService.isValidName(registration.fullName)) {
                            final tr = ref.read(translationProvider).tr;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('invalid_name'))));
                            return;
                          }
                          if (!ValidationService.isValidWilaya(registration.wilaya)) {
                            final tr = ref.read(translationProvider).tr;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('select_wilaya'))));
                            return;
                          }
                        }
                        _goToPage(registration.role == 'driver' ? 5 : 7); // 5 for driver, 7 for Emergency Contacts
                      },
                      onBack: () => _goToPage(3),
                    ),
                    DriverVehicleScreen(
                      brand: registration.carBrand,
                      model: registration.carModel,
                      year: registration.carYear,
                      color: registration.carColor,
                      plate: registration.carPlate,
                      onBrandChanged: (value) => ref.read(registrationProvider.notifier).updateCarBrand(value),
                      onModelChanged: (value) => ref.read(registrationProvider.notifier).updateCarModel(value),
                      onYearChanged: (value) => ref.read(registrationProvider.notifier).updateCarYear(value),
                      onColorChanged: (value) => ref.read(registrationProvider.notifier).updateCarColor(value),
                      onPlateChanged: (value) => ref.read(registrationProvider.notifier).updateCarPlate(value),
                      onNext: () => _goToPage(6),
                      onBack: () => _goToPage(4),
                    ),
                    DocumentsScreen(
                      onNext: () => _goToPage(7),
                      onBack: () => _goToPage(5),
                    ),
                    EmergencyContactsScreen(
                      contacts: registration.emergencyContacts,
                      onContactsChanged: (value) => ref.read(registrationProvider.notifier).updateEmergencyContacts(value),
                      onNext: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        if (AppConfig.isSupabaseConfigured) {
                          if (!ValidationService.hasValidEmergencyContact(registration.emergencyContacts)) {
                            messenger.showSnackBar(const SnackBar(content: Text('أضف جهة طوارئ واحدة على الأقل')));
                            return;
                          }
                        }
                        
                        if (AppConfig.isSupabaseConfigured) {
                          await ref.read(authProvider.notifier).completeRegistration(registration);
                          if (!mounted) return;
                          final authState = ref.read(authProvider);
                          messenger.showSnackBar(SnackBar(content: Text(authState.message ?? 'تم حفظ الملف الشخصي')));
                          if (authState.status != AuthStatus.authenticated) {
                            return;
                          }
                        }

                        if (registration.role == 'driver') {
                          _goToPage(9); // Pending approval
                        } else {
                          navigator.pushReplacement(MaterialPageRoute(builder: (_) => const TermsAcceptanceScreen()));
                        }
                      },
                      onBack: () => _goToPage(registration.role == 'driver' ? 6 : 4),
                    ),
                    LoginScreen(
                      email: registration.email,
                      password: registration.password,
                      onEmailChanged: (value) => ref.read(registrationProvider.notifier).updateEmail(value),
                      onPasswordChanged: (value) => ref.read(registrationProvider.notifier).updatePassword(value),
                      onLogin: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        if (!AppConfig.isSupabaseConfigured) {
                          messenger.showSnackBar(const SnackBar(content: Text('وضع تجريبي - دخول مباشر')));
                          navigator.pushReplacement(MaterialPageRoute(builder: (_) => const TermsAcceptanceScreen()));
                          return;
                        }
                        await ref.read(authProvider.notifier).signInWithEmail(email: registration.email, password: registration.password);
                        if (!mounted) return;
                        final authState = ref.read(authProvider);
                        messenger.showSnackBar(SnackBar(content: Text(authState.message ?? 'تم تسجيل الدخول')));
                        if (authState.status == AuthStatus.authenticated) {
                          navigator.pushReplacement(MaterialPageRoute(builder: (_) => const TermsAcceptanceScreen()));
                        }
                      },
                      onForgotPassword: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سيتم إضافة استعادة كلمة المرور لاحقًا')));
                      },
                      onBack: () => _goToPage(1),
                    ),
                    const PendingApprovalScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider).tr;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              duration: const Duration(seconds: 1),
              tween: Tween<double>(begin: 0.5, end: 1.0),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                      blurRadius: 50,
                      spreadRadius: 15,
                    ),
                  ],
                ),
                child: const Icon(Icons.favorite_rounded, size: 90, color: Color(0xFFE91E63)),
              ),
            ),
            const SizedBox(height: 56),
            Text(
              'DORA',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFE91E63),
                    letterSpacing: 4,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              tr('splash_subtitle'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 64),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onNext,
                child: Text(tr('lets_go'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                      opacity: 0.7,
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
                if (!AppConfig.isSupabaseConfigured) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TermsAcceptanceScreen()));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text('تخطي - وضع تجريبي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

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

class EmailPasswordScreen extends ConsumerStatefulWidget {
  const EmailPasswordScreen({
    super.key,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onConfirmPasswordChanged,
    required this.onNext,
    required this.onBack,
  });

  final String email;
  final String password;
  final String confirmPassword;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onConfirmPasswordChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<EmailPasswordScreen> createState() => _EmailPasswordScreenState();
}

class _EmailPasswordScreenState extends ConsumerState<EmailPasswordScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    double strength = 0.0;
    if (password.length >= 8) strength += 0.35;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.35;
    if (RegExp(r'\d').hasMatch(password)) strength += 0.30;
    return strength;
  }

  Color _getStrengthColor(double strength) {
    if (strength <= 0.35) return Colors.red;
    if (strength <= 0.70) return Colors.orange;
    return Colors.green;
  }

  String _getStrengthText(double strength, String Function(String) tr) {
    if (strength <= 0.35) return tr('weak') != 'weak' ? tr('weak') : 'ضعيفة';
    if (strength <= 0.70) return tr('medium') != 'medium' ? tr('medium') : 'متوسطة';
    return tr('strong') != 'strong' ? tr('strong') : 'قوية';
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider).tr;
    final strength = _calculatePasswordStrength(widget.password);
    final passwordsMatch = widget.password.isNotEmpty && widget.password == widget.confirmPassword;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
          ],
        ),
        const Icon(Icons.lock_person_rounded, size: 80, color: Color(0xFFE91E63)),
        const SizedBox(height: 32),
        Text(tr('setup_password_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(tr('setup_password_desc'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        TextFormField(
          initialValue: widget.email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: tr('email_optional'),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          onChanged: widget.onEmailChanged,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: widget.password,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: tr('password_label'),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          onChanged: widget.onPasswordChanged,
        ),
        if (widget.password.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: strength,
                  backgroundColor: Colors.grey.shade200,
                  color: _getStrengthColor(strength),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getStrengthText(strength, tr),
                style: TextStyle(color: _getStrengthColor(strength), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          initialValue: widget.confirmPassword,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: tr('confirm_password_label'),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          onChanged: widget.onConfirmPasswordChanged,
        ),
        if (widget.confirmPassword.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                passwordsMatch ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: passwordsMatch ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                passwordsMatch ? (tr('passwords_match') != 'passwords_match' ? tr('passwords_match') : 'كلمتا المرور متطابقتان') : (tr('passwords_mismatch') != 'passwords_mismatch' ? tr('passwords_mismatch') : 'كلمتا المرور غير متطابقتين'),
                style: TextStyle(color: passwordsMatch ? Colors.green : Colors.red, fontSize: 12),
              ),
            ],
          ),
        ],
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            if (widget.password.isNotEmpty && widget.password != widget.confirmPassword) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr('passwords_mismatch') != 'passwords_mismatch' ? tr('passwords_mismatch') : 'تنبيه: كلمتا المرور غير متطابقتين'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            widget.onNext();
          },
          child: Text(tr('continue_registration')),
        ),
      ],
    );
  }
}

class PersonalInfoScreen extends ConsumerWidget {
  const PersonalInfoScreen({
    super.key,
    required this.fullName,
    required this.wilaya,
    required this.role,
    required this.onNameChanged,
    required this.onWilayaChanged,
    required this.onRoleChanged,
    required this.onNext,
    required this.onBack,
  });

  final String fullName;
  final String wilaya;
  final String role;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onWilayaChanged;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider).tr;
    final wilayas = ValidationService.getAlgerianWilayas();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
          Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
            ],
          ),
          const SizedBox(height: 48),
          Text(tr('personal_info_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(tr('personal_info_desc'), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          TextFormField(
            initialValue: fullName,
            decoration: InputDecoration(
              labelText: tr('full_name_label'),
              prefixIcon: const Icon(Icons.person_outline),
            ),
            onChanged: onNameChanged,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: tr('wilaya_label'),
              prefixIcon: const Icon(Icons.map_outlined),
            ),
            initialValue: wilayas.contains(wilaya) ? wilaya : null,
            items: wilayas.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: (value) => onWilayaChanged(value ?? ''),
          ),
          const SizedBox(height: 32),
          Text(tr('role_question'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onRoleChanged('rider'),
                  child: GlassContainer(
                    opacity: role == 'rider' ? 0.8 : 0.2,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.directions_walk, size: 48, color: role == 'rider' ? Theme.of(context).colorScheme.primary : Colors.grey),
                        const SizedBox(height: 8),
                        Text(tr('role_rider'), style: TextStyle(fontWeight: FontWeight.bold, color: role == 'rider' ? Theme.of(context).colorScheme.primary : Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => onRoleChanged('driver'),
                  child: GlassContainer(
                    opacity: role == 'driver' ? 0.8 : 0.2,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.directions_car, size: 48, color: role == 'driver' ? Theme.of(context).colorScheme.primary : Colors.grey),
                        const SizedBox(height: 8),
                        Text(tr('role_driver'), style: TextStyle(fontWeight: FontWeight.bold, color: role == 'driver' ? Theme.of(context).colorScheme.primary : Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          ElevatedButton(onPressed: onNext, child: Text(tr('next_btn'))),
        ],
    );
  }
}

class DriverVehicleScreen extends ConsumerWidget {
  const DriverVehicleScreen({
    super.key,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.plate,
    required this.onBrandChanged,
    required this.onModelChanged,
    required this.onYearChanged,
    required this.onColorChanged,
    required this.onPlateChanged,
    required this.onNext,
    required this.onBack,
  });

  final String brand;
  final String model;
  final String year;
  final String color;
  final String plate;
  final ValueChanged<String> onBrandChanged;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onYearChanged;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String> onPlateChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider).tr;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
            ],
          ),
          const SizedBox(height: 16),
          Text(tr('vehicle_data_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(tr('vehicle_data_desc'), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: brand,
                  decoration: InputDecoration(labelText: tr('vehicle_brand')),
                  onChanged: onBrandChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: model,
                  decoration: InputDecoration(labelText: tr('vehicle_model')),
                  onChanged: onModelChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: year,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: tr('vehicle_year')),
                  onChanged: onYearChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: color,
                  decoration: InputDecoration(labelText: tr('vehicle_color')),
                  onChanged: onColorChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: plate,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: tr('vehicle_plate'),
              prefixIcon: const Icon(Icons.pin),
            ),
            onChanged: onPlateChanged,
          ),
          const SizedBox(height: 48),
          ElevatedButton(onPressed: onNext, child: Text(tr('next_docs_btn'))),
        ],
      ),
    );
  }
}

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key, required this.onNext, required this.onBack});
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider).tr;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
            ],
          ),
          const Icon(Icons.document_scanner_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 32),
          Text(tr('verify_identity_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GlassContainer(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.credit_card, color: Colors.blue),
                  title: Text(tr('id_card_img')),
                  subtitle: Text(tr('upload_clear_img')),
                  trailing: const Icon(Icons.add_a_photo),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.car_crash, color: Colors.green),
                  title: Text(tr('driving_license')),
                  subtitle: Text(tr('drivers_only')),
                  trailing: const Icon(Icons.add_a_photo),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.face_retouching_natural, color: Colors.purple),
                  title: Text(tr('live_selfie')),
                  subtitle: Text(tr('verify_face_match')),
                  trailing: const Icon(Icons.camera_front),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: onNext, child: Text(tr('skip_demo_btn'))),
        ],
      ),
    );
  }
}

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key, required this.contacts, required this.onContactsChanged, required this.onNext, required this.onBack});
  final List<EmergencyContact> contacts;
  final ValueChanged<List<EmergencyContact>> onContactsChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends ConsumerState<EmergencyContactsScreen> {
  late final List<EmergencyContact> _contacts;
  bool _acceptedTerms = true;

  @override
  void initState() {
    super.initState();
    _contacts = List<EmergencyContact>.from(widget.contacts);
    if (_contacts.isEmpty) {
      _contacts.add(const EmergencyContact());
    }
  }

  void _updateContact(int index, EmergencyContact contact) {
    setState(() {
      _contacts[index] = contact;
    });
    widget.onContactsChanged(_contacts);
  }

  void _addContact() {
    if (_contacts.length < 3) {
      setState(() {
        _contacts.add(const EmergencyContact());
      });
      widget.onContactsChanged(_contacts);
    }
  }

  void _removeContact(int index) {
    if (_contacts.length > 1) {
      setState(() {
        _contacts.removeAt(index);
      });
      widget.onContactsChanged(_contacts);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider).tr;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
            ],
          ),
          const SizedBox(height: 16),
          Text(tr('emergency_contacts_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(tr('emergency_contacts_desc'), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ...List.generate(_contacts.length, (index) {
            final contact = _contacts[index];
            return GlassContainer(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${tr('emergency_contacts_title')} #${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
                      ),
                      if (_contacts.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeContact(index),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: contact.name,
                    decoration: InputDecoration(labelText: tr('contact_name'), prefixIcon: const Icon(Icons.person_outline)),
                    onChanged: (value) => _updateContact(index, contact.copyWith(name: value)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: contact.phone,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: tr('phone_label'), prefixIcon: const Icon(Icons.phone)),
                    onChanged: (value) => _updateContact(index, contact.copyWith(phone: value)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: contact.relationship,
                    decoration: InputDecoration(labelText: tr('contact_relation'), prefixIcon: const Icon(Icons.family_restroom)),
                    onChanged: (value) => _updateContact(index, contact.copyWith(relationship: value)),
                  ),
                ],
              ),
            );
          }),
          if (_contacts.length < 3)
            OutlinedButton.icon(
              onPressed: _addContact,
              icon: const Icon(Icons.add),
              label: Text(tr('add_contact_btn') != 'add_contact_btn' ? tr('add_contact_btn') : 'إضافة جهة اتصال أخرى'),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Checkbox(
                value: _acceptedTerms,
                activeColor: const Color(0xFFE91E63),
                onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsAcceptanceScreen()),
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      text: tr('agree_terms_prefix') != 'agree_terms_prefix' ? tr('agree_terms_prefix') : 'أوافق على ',
                      children: [
                        TextSpan(
                          text: tr('terms_and_conditions') != 'terms_and_conditions' ? tr('terms_and_conditions') : 'الشروط والأحكام وسياسة الخصوصية',
                          style: const TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (!_acceptedTerms) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr('must_accept_terms') != 'must_accept_terms' ? tr('must_accept_terms') : 'يجب الموافقة على الشروط والأحكام للمتابعة'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              widget.onNext();
            },
            child: Text(tr('finish_registration_btn')),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends ConsumerWidget {
  const LoginScreen({
    super.key,
    required this.email,
    required this.password,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onBack,
  });

  final String email;
  final String password;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider).tr;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
            ],
          ),
          const SizedBox(height: 16),
          Text(tr('login_title'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(tr('login_desc')),
          const SizedBox(height: 48),
          TextFormField(
            initialValue: email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: tr('email_label'),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            onChanged: onEmailChanged,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: tr('password_label'),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            onChanged: onPasswordChanged,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: onForgotPassword, child: Text(tr('forgot_password'))),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onLogin,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(tr('enter_btn'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          if (!AppConfig.isSupabaseConfigured) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TermsAcceptanceScreen()));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('تخطي - وضع تجريبي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider).tr;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 32),
          Text(tr('request_received_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(
            tr('request_received_desc'),
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.5, color: Colors.grey),
          ),
          if (!AppConfig.isSupabaseConfigured) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RideFlowScreen()));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: const Text('دخول لتجربة التطبيق (وضع تجريبي)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}
