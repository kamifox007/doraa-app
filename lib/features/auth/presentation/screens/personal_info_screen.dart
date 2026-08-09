import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/translation_service.dart';
import '../../../../services/validation_service.dart';
import '../../../../widgets/glass_container.dart';

class PersonalInfoScreen extends ConsumerWidget {
  const PersonalInfoScreen({
    super.key,
    required this.fullName,
    required this.wilaya,
    required this.role,
    required this.onNameChanged,
    required this.onWilayaChanged,
    required this.onRoleChanged,
    required this.onNext,
    required this.onBack,
  });

  final String fullName;
  final String wilaya;
  final String role;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onWilayaChanged;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider).tr;
    final wilayas = ValidationService.getAlgerianWilayas();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
          Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
            ],
          ),
          const SizedBox(height: 48),
          Text(tr('personal_info_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(tr('personal_info_desc'), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          TextFormField(
            initialValue: fullName,
            decoration: InputDecoration(
              labelText: tr('full_name_label'),
              prefixIcon: const Icon(Icons.person_outline),
            ),
            onChanged: onNameChanged,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: tr('wilaya_label'),
              prefixIcon: const Icon(Icons.map_outlined),
            ),
            initialValue: wilayas.contains(wilaya) ? wilaya : null,
            items: wilayas.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: (value) => onWilayaChanged(value ?? ''),
          ),
          const SizedBox(height: 32),
          Text(tr('role_question'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onRoleChanged('rider'),
                  child: GlassContainer(
                    opacity: role == 'rider' ? 0.8 : 0.2,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.directions_walk, size: 48, color: role == 'rider' ? Theme.of(context).colorScheme.primary : Colors.grey),
                        const SizedBox(height: 8),
                        Text(tr('role_rider'), style: TextStyle(fontWeight: FontWeight.bold, color: role == 'rider' ? Theme.of(context).colorScheme.primary : Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => onRoleChanged('driver'),
                  child: GlassContainer(
                    opacity: role == 'driver' ? 0.8 : 0.2,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.directions_car, size: 48, color: role == 'driver' ? Theme.of(context).colorScheme.primary : Colors.grey),
                        const SizedBox(height: 8),
                        Text(tr('role_driver'), style: TextStyle(fontWeight: FontWeight.bold, color: role == 'driver' ? Theme.of(context).colorScheme.primary : Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          ElevatedButton(onPressed: onNext, child: Text(tr('next_btn'))),
        ],
    );
  }
}
