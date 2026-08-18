import 'dart:io';
import 'package:flutter/material.dart';
import 'package:doraa/services/translation_service.dart';
import 'package:doraa/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverRegistrationScreen extends ConsumerStatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  ConsumerState<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState
    extends ConsumerState<DriverRegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isSuccess = false;

  // Car Details
  String _wilaya = '';

  // Document Paths
  String? _selfiePath;
  String? _licensePath;
  String? _carteGrisePath;

  // Controllers to pre-fill draft data
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _modelCtrl = TextEditingController();
  final TextEditingController _yearCtrl = TextEditingController();
  final TextEditingController _colorCtrl = TextEditingController();
  final TextEditingController _plateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    _brandCtrl.addListener(_saveDraft);
    _modelCtrl.addListener(_saveDraft);
    _yearCtrl.addListener(_saveDraft);
    _colorCtrl.addListener(_saveDraft);
    _plateCtrl.addListener(_saveDraft);

    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        if (_wilaya.isEmpty) { _wilaya = prefs.getString('draft_wilaya') ?? ''; }
        if (_brandCtrl.text.isEmpty) { _brandCtrl.text = prefs.getString('draft_carBrand') ?? ''; }
        if (_modelCtrl.text.isEmpty) { _modelCtrl.text = prefs.getString('draft_carModel') ?? ''; }
        if (_yearCtrl.text.isEmpty) { _yearCtrl.text = prefs.getString('draft_carYear') ?? ''; }
        if (_colorCtrl.text.isEmpty) { _colorCtrl.text = prefs.getString('draft_carColor') ?? ''; }
        if (_plateCtrl.text.isEmpty) { _plateCtrl.text = prefs.getString('draft_carPlate') ?? ''; }
      });
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_wilaya', _wilaya);
    await prefs.setString('draft_carBrand', _brandCtrl.text);
    await prefs.setString('draft_carModel', _modelCtrl.text);
    await prefs.setString('draft_carYear', _yearCtrl.text);
    await prefs.setString('draft_carColor', _colorCtrl.text);
    await prefs.setString('draft_carPlate', _plateCtrl.text);
  }

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (type == 'selfie') _selfiePath = picked.path;
        if (type == 'license') _licensePath = picked.path;
        if (type == 'carte_grise') _carteGrisePath = picked.path;
      });
    }
  }

  Future<void> _submitApplication() async {
    final tr = ref.read(translationProvider).tr;
    if (_wilaya.isEmpty ||
        _brandCtrl.text.trim().isEmpty ||
        _modelCtrl.text.trim().isEmpty ||
        _yearCtrl.text.trim().isEmpty ||
        _colorCtrl.text.trim().isEmpty ||
        _plateCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تعبئة الحقول الأساسية للسيارة أولاً'),
        ),
      );
      return;
    }
    if (_selfiePath == null ||
        _licensePath == null ||
        _carteGrisePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى رفع جميع الوثائق المطلوبة (الصورة الشخصية، الرخصة، والبطاقة الرمادية)',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User is not logged in. Please login first.');
      }

      await Supabase.instance.client.from('driver_profiles').upsert({
        'user_id': user.id,
        'car_brand': _brandCtrl.text.trim(),
        'car_model': _modelCtrl.text.trim(),
        'car_year': _yearCtrl.text.trim(),
        'car_color': _colorCtrl.text.trim(),
        'car_plate': _plateCtrl.text.trim(),
        'vehicle_approval_status': 'pending',
      });

      await Supabase.instance.client
          .from('user_profiles')
          .update({'role': 'pending_driver', 'wilaya': _wilaya})
          .eq('user_id', user.id);

      final authService = AuthService();
      final selfieUrl = await authService.uploadIdentityDocument(
        userId: user.id,
        filePath: _selfiePath!,
        type: 'selfie',
      );
      final licenseUrl = await authService.uploadIdentityDocument(
        userId: user.id,
        filePath: _licensePath!,
        type: 'driving_license',
      );
      final carteGriseUrl = await authService.uploadIdentityDocument(
        userId: user.id,
        filePath: _carteGrisePath!,
        type: 'carte_grise',
      );

      if (selfieUrl == null || licenseUrl == null || carteGriseUrl == null) {
        throw Exception(
          'Failed to upload one or more documents. Please check your connection and try again.',
        );
      }

      final docsToInsert = <Map<String, dynamic>>[
        {'user_id': user.id, 'type': 'selfie', 'file_url': selfieUrl},
        {'user_id': user.id, 'type': 'driving_license', 'file_url': licenseUrl},
        {'user_id': user.id, 'type': 'carte_grise', 'file_url': carteGriseUrl},
      ];

      await Supabase.instance.client.from('documents').insert(docsToInsert);

      // Clear draft on success
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('draft_wilaya');
      await prefs.remove('draft_carBrand');
      await prefs.remove('draft_carModel');
      await prefs.remove('draft_carYear');
      await prefs.remove('draft_carColor');
      await prefs.remove('draft_carPlate');

      if (mounted) {
        setState(() => _isSuccess = true);
        _pageController.animateToPage(
          2,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('error_occurred_prefix')} $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    if (_currentPage == 0) {
      // Basic validation before swiping
      if (_wilaya.isEmpty ||
          _brandCtrl.text.trim().isEmpty ||
          _modelCtrl.text.trim().isEmpty ||
          _yearCtrl.text.trim().isEmpty ||
          _colorCtrl.text.trim().isEmpty ||
          _plateCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ÙŠØ±Ø¬Ù‰ ØªØ¹Ø¨Ø¦Ø© Ø§Ù„Ø­Ù‚ÙˆÙ„ Ø§Ù„Ø£Ø³Ø§Ø³ÙŠØ© Ù„Ù„Ø³ÙŠØ§Ø±Ø© Ø£ÙˆÙ„Ø§Ù‹',
            ),
          ),
        );
        return;
      }
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentPage == 1) {
      _submitApplication();
    }
  }

  void _prevPage() {
    if (_currentPage > 0 && !_isSuccess) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider).tr;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5FF),
      appBar: AppBar(
        title: Text(tr('join_as_captain_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFFE91E63),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (!_isSuccess) _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // Prevent manual swipe to enforce validation
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              children: [
                _buildCarDetailsPage(tr),
                _buildDocumentsPage(tr),
                _buildSuccessPage(),
              ],
            ),
          ),
          if (!_isSuccess) _buildBottomNavigation(tr),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStepIndicator(
            isActive: _currentPage >= 0,
            title: 'Ø§Ù„Ø³ÙŠØ§Ø±Ø©',
            step: 1,
          ),
          Expanded(
            child: Divider(
              color: _currentPage >= 1
                  ? const Color(0xFFE91E63)
                  : Colors.grey.shade300,
              thickness: 2,
            ),
          ),
          _buildStepIndicator(
            isActive: _currentPage >= 1,
            title: 'Ø§Ù„ÙˆØ«Ø§Ø¦Ù‚',
            step: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required bool isActive,
    required String title,
    required int step,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE91E63) : Colors.grey.shade200,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            step.toString(),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFFE91E63) : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCarDetailsPage(String Function(String) tr) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ù†Ø·Ø§Ù‚ Ø§Ù„Ø¹Ù…Ù„',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          _buildWilayaDropdown(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          const Text(
            'Ù…Ø¹Ù„ÙˆÙ…Ø§Øª Ø§Ù„Ø³ÙŠØ§Ø±Ø©',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'ÙŠØ±Ø¬Ù‰ Ø¥Ø¯Ø®Ø§Ù„ ØªÙØ§ØµÙŠÙ„ Ø³ÙŠØ§Ø±ØªÙƒ Ø¨Ø¯Ù‚Ø© ÙƒÙ…Ø§ Ù‡ÙŠ Ù…Ø³Ø¬Ù„Ø© ÙÙŠ Ø§Ù„Ø¨Ø·Ø§Ù‚Ø© Ø§Ù„Ø±Ù…Ø§Ø¯ÙŠØ©.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          _buildInputField(
            label: tr('car_brand_hint'),
            icon: Icons.directions_car,
            controller: _brandCtrl,
            onChanged: (v) {},
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: tr('car_model_hint'),
            icon: Icons.car_repair,
            controller: _modelCtrl,
            onChanged: (v) {},
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: tr('car_year_hint'),
                  icon: Icons.calendar_today,
                  controller: _yearCtrl,
                  onChanged: (v) {},
                  isNumber: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  label: tr('car_color_hint'),
                  icon: Icons.color_lens,
                  controller: _colorCtrl,
                  onChanged: (v) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: tr('car_plate_hint'),
            icon: Icons.pin,
            controller: _plateCtrl,
            onChanged: (v) {},
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsPage(String Function(String) tr) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ø§Ù„ÙˆØ«Ø§Ø¦Ù‚ Ø§Ù„Ø´Ø®ØµÙŠØ©',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_rounded, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ø±Ø³Ø§Ù„Ø© Ø£Ù…Ø§Ù† ÙˆØ®ØµÙˆØµÙŠØ©',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ØµÙˆØ±Ùƒ ÙˆÙˆØ«Ø§Ø¦Ù‚Ùƒ Ù…Ø´ÙØ±Ø© ÙˆÙ…Ø­Ù…ÙŠØ© Ø¨Ø³Ø±ÙŠØ© ØªØ§Ù…Ø©. Ù„Ù† ØªØ¸Ù‡Ø± Ù‡Ø°Ù‡ Ø§Ù„ÙˆØ«Ø§Ø¦Ù‚ Ù„Ù„Ø±ÙƒØ§Ø¨ Ø£Ùˆ Ù„Ø£ÙŠ Ø´Ø®Øµ Ø¹Ù„Ù‰ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ø¥Ø·Ù„Ø§Ù‚Ø§Ù‹! Ø§Ù„Ø±ÙƒØ§Ø¨ Ø³ÙŠØ±ÙˆÙ† ÙÙ‚Ø· "ØµÙˆØ±ØªÙƒ Ø§Ù„Ø±Ù…Ø²ÙŠØ©" Ø§Ù„ØªÙŠ ØªØ®ØªØ§Ø±ÙŠÙ†Ù‡Ø§.',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildImagePickerRow(
            title: 'ØµÙˆØ±Ø© Ø³ÙŠÙ„ÙÙŠ Ù…Ø¹ Ø¨Ø·Ø§Ù‚Ø© Ø§Ù„Ù‡ÙˆÙŠØ©',
            icon: Icons.face_rounded,
            path: _selfiePath,
            onPick: () => _pickImage('selfie'),
          ),
          const SizedBox(height: 16),
          _buildImagePickerRow(
            title: tr('driving_license_image'),
            icon: Icons.camera_alt,
            path: _licensePath,
            onPick: () => _pickImage('license'),
          ),
          const SizedBox(height: 16),
          _buildImagePickerRow(
            title: tr('carte_grise_image'),
            icon: Icons.credit_card,
            path: _carteGrisePath,
            onPick: () => _pickImage('carte_grise'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 100,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'ØªÙ… Ø§Ù„Ø¥Ø±Ø³Ø§Ù„ Ø¨Ù†Ø¬Ø§Ø­!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ù„Ù‚Ø¯ ØªÙ… Ø§Ø³ØªÙ„Ø§Ù… Ø·Ù„Ø¨Ùƒ ÙˆÙˆØ«Ø§Ø¦Ù‚Ùƒ Ø¨Ø³Ø±ÙŠØ© ØªØ§Ù…Ø©. Ø³ØªÙ‚ÙˆÙ… Ø§Ù„Ø¥Ø¯Ø§Ø±Ø© Ø¨Ù…Ø±Ø§Ø¬Ø¹Ø© Ø·Ù„Ø¨Ùƒ ÙˆØ§Ù„Ø±Ø¯ Ø¹Ù„ÙŠÙƒ ÙÙŠ Ø£Ù‚Ø±Ø¨ ÙˆÙ‚Øª. Ø´ÙƒØ±Ø§Ù‹ Ù„Ø§Ù†Ø¶Ù…Ø§Ù…Ùƒ Ø¥Ù„ÙŠÙ†Ø§ ÙƒØ´Ø±ÙŠÙƒØ©!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Ø¹ÙˆØ¯Ø© Ù„Ù„Ø±Ø¦ÙŠØ³ÙŠØ©',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Function(String) onChanged,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFE91E63)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildWilayaDropdown() {
    final wilayas = [
      '1 - Ø£Ø¯Ø±Ø§Ø±',
      '2 - Ø§Ù„Ø´Ù„Ù',
      '3 - Ø§Ù„Ø£ØºÙˆØ§Ø·',
      '4 - Ø£Ù… Ø§Ù„Ø¨ÙˆØ§Ù‚ÙŠ',
      '5 - Ø¨Ø§ØªÙ†Ø©',
      '6 - Ø¨Ø¬Ø§ÙŠØ©',
      '7 - Ø¨Ø³ÙƒØ±Ø©',
      '8 - Ø¨Ø´Ø§Ø±',
      '9 - Ø§Ù„Ø¨Ù„ÙŠØ¯Ø©',
      '10 - Ø§Ù„Ø¨ÙˆÙŠØ±Ø©',
      '11 - ØªÙ…Ù†Ø±Ø§Ø³Øª',
      '12 - ØªØ¨Ø³Ø©',
      '13 - ØªÙ„Ù…Ø³Ø§Ù†',
      '14 - ØªÙŠØ§Ø±Øª',
      '15 - ØªÙŠØ²ÙŠ ÙˆØ²Ùˆ',
      '16 - Ø§Ù„Ø¬Ø²Ø§Ø¦Ø±',
      '17 - Ø§Ù„Ø¬Ù„ÙØ©',
      '18 - Ø¬ÙŠØ¬Ù„',
      '19 - Ø³Ø·ÙŠÙ',
      '20 - Ø³Ø¹ÙŠØ¯Ø©',
      '21 - Ø³ÙƒÙŠÙƒØ¯Ø©',
      '22 - Ø³ÙŠØ¯ÙŠ Ø¨Ù„Ø¹Ø¨Ø§Ø³',
      '23 - Ø¹Ù†Ø§Ø¨Ø©',
      '24 - Ù‚Ø§Ù„Ù…Ø©',
      '25 - Ù‚Ø³Ù†Ø·ÙŠÙ†Ø©',
      '26 - Ø§Ù„Ù…Ø¯ÙŠØ©',
      '27 - Ù…Ø³ØªØºØ§Ù†Ù…',
      '28 - Ø§Ù„Ù…Ø³ÙŠÙ„Ø©',
      '29 - Ù…Ø¹Ø³ÙƒØ±',
      '30 - ÙˆØ±Ù‚Ù„Ø©',
      '31 - ÙˆÙ‡Ø±Ø§Ù†',
      '32 - Ø§Ù„Ø¨ÙŠØ¶',
      '33 - Ø¥Ù„ÙŠØ²ÙŠ',
      '34 - Ø¨Ø±Ø¬ Ø¨ÙˆØ¹Ø±ÙŠØ±ÙŠØ¬',
      '35 - Ø¨ÙˆÙ…Ø±Ø¯Ø§Ø³',
      '36 - Ø§Ù„Ø·Ø§Ø±Ù',
      '37 - ØªÙ†Ø¯ÙˆÙ',
      '38 - ØªØ³Ù…Ø³ÙŠÙ„Øª',
      '39 - Ø§Ù„ÙˆØ§Ø¯ÙŠ',
      '40 - Ø®Ù†Ø´Ù„Ø©',
      '41 - Ø³ÙˆÙ‚ Ø£Ù‡Ø±Ø§Ø³',
      '42 - ØªÙŠØ¨Ø§Ø²Ø©',
      '43 - Ù…ÙŠÙ„Ø©',
      '44 - Ø¹ÙŠÙ† Ø§Ù„Ø¯ÙÙ„Ù‰',
      '45 - Ø§Ù„Ù†Ø¹Ø§Ù…Ø©',
      '46 - Ø¹ÙŠÙ† ØªÙ…ÙˆØ´Ù†Øª',
      '47 - ØºØ±Ø¯Ø§ÙŠØ©',
      '48 - ØºÙ„ÙŠØ²Ø§Ù†',
      '49 - ØªÙŠÙ…ÙŠÙ…ÙˆÙ†',
      '50 - Ø¨Ø±Ø¬ Ø¨Ø§Ø¬ÙŠ Ù…Ø®ØªØ§Ø±',
      '51 - Ø£ÙˆÙ„Ø§Ø¯ Ø¬Ù„Ø§Ù„',
      '52 - Ø¨Ù†ÙŠ Ø¹Ø¨Ø§Ø³',
      '53 - Ø¥Ù† ØµØ§Ù„Ø­',
      '54 - Ø¥Ù† Ù‚Ø²Ø§Ù…',
      '55 - ØªÙ‚Ø±Øª',
      '56 - Ø¬Ø§Ù†Øª',
      '57 - Ø§Ù„Ù…ØºÙŠØ±',
      '58 - Ø§Ù„Ù…Ù†ÙŠØ¹Ø©',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _wilaya.isEmpty
              ? Colors.grey.shade300
              : const Color(0xFFE91E63),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _wilaya.isEmpty ? null : _wilaya,
          hint: const Text(
            'Ø§Ø®ØªØ§Ø±ÙŠ ÙˆÙ„Ø§ÙŠØ© Ø§Ù„Ø¹Ù…Ù„...',
            style: TextStyle(color: Colors.grey),
          ),
          isExpanded: true,
          icon: const Icon(Icons.location_on, color: Color(0xFFE91E63)),
          items: wilayas.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _wilaya = newValue!;
            });
            _saveDraft();
          },
        ),
      ),
    );
  }

  Widget _buildImagePickerRow({
    required String title,
    required IconData icon,
    required String? path,
    required VoidCallback onPick,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: path != null ? null : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              image: path != null
                  ? DecorationImage(
                      image: FileImage(File(path)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: path == null
                ? Icon(icon, color: Colors.grey.shade400, size: 30)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: onPick,
            style: ElevatedButton.styleFrom(
              backgroundColor: path != null
                  ? Colors.grey.shade100
                  : const Color(0xFFE91E63).withValues(alpha: 0.1),
              foregroundColor: path != null
                  ? Colors.black87
                  : const Color(0xFFE91E63),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(path != null ? 'ØªØºÙŠÙŠØ±' : 'Ø±ÙØ¹'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(String Function(String) tr) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (_currentPage > 0) ...[
                  OutlinedButton(
                    onPressed: _prevPage,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 20,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _currentPage == 1
                                ? tr('submit_application_btn')
                                : tr('next_btn'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _saveDraft,
              icon: const Icon(Icons.save_outlined, color: Colors.grey),
              label: const Text(
                'Ø­ÙØ¸ ÙƒÙ…Ø³ÙˆØ¯Ø© Ù„Ù„Ø¥ÙƒÙ…Ø§Ù„ Ù„Ø§Ø­Ù‚Ø§Ù‹',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
