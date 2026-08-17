import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/translation_service.dart';
import '../../../../models/auth_models.dart';
import '../../../legal/screens/terms_acceptance_screen.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark premium background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: widget.onBack, 
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFFD700)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            
            // Animated Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.contact_emergency_rounded, size: 60, color: Color(0xFFFFD700)),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fade(),
            
            const SizedBox(height: 32),
            
            Text(
              tr('emergency_contacts_title'), 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ), 
              textAlign: TextAlign.center,
            ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 8),
            
            Text(
              tr('emergency_contacts_desc'), 
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
              textAlign: TextAlign.center,
            ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 32),
            
            ...List.generate(_contacts.length, (index) {
              final contact = _contacts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              tr('emergency_contacts_title'),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                        if (_contacts.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () => _removeContact(index),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      initialValue: contact.name,
                      label: tr('contact_name'),
                      icon: Icons.person_outline_rounded,
                      onChanged: (value) => _updateContact(index, contact.copyWith(name: value)),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      initialValue: contact.phone,
                      label: tr('phone_label'),
                      icon: Icons.phone_iphone_rounded,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      onChanged: (value) => _updateContact(index, contact.copyWith(phone: value)),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      initialValue: contact.relationship,
                      label: tr('contact_relation'),
                      icon: Icons.family_restroom_rounded,
                      onChanged: (value) => _updateContact(index, contact.copyWith(relationship: value)),
                    ),
                  ],
                ),
              ).animate().fade(delay: (300 + (index * 100)).ms).slideX(begin: 0.1, end: 0);
            }),
            
            if (_contacts.length < 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: OutlinedButton.icon(
                  onPressed: _addContact,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: Text(tr('add_contact_btn') != 'add_contact_btn' ? tr('add_contact_btn') : 'إضافة جهة اتصال أخرى', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD700),
                    side: BorderSide(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ).animate().fade(delay: 500.ms),
              ),
              
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  activeColor: const Color(0xFFFFD700),
                  checkColor: Colors.black,
                  side: BorderSide(color: Colors.grey.shade600),
                  onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
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
                          style: TextStyle(color: Colors.grey.shade300),
                          children: [
                            TextSpan(
                              text: tr('terms_and_conditions') != 'terms_and_conditions' ? tr('terms_and_conditions') : 'الشروط والأحكام وسياسة الخصوصية',
                              style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fade(delay: 600.ms),
            
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: () {
                if (!_acceptedTerms) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        tr('must_accept_terms') != 'must_accept_terms' ? tr('must_accept_terms') : 'يجب الموافقة على الشروط والأحكام للمتابعة',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: const Color(0xFFFFD700),
                    ),
                  );
                  return;
                }
                widget.onNext();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700), // Gold
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.5),
              ),
              child: Text(tr('finish_registration_btn'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ).animate().fade(delay: 700.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String initialValue,
    required String label,
    required IconData icon,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    TextDirection? textDirection,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      textDirection: textDirection,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(icon, color: const Color(0xFFFFD700)),
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
      onChanged: onChanged,
    );
  }
}
