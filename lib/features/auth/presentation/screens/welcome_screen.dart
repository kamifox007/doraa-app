// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import '../../../../providers/auth_providers.dart';
import '../../../../widgets/glass_container.dart';

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
        const SnackBar(content: Text('يرجى إدخال اسمك الكريم')),
      );
      return;
    }
    if (_selectedWilaya == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الولاية')),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFCE4EC), Colors.white],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: _isLoadingLink
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // شعار ترحيبي
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE91E63).withValues(alpha: 0.2),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.favorite_rounded, size: 60, color: Color(0xFFE91E63)),
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (_invitedWilaya != null) ...[
                        Text(
                          'مرحباً بك في DORA $_invitedWilaya!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: const Color(0xFFE91E63),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لقد تمت دعوتك للانضمام، نحن سعداء بوجودك معنا.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                        ),
                      ] else ...[
                        Text(
                          'أهلاً بك في عائلة DORA',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: const Color(0xFF333333),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'المنصة الأولى المصممة خصيصاً لراحة وأمان المرأة',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(height: 48),

                      GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'لنتعرف عليكِ أولاً',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 24),
                            
                            // إدخال الاسم
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'الاسم (كما ترغبين أن نناديكِ)',
                                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFE91E63)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // اختيار الولاية
                            DropdownButtonFormField<String>(
                              value: _selectedWilaya,
                              decoration: InputDecoration(
                                labelText: 'ولاية إقامتك',
                                prefixIcon: const Icon(Icons.location_city_rounded, color: Color(0xFFE91E63)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
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
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _handleNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'متابعة',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
