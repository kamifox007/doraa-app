import 'dart:io';
import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import '../services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverRegistrationScreen extends ConsumerStatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  ConsumerState<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends ConsumerState<DriverRegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isSuccess = false;

  // Car Details
  String _wilaya = '';
  String _carBrand = '';
  String _carModel = '';
  String _carYear = '';
  String _carColor = '';
  String _carPlate = '';

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
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wilaya = prefs.getString('draft_wilaya') ?? '';
      _carBrand = prefs.getString('draft_carBrand') ?? '';
      _carModel = prefs.getString('draft_carModel') ?? '';
      _carYear = prefs.getString('draft_carYear') ?? '';
      _carColor = prefs.getString('draft_carColor') ?? '';
      _carPlate = prefs.getString('draft_carPlate') ?? '';

      _brandCtrl.text = _carBrand;
      _modelCtrl.text = _carModel;
      _yearCtrl.text = _carYear;
      _colorCtrl.text = _carColor;
      _plateCtrl.text = _carPlate;
    });
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_wilaya', _wilaya);
    await prefs.setString('draft_carBrand', _carBrand);
    await prefs.setString('draft_carModel', _carModel);
    await prefs.setString('draft_carYear', _carYear);
    await prefs.setString('draft_carColor', _carColor);
    await prefs.setString('draft_carPlate', _carPlate);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ مسودة بيانات السيارة بنجاح! للإكمال لاحقاً.'), backgroundColor: Colors.green),
      );
    }
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
    if (_wilaya.isEmpty || _carBrand.isEmpty || _carModel.isEmpty || _carPlate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('please_fill_car_details'))),
      );
      return;
    }
    if (_selfiePath == null || _licensePath == null || _carteGrisePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى رفع جميع الوثائق المطلوبة (الصورة الشخصية، الرخصة، والبطاقة الرمادية)')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('driver_profiles').upsert({
          'user_id': user.id,
          'car_brand': _carBrand,
          'car_model': _carModel,
          'car_year': _carYear,
          'car_color': _carColor,
          'car_plate': _carPlate,
          'vehicle_approval_status': 'pending', 
        });

        await Supabase.instance.client.from('user_profiles').update({
          'role': 'pending_driver',
          'wilaya': _wilaya,
        }).eq('user_id', user.id);

        final authService = AuthService();
        final selfieUrl = await authService.uploadIdentityDocument(userId: user.id, filePath: _selfiePath!, type: 'selfie');
        final licenseUrl = await authService.uploadIdentityDocument(userId: user.id, filePath: _licensePath!, type: 'driving_license');
        final carteGriseUrl = await authService.uploadIdentityDocument(userId: user.id, filePath: _carteGrisePath!, type: 'carte_grise');

        final docsToInsert = <Map<String, dynamic>>[];
        if (selfieUrl != null) docsToInsert.add({'user_id': user.id, 'type': 'selfie', 'file_url': selfieUrl});
        if (licenseUrl != null) docsToInsert.add({'user_id': user.id, 'type': 'driving_license', 'file_url': licenseUrl});
        if (carteGriseUrl != null) docsToInsert.add({'user_id': user.id, 'type': 'carte_grise', 'file_url': carteGriseUrl});
        
        if (docsToInsert.isNotEmpty) {
          await Supabase.instance.client.from('documents').insert(docsToInsert);
        }

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
          _pageController.animateToPage(2, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
        }
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
      if (_wilaya.isEmpty || _carBrand.isEmpty || _carModel.isEmpty || _carPlate.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تعبئة الحقول الأساسية للسيارة أولاً')));
        return;
      }
      _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (_currentPage == 1) {
      _submitApplication();
    }
  }

  void _prevPage() {
    if (_currentPage > 0 && !_isSuccess) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
              physics: const NeverScrollableScrollPhysics(), // Prevent manual swipe to enforce validation
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
          _buildStepIndicator(isActive: _currentPage >= 0, title: 'السيارة', step: 1),
          Expanded(child: Divider(color: _currentPage >= 1 ? const Color(0xFFE91E63) : Colors.grey.shade300, thickness: 2)),
          _buildStepIndicator(isActive: _currentPage >= 1, title: 'الوثائق', step: 2),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({required bool isActive, required String title, required int step}) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE91E63) : Colors.grey.shade200,
            shape: BoxShape.circle,
            boxShadow: isActive ? [BoxShadow(color: const Color(0xFFE91E63).withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2)] : null,
          ),
          alignment: Alignment.center,
          child: Text(step.toString(), style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: isActive ? const Color(0xFFE91E63) : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCarDetailsPage(String Function(String) tr) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          const Text('نطاق العمل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 12),
          _buildWilayaDropdown(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          const Text('معلومات السيارة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),

          const SizedBox(height: 8),
          Text('يرجى إدخال تفاصيل سيارتك بدقة كما هي مسجلة في البطاقة الرمادية.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          _buildInputField(label: tr('car_brand_hint'), icon: Icons.directions_car, controller: _brandCtrl, onChanged: (v) => _carBrand = v),
          const SizedBox(height: 16),
          _buildInputField(label: tr('car_model_hint'), icon: Icons.car_repair, controller: _modelCtrl, onChanged: (v) => _carModel = v),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInputField(label: tr('car_year_hint'), icon: Icons.calendar_today, controller: _yearCtrl, onChanged: (v) => _carYear = v, isNumber: true)),
              const SizedBox(width: 16),
              Expanded(child: _buildInputField(label: tr('car_color_hint'), icon: Icons.color_lens, controller: _colorCtrl, onChanged: (v) => _carColor = v)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(label: tr('car_plate_hint'), icon: Icons.pin, controller: _plateCtrl, onChanged: (v) => _carPlate = v),
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
          const Text('الوثائق الشخصية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
              boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
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
                      const Text('رسالة أمان وخصوصية', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(
                        'صورك ووثائقك مشفرة ومحمية بسرية تامة. لن تظهر هذه الوثائق للركاب أو لأي شخص على التطبيق إطلاقاً! الركاب سيرون فقط "صورتك الرمزية" التي تختارينها.',
                        style: TextStyle(color: Colors.green.shade800, fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildImagePickerRow(title: 'صورة سيلفي مع بطاقة الهوية', icon: Icons.face_rounded, path: _selfiePath, onPick: () => _pickImage('selfie')),
          const SizedBox(height: 16),
          _buildImagePickerRow(title: tr('driving_license_image'), icon: Icons.camera_alt, path: _licensePath, onPick: () => _pickImage('license')),
          const SizedBox(height: 16),
          _buildImagePickerRow(title: tr('carte_grise_image'), icon: Icons.credit_card, path: _carteGrisePath, onPick: () => _pickImage('carte_grise')),
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
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 100),
            ),
            const SizedBox(height: 32),
            const Text('تم الإرسال بنجاح!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 16),
            const Text(
              'لقد تم استلام طلبك ووثائقك بسرية تامة. ستقوم الإدارة بمراجعة طلبك والرد عليك في أقرب وقت. شكراً لانضمامك إلينا كشريكة!',
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('عودة للرئيسية', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({required String label, required IconData icon, required TextEditingController controller, required Function(String) onChanged, bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFE91E63)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: onChanged,
      ),
    );
  }


  Widget _buildWilayaDropdown() {
    final wilayas = [
      '1 - أدرار', '2 - الشلف', '3 - الأغواط', '4 - أم البواقي', '5 - باتنة', '6 - بجاية', '7 - بسكرة', '8 - بشار', '9 - البليدة', '10 - البويرة',
      '11 - تمنراست', '12 - تبسة', '13 - تلمسان', '14 - تيارت', '15 - تيزي وزو', '16 - الجزائر', '17 - الجلفة', '18 - جيجل', '19 - سطيف', '20 - سعيدة',
      '21 - سكيكدة', '22 - سيدي بلعباس', '23 - عنابة', '24 - قالمة', '25 - قسنطينة', '26 - المدية', '27 - مستغانم', '28 - المسيلة', '29 - معسكر', '30 - ورقلة',
      '31 - وهران', '32 - البيض', '33 - إليزي', '34 - برج بوعريريج', '35 - بومرداس', '36 - الطارف', '37 - تندوف', '38 - تسمسيلت', '39 - الوادي', '40 - خنشلة',
      '41 - سوق أهراس', '42 - تيبازة', '43 - ميلة', '44 - عين الدفلى', '45 - النعامة', '46 - عين تموشنت', '47 - غرداية', '48 - غليزان', '49 - تيميمون', '50 - برج باجي مختار',
      '51 - أولاد جلال', '52 - بني عباس', '53 - إن صالح', '54 - إن قزام', '55 - تقرت', '56 - جانت', '57 - المغير', '58 - المنيعة'
    ];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wilaya.isEmpty ? Colors.grey.shade300 : const Color(0xFFE91E63), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _wilaya.isEmpty ? null : _wilaya,
          hint: const Text('اختاري ولاية العمل...', style: TextStyle(color: Colors.grey)),
          isExpanded: true,
          icon: const Icon(Icons.location_on, color: Color(0xFFE91E63)),
          items: wilayas.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _wilaya = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildImagePickerRow
({required String title, required IconData icon, required String? path, required VoidCallback onPick}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
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
              image: path != null ? DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover) : null,
            ),
            child: path == null ? Icon(icon, color: Colors.grey.shade400, size: 30) : null,
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          ElevatedButton(
            onPressed: onPick,
            style: ElevatedButton.styleFrom(
              backgroundColor: path != null ? Colors.grey.shade100 : const Color(0xFFE91E63).withValues(alpha: 0.1),
              foregroundColor: path != null ? Colors.black87 : const Color(0xFFE91E63),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(path != null ? 'تغيير' : 'رفع'),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, -5))],
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: Colors.black54),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          _currentPage == 1 ? tr('submit_application_btn') : tr('next_btn'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _saveDraft,
              icon: const Icon(Icons.save_outlined, color: Colors.grey),
              label: const Text('حفظ كمسودة للإكمال لاحقاً', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
