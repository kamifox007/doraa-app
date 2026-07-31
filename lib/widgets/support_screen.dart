import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_providers.dart';


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

      // ✅ نستخدم safety_reports (الجدول الأصلي) بدلاً من support_tickets (المكرر)
      await Supabase.instance.client.from('safety_reports').insert({
        'reporter_id': userId,
        'reported_id': widget.targetId,      // الشخص المشتكى عليه
        'ride_id': widget.rideId,            // رقم الرحلة إن وجد
        'reason': _selectedCategory,         // نوع الشكوى الجاهز
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
      appBar: AppBar(
        title: Text(tr('help_and_complaints'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
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
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('support_intro_message'),
                      style: const TextStyle(color: Colors.orange, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            Text(tr('what_is_the_problem'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  hint: Text(tr('choose_complaint_type_hint')),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(tr('complaint_details_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: tr('complaint_details_hint'),
                alignLabelWithHint: true,
              ),
            ),
            
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _submitComplaint,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(tr('submit_complaint_btn'), style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
