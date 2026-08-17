import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../providers/auth_providers.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key, required this.onRoleSelected});
  final VoidCallback onRoleSelected;

  void _handleSelection(BuildContext context, WidgetRef ref, String role) {
    ref.read(registrationProvider.notifier).updateRole(role);
    onRoleSelected();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(registrationProvider).fullName;
    final displayName = name.isNotEmpty ? name.split(' ').first : 'عزيزتي';

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark premium background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),
              Text(
                'أهلاً بكِ $displayName 👋',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFFFFD700), // Gold
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.right,
              ).animate().fade(duration: 500.ms).slideX(begin: 0.2, end: 0),
              const SizedBox(height: 12),
              Text(
                'كيف يمكن لـ DZdora مساعدتكِ اليوم؟',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.right,
              ).animate().fade(delay: 200.ms).slideX(begin: 0.2, end: 0),
              const Spacer(flex: 2),

              // زر الراكبة
              _buildRoleCard(
                context: context,
                title: 'أحتاج توصيل 🚗',
                subtitle: 'تنقلي بأمان وراحة تامة مع سائقات موثوقات من DZdora',
                icon: Icons.directions_car_filled_rounded,
                color: const Color(0xFFFFD700), // Gold
                onTap: () => _handleSelection(context, ref, 'rider'),
              ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 24),

              // زر السائقة
              _buildRoleCard(
                context: context,
                title: 'أنضم كسائقة 👩‍✈️',
                subtitle: 'انضمي لفريقنا وحققي أرباحاً مرنة في بيئة آمنة وخاصة بالنساء',
                icon: Icons.work_outline_rounded,
                color: const Color(0xFFE5C100), // Slightly darker gold for contrast
                onTap: () => _handleSelection(context, ref, 'driver'),
              ).animate().fade(delay: 600.ms).slideY(begin: 0.2, end: 0),
              
              const Spacer(flex: 3),
              
              // زر للذهاب لشاشة تسجيل الدخول إذا كان لديها حساب
              Center(
                child: TextButton(
                  onPressed: () {
                    // سيتم التعامل معها لاحقاً أو عبر التوجيه الأساسي
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'لديكِ حساب بالفعل؟ ',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                      children: const [
                        TextSpan(
                          text: 'تسجيل الدخول',
                          style: TextStyle(
                            color: Color(0xFFFFD700), // Gold
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fade(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Darker card background
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1), // Subtle gold glow
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2), // Gold border
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // White text on dark card
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
