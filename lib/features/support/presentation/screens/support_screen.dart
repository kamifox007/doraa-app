import 'package:flutter/material.dart';
import 'package:doraa/services/translation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:doraa/providers/auth_providers.dart';


class SupportScreen extends ConsumerStatefulWidget {
  final String? rideId;
  final String? targetId;

  const SupportScreen({super.key, this.rideId, this.targetId});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  Future<void> _submitComplaint() async {
    final tr = ref.read(translationProvider).tr;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('please_select_complaint_type'))));
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('please_write_problem_details'))));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = ref.read(authProvider).userId;
      if (userId == null) throw Exception(tr('user_not_logged_in'));

      // âœ… Ù†Ø³ØªØ®Ø¯Ù… safety_reports (Ø§Ù„Ø¬Ø¯ÙˆÙ„ Ø§Ù„Ø£ØµÙ„ÙŠ) Ø¨Ø¯Ù„Ø§Ù‹ Ù…Ù† support_tickets (Ø§Ù„Ù…ÙƒØ±Ø±)
      await Supabase.instance.client.from('safety_reports').insert({
        'reporter_id': userId,
        'reported_id': widget.targetId,      // Ø§Ù„Ø´Ø®Øµ Ø§Ù„Ù…Ø´ØªÙƒÙ‰ Ø¹Ù„ÙŠÙ‡
        'ride_id': widget.rideId,            // Ø±Ù‚Ù… Ø§Ù„Ø±Ø­Ù„Ø© Ø¥Ù† ÙˆØ¬Ø¯
        'reason': _selectedCategory,         // Ù†ÙˆØ¹ Ø§Ù„Ø´ÙƒÙˆÙ‰ Ø§Ù„Ø¬Ø§Ù‡Ø²
        'details': _descriptionController.text.trim(),
        'status': 'open',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('complaint_sent_success'))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('error_occurred_prefix')} $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider).tr;
    final List<String> categories = [
      tr('category_delay'),
      tr('category_car_mismatch'),
      tr('category_bad_behavior'),
      tr('category_payment_issue'),
      tr('category_other'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(tr('help_and_complaints'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF121212),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFFFD700)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('support_intro_message'),
                      style: const TextStyle(color: Color(0xFFFFD700), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            Text(tr('what_is_the_problem'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  dropdownColor: const Color(0xFF1E1E1E),
                  iconEnabledColor: const Color(0xFFFFD700),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  isExpanded: true,
                  hint: Text(tr('choose_complaint_type_hint'), style: const TextStyle(color: Colors.white54)),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(tr('complaint_details_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: tr('complaint_details_hint'),
                hintStyle: const TextStyle(color: Colors.white54),
                alignLabelWithHint: true,
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFFFD700)),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _submitComplaint,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text(tr('submit_complaint_btn'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

