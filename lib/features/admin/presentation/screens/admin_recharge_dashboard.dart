import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/wallet_service.dart';
import '../../../../providers/auth_providers.dart';

class AdminRechargeDashboard extends ConsumerStatefulWidget {
  const AdminRechargeDashboard({super.key});

  @override
  ConsumerState<AdminRechargeDashboard> createState() => _AdminRechargeDashboardState();
}

class _AdminRechargeDashboardState extends ConsumerState<AdminRechargeDashboard> {
  bool _isRecharging = false;
  final TextEditingController _agentIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _agentIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleTopup() async {
    final agentId = _agentIdController.text.trim();
    final amountStr = _amountController.text.trim();
    final adminId = ref.read(authProvider).userId;

    if (agentId.isEmpty || amountStr.isEmpty || adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
      );
      return;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مبلغ الشحن غير صحيح')),
      );
      return;
    }

    setState(() => _isRecharging = true);

    final result = await WalletService.adminTopupAgent(
      adminId: adminId,
      agentId: agentId,
      amount: amount,
    );

    if (mounted) {
      setState(() => _isRecharging = false);
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم شحن رصيد الوكيل بنجاح!'), backgroundColor: Colors.green),
        );
        _agentIdController.clear();
        _amountController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الشحن: ${result['message']}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة (Admin) - شحن الوكلاء'),
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF673AB7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF673AB7).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Color(0xFF673AB7), size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'نظام الشحن الثلاثي (Tier 1)\nهذه الشاشة مخصصة فقط للمشرفين لضخ الرصيد للوكلاء.',
                      style: TextStyle(color: Color(0xFF673AB7), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Text('شحن رصيد وكيل (Agent Float)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _agentIdController,
              decoration: const InputDecoration(
                labelText: 'معرف الوكيل (Agent ID)',
                prefixIcon: Icon(Icons.support_agent, color: Color(0xFF673AB7)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'المبلغ (د.ج)',
                prefixIcon: Icon(Icons.attach_money, color: Color(0xFF673AB7)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRecharging ? null : _handleTopup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isRecharging
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ضخ الرصيد للوكيل', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
