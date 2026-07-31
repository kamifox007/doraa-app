import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Assuming userProvider exists somewhere in your app. 
// If not, you will need to import it properly.
// import '../../providers/user_provider.dart'; 

class PersonalizedGreeting extends ConsumerWidget {
  final String userName; // Changed to accept name or fetch from provider if available
  const PersonalizedGreeting({super.key, this.userName = 'مستخدم'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If you have a userProvider, you can use:
    // final userName = ref.watch(userProvider.select((u) => u.name));
    
    final hour = DateTime.now().hour;

    String greeting;
    if (hour < 12) {
      greeting = 'صباح الخير';
    } else if (hour < 17) {
      greeting = 'مساء الخير';
    } else {
      greeting = 'مساء النور';
    }

    return Text(
      '$greeting $userName! 👋',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: const Color(0xFF00897B),
      ),
    );
  }
}
