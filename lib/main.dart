import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/app_config.dart';
import 'services/stitch_service.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/auth_flow.dart';
import 'widgets/glass_container.dart';
import 'providers/locale_provider.dart';
import 'services/translation_service.dart';
import 'core/security/root_detection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. اعرض Splash فوراً
  runApp(const SplashApp());

  // 2. Initialize في الخلفية
  _initializeApp().then((_) async {
    // 3. فحص الأمان
    final isSecure = await SecurityCheck.isDeviceSecure();
    if (!isSecure) {
      runApp(const SecurityBlockApp());
      return;
    }
    
    // 4. تشغيل التطبيق الفعلي
    runApp(const ProviderScope(child: MyApp()));
  });
}

Future<void> _initializeApp() async {
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp();
    }
    await SupabaseService.initialize();
    await Hive.initFlutter();
    
    // إعداد قراءة الروابط العميقة (Deep Links) لتحديد الولاية
    try {
      final appLinks = AppLinks();
      
      // قراءة الرابط إذا كان التطبيق مغلقاً وفتح عبر الرابط
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
      
      // قراءة الروابط إذا كان التطبيق مفتوحاً في الخلفية
      appLinks.uriLinkStream.listen((uri) {
        _handleDeepLink(uri);
      });
    } catch (e) {
      debugPrint("AppLinks Error: $e");
    }
    
    if (!kIsWeb) {
      await PushNotificationService().initialize();
      await NotificationService().init();
    }
  } catch (e) {
    debugPrint("Initialization Error: $e");
  }
}

void _handleDeepLink(Uri uri) async {
  // فحص إذا كان الرابط يحتوي على معامل ?wilaya=
  if (uri.queryParameters.containsKey('wilaya')) {
    final wilaya = uri.queryParameters['wilaya'];
    if (wilaya != null && wilaya.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('referral_wilaya', wilaya);
      debugPrint("تم تسجيل الولاية من الرابط: $wilaya");
    }
  }
}

class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF00897B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.directions_car_filled, size: 80, color: Colors.white),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class SecurityBlockApp extends StatelessWidget {
  const SecurityBlockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gpp_bad_rounded, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'جهاز غير آمن / Unsafe Device',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'تم اكتشاف تعديل على النظام (Root/Jailbreak). لا يمكن استخدام التطبيق لأسباب أمنية.\n\nSystem modification (Root/Jailbreak) detected. App cannot be used for security reasons.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => SystemNavigator.pop(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('خروج / Exit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeString = ref.watch(localeProvider);
    final isRtl = localeString == 'ar';

    return MaterialApp(
      title: 'Doraa App',
      debugShowCheckedModeBanner: false,
      locale: Locale(localeString),
      supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
      builder: (context, child) {
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E63), // Pink primary
          primary: const Color(0xFFE91E63),
          secondary: const Color(0xFF00897B), // Teal accent
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: const Color(0xFFF9FAFC),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: const Color(0xFFE91E63).withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE91E63),
            side: const BorderSide(color: Color(0xFFE91E63), width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
          ),
        ),
      ),
      home: AppConfig.isSupabaseConfigured ? const AuthFlowScreen() : const HomePage(),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  String supabaseStatus = 'جاري الفحص...';
  String stitchStatus = 'جاري الفحص...';
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _referralWilaya;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();
    _loadStatuses();
    _loadReferralWilaya();
  }

  Future<void> _loadReferralWilaya() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _referralWilaya = prefs.getString('referral_wilaya');
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStatuses() async {
    final supabaseResult = await SupabaseService.getHealth();
    final stitchResult = await StitchService.ping();

    setState(() {
      if (supabaseResult == null) {
        supabaseStatus = 'Supabase غير مُهيأ بعد';
      } else if (supabaseResult['status'] == 'ok') {
        supabaseStatus = 'متصل بـ Supabase';
      } else {
        supabaseStatus = 'خطأ: ${supabaseResult['message']}';
      }

      if (stitchResult['status'] == 'ok') {
        stitchStatus = 'جاهز لـ Stitch';
      } else {
        stitchStatus = 'Stitch غير مُهيأ بعد';
      }

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFCE4EC), // Very light pink
              Color(0xFFE0F2F1), // Very light teal
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Language Switcher
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.language, color: Colors.grey),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: ref.watch(localeProvider),
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'ar', child: Text('العربية')),
                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(localeProvider.notifier).setLocale(val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Consumer(
                        builder: (context, ref, child) {
                          final tr = ref.watch(translationProvider).tr;
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.pink.withValues(alpha: 0.1),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.directions_car_filled,
                                  size: 64,
                                  color: Color(0xFFE91E63),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                _referralWilaya != null ? 'Dora ${_referralWilaya![0].toUpperCase()}${_referralWilaya!.substring(1)}' : tr('app_name'),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFE91E63),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tr('app_subtitle'),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.grey.shade700,
                                    ),
                              ),
                              const SizedBox(height: 48),
                              GlassContainer(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildStatusRow(
                                      icon: Icons.cloud_done_rounded,
                                      title: tr('db_status'),
                                      status: isLoading ? tr('checking') : supabaseStatus,
                                      isOk: AppConfig.isSupabaseConfigured,
                                    ),
                                    const Divider(height: 32),
                                    _buildStatusRow(
                                      icon: Icons.api_rounded,
                                      title: tr('backend_status'),
                                      status: isLoading ? tr('checking') : stitchStatus,
                                      isOk: AppConfig.isStitchConfigured,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 48),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(builder: (_) => const AuthFlowScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                                  label: Text(
                                    tr('start_app'),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow({required IconData icon, required String title, required String status, required bool isOk}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isOk ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isOk ? Colors.green : Colors.orange, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
            ],
          ),
        ),
        Icon(
          isOk ? Icons.check_circle_rounded : Icons.pending_rounded,
          color: isOk ? Colors.green : Colors.orange,
        ),
      ],
    );
  }
}
