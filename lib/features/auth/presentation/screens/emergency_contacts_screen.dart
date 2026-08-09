import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/translation_service.dart';
import '../../../../models/auth_models.dart';
import '../../../../widgets/glass_container.dart';
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
