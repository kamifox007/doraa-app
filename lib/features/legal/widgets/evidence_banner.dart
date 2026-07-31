import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/translation_service.dart';

class EvidenceBanner extends ConsumerWidget {
  const EvidenceBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider).tr;
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tr('ride_protected_evidence'),
              style: TextStyle(fontSize: 12, color: Colors.blue[800]),
            ),
          ),
        ],
      ),
    );
  }
}
