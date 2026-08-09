import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/translation_service.dart';
import '../../../../widgets/glass_container.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key, required this.onNext, required this.onBack});
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
          const Icon(Icons.document_scanner_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 32),
          Text(tr('verify_identity_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GlassContainer(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.credit_card, color: Colors.blue),
                  title: Text(tr('id_card_img')),
                  subtitle: Text(tr('upload_clear_img')),
                  trailing: const Icon(Icons.add_a_photo),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.car_crash, color: Colors.green),
                  title: Text(tr('driving_license')),
                  subtitle: Text(tr('drivers_only')),
                  trailing: const Icon(Icons.add_a_photo),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.face_retouching_natural, color: Colors.purple),
                  title: Text(tr('live_selfie')),
                  subtitle: Text(tr('verify_face_match')),
                  trailing: const Icon(Icons.camera_front),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: onNext, child: Text(tr('skip_demo_btn'))),
        ],
      ),
    );
  }
}
