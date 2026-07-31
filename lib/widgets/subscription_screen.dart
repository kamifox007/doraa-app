import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_providers.dart';
import '../services/ride_service.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  final _client = Supabase.instance.client;

  bool _isLoading = true;
  bool _isFreeTrial = false;
  bool _isActive = false;

  int _daysLeft = 0;
  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionInfo();
  }

  Future<void> _loadSubscriptionInfo() async {
    setState(() => _isLoading = true);
    final userId = ref.read(authProvider).userId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final profile = await _client
          .from('user_profiles')
          .select('created_at, subscription_expiry, wallet_balance')
          .eq('user_id', userId)
          .maybeSingle();

      if (profile != null && mounted) {
        final regDate = profile['created_at'] != null
            ? DateTime.parse(profile['created_at'])
            : DateTime.now();
        final expiry = profile['subscription_expiry'] != null
            ? DateTime.parse(profile['subscription_expiry'])
            : null;
        final balance = (profile['wallet_balance'] ?? 0).toDouble();

        final freeTrial = RideService.isInFreeTrial(regDate);
        final active = RideService.isSubscriptionActive(
          subscriptionExpiry: expiry,
          registrationDate: regDate,
        );

        int daysLeft = 0;
        if (freeTrial) {
          daysLeft = 30 - DateTime.now().difference(regDate).inDays;
        } else if (expiry != null && expiry.isAfter(DateTime.now())) {
          daysLeft = expiry.difference(DateTime.now()).inDays;
        }

        setState(() {

          _isFreeTrial = freeTrial;
          _isActive = active;
          _daysLeft = daysLeft.clamp(0, 365);
          _walletBalance = balance;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isFreeTrial = true;
          _isActive = true;
          _daysLeft = 30;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _isFreeTrial = true;
        _isActive = true;
        _daysLeft = 30;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestRenewal() async {
    final tr = ref.read(translationProvider).tr;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('renew_monthly_subscription_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('renew_instruction_1')),
            const SizedBox(height: 12),
            Text(tr('renew_instruction_2')),
            Text(tr('renew_instruction_3')),
            const SizedBox(height: 8),
            const SelectableText(
              '0799 000 000',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00897B),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(tr('renew_instruction_4')),
            const SizedBox(height: 12),
            Text(
              tr('renew_note'),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('close_btn')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider).tr;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0FF),
      appBar: AppBar(
        title: Text(tr('wallet_and_subscription'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE91E63), Color(0xFF880E4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 20),
                    _buildCommissionCard(),
                    const SizedBox(height: 20),
                    _buildWalletCard(),
                    const SizedBox(height: 20),
                    if (!_isActive || _daysLeft <= 7) _buildRenewButton(),
                    const SizedBox(height: 24),
                    _buildPlansSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final tr = ref.watch(translationProvider).tr;
    Color cardColor;
    String statusText;
    String iconText;

    if (_isFreeTrial) {
      cardColor = const Color(0xFF1565C0);
      statusText = tr('free_trial_month');
      iconText = '🎉';
    } else if (_isActive) {
      cardColor = const Color(0xFF2E7D32);
      statusText = tr('subscription_active');
      iconText = '✅';
    } else {
      cardColor = const Color(0xFFC62828);
      statusText = tr('subscription_expired');
      iconText = '⛔';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withValues(alpha: 0.7)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(iconText, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_daysLeft > 0)
            Text(
              '${tr('days_remaining')} $_daysLeft ${tr('days')}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
              ),
            ),
          if (_isFreeTrial)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                tr('free_trial_note'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ),
          // شريط التقدم
          if (_daysLeft > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _isFreeTrial ? (_daysLeft / 30).clamp(0.0, 1.0) : (_daysLeft / 30).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommissionCard() {
    final tr = ref.watch(translationProvider).tr;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.percent, color: Color(0xFF00897B)),
              const SizedBox(width: 8),
              Text(tr('commission_system'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(tr('minimum_fare'), '200 دج'),
          _infoRow(tr('dora_commission_per_ride'), '10%'),
          _infoRow(tr('net_income_per_ride'), '90%'),
          const Divider(),
          _infoRow(tr('example_ride'), ''),
          _infoRow(tr('dora_commission_example'), '50 دج'),
          _infoRow(tr('net_income_example'), '450 دج', green: true),
          const Divider(),
          Text(
            tr('fare_calculation_note'),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    final tr = ref.watch(translationProvider).tr;
    final isPositive = _walletBalance >= 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF1A237E), const Color(0xFF3949AB)]
              : [const Color(0xFFB71C1C), const Color(0xFFD32F2F)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? const Color(0xFF1A237E) : const Color(0xFFB71C1C)).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 22),
              const SizedBox(width: 8),
              Text(tr('digital_wallet'), style: const TextStyle(color: Colors.white70, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('DORA Pay', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${_walletBalance >= 0 ? '+' : ''}${_walletBalance.toStringAsFixed(0)} دج',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            isPositive ? tr('balance_available') : tr('balance_negative'),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showAddBalanceDialog,
            icon: const Icon(Icons.add_card_rounded),
            label: Text(tr('charge_wallet_baridimob'), style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A237E),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRenewButton() {
    final tr = ref.watch(translationProvider).tr;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _requestRenewal,
        icon: const Icon(Icons.refresh_rounded, size: 22),
        label: Text(tr('renew_subscription_btn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 58),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildPlansSection() {
    final tr = ref.watch(translationProvider).tr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('subscription_plans_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _planCard(
          title: tr('free_trial_plan_title'),
          price: tr('free_price'),
          color: const Color(0xFF1565C0),
          features: [tr('free_for_new_driver'), tr('thirty_days_full'), tr('all_app_features'), tr('commission_10_percent')],
          isFree: true,
        ),
        const SizedBox(height: 12),
        _planCard(
          title: tr('monthly_subscription_plan_title'),
          price: tr('three_thousand_dzd_month'),
          color: const Color(0xFF00897B),
          features: [
            tr('priority_appearance'),
            tr('dedicated_tech_support'),
            tr('monthly_earnings_reports'),
            tr('commission_10_percent'),
          ],
          isFree: false,
        ),
      ],
    );
  }

  Widget _planCard({
    required String title,
    required String price,
    required Color color,
    required List<String> features,
    required bool isFree,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: color, size: 16),
                const SizedBox(width: 8),
                Text(f, style: const TextStyle(fontSize: 13)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool green = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: green ? Colors.green.shade700 : null,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBalanceDialog() {
    final tr = ref.read(translationProvider).tr;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('charge_wallet_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('charge_instruction_1')),
            const SizedBox(height: 10),
            Text(tr('charge_instruction_2')),
            const SizedBox(height: 6),
            const SelectableText(
              '0799 000 000',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00897B),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(tr('charge_instruction_3')),
            const SizedBox(height: 8),
            Text(tr('charge_note'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('ok_btn'))),
        ],
      ),
    );
  }
}
