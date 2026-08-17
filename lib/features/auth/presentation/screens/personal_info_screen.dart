import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/translation_service.dart';
import '../../../../services/validation_service.dart';

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
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark premium background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: onBack, 
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFFD700)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
            const SizedBox(height: 16),
            Text(
              tr('personal_info_title'), 
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fade().slideX(begin: 0.2, end: 0),
            
            const SizedBox(height: 8),
            
            Text(
              tr('personal_info_desc'), 
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            ).animate().fade(delay: 100.ms).slideX(begin: 0.2, end: 0),
            
            const SizedBox(height: 32),
            
            TextFormField(
              initialValue: fullName,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: tr('full_name_label'),
                labelStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFFFD700)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                ),
              ),
              onChanged: onNameChanged,
            ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: tr('wilaya_label'),
                labelStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.map_outlined, color: Color(0xFFFFD700)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                ),
              ),
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFFD700)),
              initialValue: wilayas.contains(wilaya) ? wilaya : null,
              items: wilayas.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
              onChanged: (value) => onWilayaChanged(value ?? ''),
            ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 32),
            
            Text(
              tr('role_question'), 
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fade(delay: 400.ms),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onRoleChanged('rider'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: role == 'rider' ? const Color(0xFFFFD700).withValues(alpha: 0.15) : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: role == 'rider' ? const Color(0xFFFFD700) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.directions_walk, 
                            size: 48, 
                            color: role == 'rider' ? const Color(0xFFFFD700) : Colors.grey.shade600
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr('role_rider'), 
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: role == 'rider' ? const Color(0xFFFFD700) : Colors.grey.shade600
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fade(delay: 500.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: GestureDetector(
                    onTap: () => onRoleChanged('driver'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: role == 'driver' ? const Color(0xFFFFD700).withValues(alpha: 0.15) : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: role == 'driver' ? const Color(0xFFFFD700) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.directions_car, 
                            size: 48, 
                            color: role == 'driver' ? const Color(0xFFFFD700) : Colors.grey.shade600
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr('role_driver'), 
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: role == 'driver' ? const Color(0xFFFFD700) : Colors.grey.shade600
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fade(delay: 600.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
            
            const SizedBox(height: 48),
            
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700), // Gold
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.5),
              ),
              child: Text(tr('next_btn'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ).animate().fade(delay: 700.ms).slideY(begin: 0.2, end: 0),
          ],
      ),
    );
  }
}
