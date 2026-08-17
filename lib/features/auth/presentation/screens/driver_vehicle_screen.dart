import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/translation_service.dart';

class DriverVehicleScreen extends ConsumerWidget {
  const DriverVehicleScreen({
    super.key,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.plate,
    required this.onBrandChanged,
    required this.onModelChanged,
    required this.onYearChanged,
    required this.onColorChanged,
    required this.onPlateChanged,
    required this.onNext,
    required this.onBack,
  });

  final String brand;
  final String model;
  final String year;
  final String color;
  final String plate;
  final ValueChanged<String> onBrandChanged;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onYearChanged;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String> onPlateChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider).tr;
    
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
                child: const Icon(Icons.directions_car_rounded, size: 60, color: Color(0xFFFFD700)),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fade(),
            
            const SizedBox(height: 32),
            
            Text(
              tr('vehicle_data_title'), 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 8),
            
            Text(
              tr('vehicle_data_desc'), 
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
              textAlign: TextAlign.center,
            ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    initialValue: brand,
                    label: tr('vehicle_brand'),
                    onChanged: onBrandChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    initialValue: model,
                    label: tr('vehicle_model'),
                    onChanged: onModelChanged,
                  ),
                ),
              ],
            ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    initialValue: year,
                    label: tr('vehicle_year'),
                    keyboardType: TextInputType.number,
                    onChanged: onYearChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    initialValue: color,
                    label: tr('vehicle_color'),
                    onChanged: onColorChanged,
                  ),
                ),
              ],
            ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              initialValue: plate,
              label: tr('vehicle_plate'),
              prefixIcon: Icons.pin_rounded,
              textDirection: TextDirection.ltr,
              onChanged: onPlateChanged,
            ).animate().fade(delay: 500.ms).slideY(begin: 0.2, end: 0),
            
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
              child: Text(tr('next_docs_btn'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ).animate().fade(delay: 600.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String initialValue,
    required String label,
    required ValueChanged<String> onChanged,
    IconData? prefixIcon,
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
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFFFFD700)) : null,
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
      onChanged: onChanged,
    );
  }
}
