import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_providers.dart';
import '../services/ride_service.dart';
import 'glass_container.dart';

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
  double _referralCredit = 0.0;
  int _ridesCoveredByCredit = 0;
  String? _userRole; // لمعرفة إذا كانت سائقة أم لا
  bool _hasPendingDriverCredit = false; // رصيد مجمد بانتظار التسجيل كسائقة
  List<Map<String, dynamic>> _transactions = [];

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

      final txRes = await _client
          .from('wallet_transactions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);

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

        // تحميل ملخص المحفظة الذكي من دالة get_wallet_summary
        double referralCredit = 0;
        int ridesCovered = 0;
        try {
          final walletSummary = await _client.rpc(
            'get_wallet_summary',
            params: {'p_user_id': userId},
          );
          if (walletSummary != null) {
            referralCredit = (walletSummary['referral_credit'] as num?)?.toDouble() ?? 0;
            ridesCovered   = (walletSummary['rides_covered_by_credit'] as num?)?.toInt() ?? 0;
          }
        } catch (_) {}

        // تحميل دور المستخدمة وفحص الرصيد المجمّد
        String? userRole;
        bool hasPendingCredit = false;
        try {
          final roleRes = await _client
              .from('user_profiles')
              .select('role')
              .eq('user_id', userId!)
              .maybeSingle();
          userRole = roleRes?['role'] as String?;

          // فحص هل يوجد رصيد إحالة مجمّد من شخص دعاها قبل تسجيلها كسائقة
          final pendingCredit = await _client
              .from('referrals')
              .select('reward_amount')
              .eq('referred_id', userId)
              .eq('referral_type', 'driver')
              .eq('reward_paid', false)
              .maybeSingle();
          hasPendingCredit = pendingCredit != null;
        } catch (_) {}

        setState(() {
          _isFreeTrial          = freeTrial;
          _isActive             = active;
          _daysLeft             = daysLeft.clamp(0, 365);
          _walletBalance        = balance;
          _referralCredit       = referralCredit;
          _ridesCoveredByCredit = ridesCovered;
          _userRole             = userRole;
          _hasPendingDriverCredit = hasPendingCredit;
          _transactions         = List<Map<String, dynamic>>.from(txRes);
          _isLoading            = false;
        });
      } else {
        setState(() {
          _isFreeTrial = true;
          _isActive    = true;
          _daysLeft    = 30;
          _isLoading   = false;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('renew_monthly_subscription_title'), style: const TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('renew_instruction_1')),
            const SizedBox(height: 12),
            Text(tr('renew_instruction_2')),
            Text(tr('renew_instruction_3')),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.green),
                  SizedBox(width: 12),
                  SelectableText('0799 000 000', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 3)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(tr('renew_instruction_4')),
            const SizedBox(height: 12),
            Text(tr('renew_note'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('close_btn'), style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx), 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('تم الدفع', style: TextStyle(color: Colors.white)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('charge_wallet_title'), style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('charge_instruction_1')),
            const SizedBox(height: 10),
            Text(tr('charge_instruction_2')),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.credit_card, color: Color(0xFF1A237E)),
                  SizedBox(width: 12),
                  SelectableText('0799 000 000', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E), letterSpacing: 3)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(tr('charge_instruction_3')),
            const SizedBox(height: 8),
            Text(tr('charge_note'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('close_btn'), style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx), 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('تم الدفع', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider).tr;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(tr('wallet_and_subscription'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFF311B92)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // بانر الرصيد المجمّد لتحفيز غير السائقات
                        if (_hasPendingDriverCredit || (_userRole != 'driver' && _userRole != 'pending_driver'))
                          _buildLockedCreditBanner(),
                        if (_hasPendingDriverCredit || (_userRole != 'driver' && _userRole != 'pending_driver'))
                          const SizedBox(height: 16),
                        _buildWalletCard(),
                        const SizedBox(height: 20),
                        _buildStatusCard(),
                        const SizedBox(height: 20),
                        if (!_isActive || _daysLeft <= 7) _buildRenewButton(),
                        if (!_isActive || _daysLeft <= 7) const SizedBox(height: 24),
                        _buildTransactionsSection(tr),
                        const SizedBox(height: 24),
                        _buildCommissionCard(),
                        const SizedBox(height: 24),
                        _buildPlansSection(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    final tr = ref.watch(translationProvider).tr;
    final isPositive = _walletBalance >= 0;
    
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      blur: 20,
      opacity: 0.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(tr('digital_wallet'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('DORA Pay', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '${_walletBalance >= 0 ? '+' : ''}${_walletBalance.toStringAsFixed(0)} دج',
            style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            isPositive ? tr('balance_available') : tr('balance_negative'),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),

          // ── رصيد مكافأة الإحالة الذكي ──
          if (_referralCredit > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.savings_rounded, color: Colors.greenAccent, size: 20),
                      const SizedBox(width: 8),
                      const Text('رصيد مكافأة الإحالة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      const Spacer(),
                      Text('${_referralCredit.toStringAsFixed(0)} دج', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('✅ هذا الرصيد يُستخدم تلقائياً لدفع عمولة 10% من رحلاتك بدلاً من أرباحك', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  if (_ridesCoveredByCredit > 0) ...[
                    const SizedBox(height: 6),
                    Text('🚗 عدد الرحلات التي غطى فيها الرصيد العمولة: $_ridesCoveredByCredit رحلة', style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddBalanceDialog,
            icon: const Icon(Icons.add_card_rounded),
            label: Text(tr('charge_wallet_baridimob'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF311B92),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final tr = ref.watch(translationProvider).tr;
    String statusText;
    String iconText;
    Color statusColor;

    if (_isFreeTrial) {
      statusText = tr('free_trial_month');
      iconText = '🎉';
      statusColor = Colors.blue.shade200;
    } else if (_isActive) {
      statusText = tr('subscription_active');
      iconText = '✅';
      statusColor = Colors.green.shade300;
    } else {
      statusText = tr('subscription_expired');
      iconText = '⛔';
      statusColor = Colors.red.shade300;
    }

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(iconText, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_daysLeft > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${tr('days_remaining')} $_daysLeft ${tr('days')}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
          if (_isFreeTrial)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                tr('free_trial_note'),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
              ),
            ),
          if (_daysLeft > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_daysLeft / 30).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(String Function(String) tr) {
    if (_transactions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'سجل المعاملات (History)',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GlassContainer(
          borderRadius: 20,
          opacity: 0.1,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactions.length,
            separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            itemBuilder: (context, index) {
              final tx = _transactions[index];
              final amount = (tx['amount'] ?? 0).toDouble();
              final isPositive = amount > 0;
              final type = tx['type'] as String?;
              final dateStr = tx['created_at'] as String?;
              final desc = tx['description'] as String? ?? '';
              
              String dateFormatted = '';
              if (dateStr != null) {
                try {
                  final dt = DateTime.parse(dateStr).toLocal();
                  dateFormatted = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                } catch(e) {
                  dateFormatted = dateStr;
                }
              }

              IconData icon;
              Color iconColor;
              if (type == 'commission') {
                icon = Icons.percent_rounded;
                iconColor = Colors.orange.shade300;
              } else if (type == 'subscription') {
                icon = Icons.star_rounded;
                iconColor = Colors.purple.shade300;
              } else if (type == 'topup') {
                icon = Icons.account_balance_wallet_rounded;
                iconColor = Colors.green.shade300;
              } else {
                icon = Icons.swap_horiz_rounded;
                iconColor = Colors.white70;
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: iconColor.withValues(alpha: 0.2),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                title: Text(desc, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: Text(dateFormatted, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                trailing: Text(
                  '${isPositive ? '+' : ''}${amount.toStringAsFixed(0)} دج',
                  style: TextStyle(
                    color: isPositive ? Colors.green.shade300 : Colors.red.shade300,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommissionCard() {
    final tr = ref.watch(translationProvider).tr;
    final isFreeNow = _isFreeTrial || _isActive;
    final commissionRate = isFreeNow ? '0%' : '10%';
    final netRate = isFreeNow ? '100%' : '90%';
    final exampleCommission = isFreeNow ? '0 دج' : '50 دج';
    final exampleNet = isFreeNow ? '500 دج' : '450 دج';

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(tr('commission_system'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (isFreeNow) 
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: const Text('🎉 أنتِ الآن تتمتعين بإعفاء تام من العمولة (0%)!', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          _infoRow(tr('minimum_fare'), '200 دج'),
          _infoRow(tr('dora_commission_per_ride'), commissionRate, green: isFreeNow),
          _infoRow(tr('net_income_per_ride'), netRate, green: true),
          Divider(color: Colors.white.withValues(alpha: 0.2)),
          _infoRow(tr('example_ride'), '500 دج'),
          _infoRow(tr('dora_commission_example'), exampleCommission, green: isFreeNow),
          _infoRow(tr('net_income_example'), exampleNet, green: true),
          const SizedBox(height: 12),
          Text(
            tr('fare_calculation_note'),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool green = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: green ? Colors.green.shade300 : Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRenewButton() {
    final tr = ref.watch(translationProvider).tr;
    return ElevatedButton.icon(
      onPressed: _requestRenewal,
      icon: const Icon(Icons.workspace_premium_rounded, size: 24),
      label: Text(tr('renew_subscription_btn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pinkAccent.shade400,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 10,
        shadowColor: Colors.pinkAccent.shade400.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildPlansSection() {
    final tr = ref.watch(translationProvider).tr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('subscription_plans_title'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _planCard(
          title: tr('free_trial_plan_title'),
          price: tr('free_price'),
          color: Colors.blue.shade300,
          features: [tr('free_for_new_driver'), tr('thirty_days_full'), tr('all_app_features'), tr('commission_10_percent')],
        ),
        const SizedBox(height: 16),
        _planCard(
          title: tr('monthly_subscription_plan_title'),
          price: tr('three_thousand_dzd_month'),
          color: Colors.tealAccent.shade400,
          features: [
            tr('priority_appearance'),
            tr('dedicated_tech_support'),
            tr('monthly_earnings_reports'),
            tr('commission_10_percent'),
          ],
        ),
      ],
    );
  }

  Widget _planCard({
    required String title,
    required String price,
    required Color color,
    required List<String> features,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Text(price, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(f, style: const TextStyle(color: Colors.white, fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ══ بانر الرصيد المجمّد: يجبر غير السائقة على التسجيل ══
  Widget _buildLockedCreditBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade700, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🎁', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1,000 دج بانتظارك!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      SizedBox(height: 3),
                      Text('هدية مقفلة باسمك بانتظار تفعيلها', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('مقفل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🔓 هذه الهدية مقفلة بانتظارك — سجّلي كسائقة لتفعيلها فوراً!',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // فتح شاشة تسجيل السائقة
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('سجّلي كسائقة من الملف الشخصي لتفعيل رصيدك الفوري!', style: TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 4),
                    ),
                  );
                },
                icon: const Icon(Icons.directions_car_rounded, color: Colors.amber),
                label: const Text('سجّلي كسائقة وافتحي رصيدك!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
