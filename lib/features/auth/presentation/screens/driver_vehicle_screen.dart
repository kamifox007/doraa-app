import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
            ],
          ),
          const SizedBox(height: 16),
          Text(tr('vehicle_data_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(tr('vehicle_data_desc'), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: brand,
                  decoration: InputDecoration(labelText: tr('vehicle_brand')),
                  onChanged: onBrandChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: model,
                  decoration: InputDecoration(labelText: tr('vehicle_model')),
                  onChanged: onModelChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: year,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: tr('vehicle_year')),
                  onChanged: onYearChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: color,
                  decoration: InputDecoration(labelText: tr('vehicle_color')),
                  onChanged: onColorChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: plate,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: tr('vehicle_plate'),
              prefixIcon: const Icon(Icons.pin),
            ),
            onChanged: onPlateChanged,
          ),
          const SizedBox(height: 48),
          ElevatedButton(onPressed: onNext, child: Text(tr('next_docs_btn'))),
        ],
      ),
    );
  }
}
