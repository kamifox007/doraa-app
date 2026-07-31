import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class DriverRegistrationScreen extends ConsumerStatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  ConsumerState<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends ConsumerState<DriverRegistrationScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Car Details
  String _carBrand = '';
  String _carModel = '';
  String _carYear = '';
  String _carColor = '';
  String _carPlate = '';

  Future<void> _submitApplication() async {
    final tr = ref.read(translationProvider).tr;
    if (_carBrand.isEmpty || _carModel.isEmpty || _carPlate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('please_fill_car_details'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // 1. Save vehicle info
        await Supabase.instance.client.from('driver_profiles').upsert({
          'user_id': user.id,
          'vehicle_make': _carBrand,
          'vehicle_model': _carModel,
          'vehicle_year': int.tryParse(_carYear) ?? 2020,
          'vehicle_color': _carColor,
          'license_plate': _carPlate,
          'verification_status': 'pending', // Pending Admin Approval
        });

        // 2. Change role in user_profiles to pending_driver
        await Supabase.instance.client.from('user_profiles').update({
          'role': 'pending_driver'
        }).eq('user_id', user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('application_received_success'))),
          );
          Navigator.pop(context, true); // Return true to indicate success
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

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider).tr;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('join_as_captain_title')),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            setState(() => _currentStep++);
          } else {
            _submitApplication();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_currentStep == 1 ? tr('submit_application_btn') : tr('next_btn')),
                  ),
                ),
                const SizedBox(width: 12),
                if (_currentStep == 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: Text(tr('cancel_btn')),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: Text(tr('previous_btn')),
                    ),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            isActive: _currentStep >= 0,
            title: Text(tr('car_details_step')),
            content: Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(labelText: tr('car_brand_hint')),
                        onChanged: (val) => _carBrand = val,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(labelText: tr('car_model_hint')),
                        onChanged: (val) => _carModel = val,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: tr('car_year_hint')),
                        onChanged: (val) => _carYear = val,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(labelText: tr('car_color_hint')),
                        onChanged: (val) => _carColor = val,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: tr('car_plate_hint'),
                    prefixIcon: const Icon(Icons.pin),
                  ),
                  onChanged: (val) => _carPlate = val,
                ),
              ],
            ),
          ),
          Step(
            isActive: _currentStep >= 1,
            title: Text(tr('upload_documents_step')),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('documents_upload_note'),
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {}, // In a real app, opens image picker
                  icon: const Icon(Icons.camera_alt),
                  label: Text(tr('driving_license_image')),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {}, 
                  icon: const Icon(Icons.credit_card),
                  label: Text(tr('carte_grise_image')),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
