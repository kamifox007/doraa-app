import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doraa/models/auth_models.dart';
import 'package:doraa/providers/auth_providers.dart';
import 'package:doraa/services/app_config.dart';
import 'package:doraa/services/validation_service.dart';
import 'package:doraa/services/translation_service.dart';
import 'package:doraa/features/legal/screens/terms_acceptance_screen.dart';

import 'package:doraa/features/auth/presentation/screens/welcome_screen.dart';
import 'package:doraa/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:doraa/features/auth/presentation/screens/phone_otp_screen.dart';
import 'package:doraa/features/auth/presentation/screens/email_password_screen.dart';
import 'package:doraa/features/auth/presentation/screens/personal_info_screen.dart';
import 'package:doraa/features/auth/presentation/screens/driver_vehicle_screen.dart';
import 'package:doraa/features/auth/presentation/screens/documents_screen.dart';
import 'package:doraa/features/auth/presentation/screens/emergency_contacts_screen.dart';
import 'package:doraa/features/auth/presentation/screens/login_screen.dart';
import 'package:doraa/features/auth/presentation/screens/pending_approval_screen.dart';

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
                          'ÙˆØ¶Ø¹ ØªØ¬Ø±ÙŠØ¨ÙŠ: ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„Ø§Ø³ØªÙ…Ø±Ø§Ø± ÙÙŠ ØªØµÙØ­ Ø§Ù„ÙˆØ§Ø¬Ù‡Ø§Øª Ø¨Ø¯ÙˆÙ† Supabase.',
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
                    WelcomeScreen(onNext: () => _goToPage(1)),
                    RoleSelectionScreen(
                      onRoleSelected: () => _goToPage(2),
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
                        messenger.showSnackBar(SnackBar(content: Text(ref.read(authProvider).message ?? 'ØªÙ… Ø§Ù„ØªØ­Ù‚Ù‚')));
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
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ø§Ù„Ø¨Ø±ÙŠØ¯ ØºÙŠØ± ØµØ§Ù„Ø­')));
                          return;
                        }
                        if (!ValidationService.isValidPassword(registration.password)) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± ÙŠØ¬Ø¨ Ø£Ù† ØªÙƒÙˆÙ† 8 Ø£Ø­Ø±Ù ÙˆØªØ­ØªÙˆÙŠ Ø¹Ù„Ù‰ Ø±Ù‚Ù… ÙˆØ­Ø±Ù ÙƒØ¨ÙŠØ±')));
                          return;
                        }
                        if (registration.password != registration.confirmPassword) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ÙƒÙ„Ù…ØªØ§ Ø§Ù„Ù…Ø±ÙˆØ± ØºÙŠØ± Ù…ØªØ·Ø§Ø¨Ù‚ØªÙŠÙ†')));
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
                            messenger.showSnackBar(const SnackBar(content: Text('Ø£Ø¶Ù Ø¬Ù‡Ø© Ø·ÙˆØ§Ø±Ø¦ ÙˆØ§Ø­Ø¯Ø© Ø¹Ù„Ù‰ Ø§Ù„Ø£Ù‚Ù„')));
                            return;
                          }
                        }
                        
                        if (AppConfig.isSupabaseConfigured) {
                          await ref.read(authProvider.notifier).completeRegistration(registration);
                          if (!mounted) return;
                          final authState = ref.read(authProvider);
                          messenger.showSnackBar(SnackBar(content: Text(authState.message ?? 'ØªÙ… Ø­ÙØ¸ Ø§Ù„Ù…Ù„Ù Ø§Ù„Ø´Ø®ØµÙŠ')));
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
                          messenger.showSnackBar(const SnackBar(content: Text('ÙˆØ¶Ø¹ ØªØ¬Ø±ÙŠØ¨ÙŠ - Ø¯Ø®ÙˆÙ„ Ù…Ø¨Ø§Ø´Ø±')));
                          navigator.pushReplacement(MaterialPageRoute(builder: (_) => const TermsAcceptanceScreen()));
                          return;
                        }
                        await ref.read(authProvider.notifier).signInWithEmail(email: registration.email, password: registration.password);
                        if (!mounted) return;
                        final authState = ref.read(authProvider);
                        messenger.showSnackBar(SnackBar(content: Text(authState.message ?? 'ØªÙ… ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„')));
                        if (authState.status == AuthStatus.authenticated) {
                          navigator.pushReplacement(MaterialPageRoute(builder: (_) => const TermsAcceptanceScreen()));
                        }
                      },
                      onForgotPassword: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ø³ÙŠØªÙ… Ø¥Ø¶Ø§ÙØ© Ø§Ø³ØªØ¹Ø§Ø¯Ø© ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± Ù„Ø§Ø­Ù‚Ù‹Ø§')));
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

