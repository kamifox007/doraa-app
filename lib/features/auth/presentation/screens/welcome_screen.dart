// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../providers/auth_providers.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _nameController = TextEditingController();
  String? _selectedWilaya;
  bool _isLoadingLink = true;
  String? _invitedWilaya;

  final List<String> _wilayas = [
    'الجزائر العاصمة', 'وهران', 'قسنطينة', 'عنابة', 'باتنة', 
    'سطيف', 'تلمسان', 'البليدة', 'بجاية', 'سكيكدة',
  ];

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    
    try {
      // الحصول على الرابط الأولي (إذا تم فتح التطبيق منه)
      final initialUri = await _appLinks.getInitialLink();
      _handleDeepLink(initialUri);
    } catch (e) {
      debugPrint('Error reading initial app link: $e');
    }

    // الاستماع للروابط أثناء فتح التطبيق
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    if (mounted) {
      setState(() => _isLoadingLink = false);
    }
  }

  void _handleDeepLink(Uri? uri) {
    if (uri != null) {
      // توقع الرابط: dora.com/invite?wilaya=Algiers
      final wilaya = uri.queryParameters['wilaya'];
      if (wilaya != null && wilaya.isNotEmpty) {
        setState(() {
          _invitedWilaya = wilaya;
          // تعيين الولاية المحددة إذا كانت متوفرة في القائمة، وإلا نختار الأولى
          _selectedWilaya = _wilayas.contains(wilaya) ? wilaya : _wilayas.first;
        });
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسمك الكريم', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFFFFD700),
        ),
      );
      return;
    }
    if (_selectedWilaya == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الولاية', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFFFFD700),
        ),
      );
      return;
    }

    // تحديث الحالة
    ref.read(registrationProvider.notifier).updateFullName(name);
    ref.read(registrationProvider.notifier).updateWilaya(_selectedWilaya!);

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark premium background
      body: SafeArea(
        child: _isLoadingLink
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    
                    // شعار ترحيبي
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.diamond_rounded, size: 64, color: Color(0xFFFFD700)),
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fade(),
                    
                    const SizedBox(height: 32),

                    if (_invitedWilaya != null) ...[
                      Text(
                        'مرحباً بكِ في DZdora $_invitedWilaya!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: const Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                            ),
                      ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 12),
                      Text(
                        'لقد تمت دعوتكِ للانضمام، نحن سعداء بوجودكِ معنا في مجتمعنا الراقي.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade400, height: 1.5),
                      ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),
                    ] else ...[
                      Text(
                        'أهلاً بكِ في عائلة DZdora',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: const Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                            ),
                      ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 12),
                      Text(
                        'المنصة الأولى المصممة خصيصاً لراحة وأمان المرأة، بمعايير VIP.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade400, height: 1.5),
                      ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),
                    ],
                    
                    const SizedBox(height: 48),

                    Container(
                      padding: const EdgeInsets.all(24),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'لنتعرف عليكِ أولاً ✨',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ).animate().fade(delay: 400.ms),
                          const SizedBox(height: 24),
                          
                          // إدخال الاسم
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'الاسم (كما ترغبين أن نناديكِ)',
                              labelStyle: TextStyle(color: Colors.grey.shade500),
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFFFFD700)),
                              filled: true,
                              fillColor: const Color(0xFF121212),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                              ),
                            ),
                          ).animate().fade(delay: 500.ms).slideY(begin: 0.2, end: 0),
                          
                          const SizedBox(height: 20),

                          // اختيار الولاية
                          DropdownButtonFormField<String>(
                            value: _selectedWilaya,
                            dropdownColor: const Color(0xFF1E1E1E),
                            style: const TextStyle(color: Colors.white),
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFFFD700)),
                            decoration: InputDecoration(
                              labelText: 'ولاية إقامتك',
                              labelStyle: TextStyle(color: Colors.grey.shade500),
                              prefixIcon: const Icon(Icons.location_city_rounded, color: Color(0xFFFFD700)),
                              filled: true,
                              fillColor: const Color(0xFF121212),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                              ),
                            ),
                            items: _wilayas.map((String wilaya) {
                              return DropdownMenuItem<String>(
                                value: wilaya,
                                child: Text(wilaya),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedWilaya = newValue;
                              });
                            },
                          ).animate().fade(delay: 600.ms).slideY(begin: 0.2, end: 0),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),

                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _handleNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700), // Gold
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 5,
                          shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        ),
                        child: const Text(
                          'متابعة',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ).animate().fade(delay: 700.ms).slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}
