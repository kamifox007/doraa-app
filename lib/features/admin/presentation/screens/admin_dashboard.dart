import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:doraa/services/translation_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;
  late TabController _tabController;

  // ── بيانات كل تبويب ──
  List<Map<String, dynamic>> _pendingDrivers = [];
  List<Map<String, dynamic>> _safetyReports = [];
  List<Map<String, dynamic>> _pendingDocuments = [];
  List<Map<String, dynamic>> _pendingVehicles = [];
  List<Map<String, dynamic>> _activeRides = [];
  List<Map<String, dynamic>> _fareSettings = [];
  List<Map<String, dynamic>> _promoCodes = [];
  List<Map<String, dynamic>> _lostItems = [];
  List<Map<String, dynamic>> _disputes = [];
  List<Map<String, dynamic>> _financialTransactions = [];
  List<Map<String, dynamic>> _ratings = [];

  bool _isLoadingDrivers = true;
  bool _isLoadingReports = true;
  bool _isLoadingDocs = true;
  bool _isLoadingVehicles = true;
  bool _isLoadingRides = true;
  bool _isLoadingFares = true;
  bool _isLoadingPromo = true;
  bool _isLoadingLost = true;
  bool _isLoadingDisputes = true;
  bool _isLoadingFinancials = true;
  bool _isLoadingRatings = true;

  double _totalTopups = 0;
  double _totalCommissions = 0;

  // Push Notification
  final _notifTitleCtrl = TextEditingController();
  final _notifBodyCtrl = TextEditingController();
  bool _isSendingNotif = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 11, vsync: this);
    _tabController.addListener(() {
      switch (_tabController.index) {
        case 0: _fetchPendingDrivers(); break;
        case 1: _fetchPendingDocuments(); break;
        case 2: _fetchPendingVehicles(); break;
        case 3: _fetchSafetyReports(); break;
        case 4: _fetchActiveRides(); break;
        case 5: _fetchFareSettings(); break;
        case 6: _fetchPromoCodes(); break;
        case 7: _fetchLostItems(); break;
        case 8: _fetchDisputes(); break;
        case 9: _fetchFinancials(); break;
        case 10: _fetchRatings(); break;
      }
    });
    _fetchPendingDrivers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notifTitleCtrl.dispose();
    _notifBodyCtrl.dispose();
    super.dispose();
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Data Fetchers
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Future<void> _fetchPendingDrivers() async {
    setState(() => _isLoadingDrivers = true);
    try {
      final r = await _client.from('user_profiles').select().eq('role', 'driver');
      if (mounted) setState(() { _pendingDrivers = List<Map<String, dynamic>>.from(r); _isLoadingDrivers = false; });
    } catch (_) { if (mounted) setState(() => _isLoadingDrivers = false); }
  }

  Future<void> _fetchPendingDocuments() async {
    setState(() => _isLoadingDocs = true);
    try {
      final r = await _client
          .from('documents')
          .select('*, user:user_id(full_name, phone)')
          .eq('status', 'pending')
          .order('uploaded_at', ascending: false);
      if (mounted) setState(() { _pendingDocuments = List<Map<String, dynamic>>.from(r); _isLoadingDocs = false; });
    } catch (_) { if (mounted) setState(() => _isLoadingDocs = false); }
  }

  Future<void> _fetchPendingVehicles() async {
    setState(() => _isLoadingVehicles = true);
    try {
      final r = await _client
          .from('driver_profiles')
          .select('*, user:user_id(full_name, phone)')
          .eq('vehicle_approval_status', 'pending');
      if (mounted) setState(() { _pendingVehicles = List<Map<String, dynamic>>.from(r); _isLoadingVehicles = false; });
    } catch (_) { if (mounted) setState(() => _isLoadingVehicles = false); }
  }

  Future<void> _fetchSafetyReports() async {
    setState(() => _isLoadingReports = true);
    try {
      final r = await _client
          .from('safety_reports')
          .select('*, reporter:reporter_id(full_name, phone), reported:reported_id(full_name)')
          .order('created_at', ascending: false);
      if (mounted) setState(() { _safetyReports = List<Map<String, dynamic>>.from(r); _isLoadingReports = false; });
    } catch (_) { if (mounted) setState(() => _isLoadingReports = false); }
  }

  Future<void> _fetchActiveRides() async {
    setState(() => _isLoadingRides = true);
    try {
      final r = await _client
          .from('rides')
          .select('*, rider:rider_id(full_name), driver:driver_id(full_name)')
          .inFilter('status', ['searching', 'accepted', 'arrived_pickup', 'started']);
      if (mounted) setState(() { _activeRides = List<Map<String, dynamic>>.from(r); _isLoadingRides = false; });
    } catch (_) { if (mounted) setState(() => _isLoadingRides = false); }
  }

  Future<void> _fetchFareSettings() async {
    setState(() => _isLoadingFares = true);
    try {
      final r = await _client.from('fare_settings').select().order('wilaya');
      if (mounted) setState(() { _fareSettings = List<Map<String, dynamic>>.from(r); _isLoadingFares = false; });
    } catch (_) { if (mounted) setState(() => _isLoadingFares = false); }
  }

  Future<void> _fetchPromoCodes() async {
    setState(() => _isLoadingPromo = true);
    try {
      final r = await _client.from('promo_codes').select().order('created_at', ascending: false);
      if (mounted) setState(() { _promoCodes = List<Map<String, dynamic>>.from(r); _isLoadingPromo = false; });
    } catch (_) { if (mounted) setState(() => _isLoadingPromo = false); }
  }

  Future<void> _fetchLostItems() async {
    setState(() => _isLoadingLost = true);
    try {
      final r = await _client.from('lost_items').select('*, ride:ride_id(pickup_address, dropoff_address)').order('created_at', ascending: false);
      if (mounted) setState(() { _lostItems = List<Map<String, dynamic>>.from(r); _isLoadingLost = false; });
    } catch (_) { if (mounted) setState(() => _isLoadingLost = false); }
  }

  Future<void> _fetchDisputes() async {
    setState(() => _isLoadingDisputes = true);
    try {
      final r = await _client.from('disputes').select('*, ride:ride_id(pickup_address, dropoff_address)').order('created_at', ascending: false);
      if (mounted) setState(() { _disputes = List<Map<String, dynamic>>.from(r); _isLoadingDisputes = false; });
    } catch (_) { if (mounted) setState(() => _isLoadingDisputes = false); }
  }

  Future<void> _fetchFinancials() async {
    setState(() => _isLoadingFinancials = true);
    try {
      final r = await _client.from('wallet_transactions').select('*, user:user_id(full_name, phone)').order('created_at', ascending: false).limit(100);
      double topups = 0;
      double commissions = 0;
      for (var txn in r) {
        if (txn['type'] == 'topup') topups += (txn['amount'] as num).toDouble();
        if (txn['type'] == 'commission') commissions += (txn['amount'] as num).toDouble().abs();
      }
      if (mounted) {
        setState(() {
          _financialTransactions = List<Map<String, dynamic>>.from(r);
          _totalTopups = topups;
          _totalCommissions = commissions;
          _isLoadingFinancials = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingFinancials = false);
    }
  }

  Future<void> _fetchRatings() async {
    setState(() => _isLoadingRatings = true);
    try {
      final r = await _client
          .from('ratings')
          .select('*, reviewer:reviewer_id(full_name), reviewee:reviewee_id(full_name)')
          .order('created_at', ascending: false)
          .limit(100);
      if (mounted) setState(() { _ratings = List<Map<String, dynamic>>.from(r); _isLoadingRatings = false; });
    } catch (_) { 
      if (mounted) setState(() => _isLoadingRatings = false); 
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Actions
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Future<void> _updateDocumentStatus(String docId, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    final tr = ref.read(translationProvider).tr;
    try {
      await _client.from('documents').update({'status': status, 'admin_notes': status == 'approved' ? tr('approved_success') : tr('rejected_success')}).eq('id', docId);
      messenger.showSnackBar(SnackBar(content: Text('${tr('document_updated')} $status')));
      _fetchPendingDocuments();
    } catch (e) { messenger.showSnackBar(SnackBar(content: Text('${tr('error_occurred_prefix')} $e'))); }
  }

  Future<void> _updateVehicleStatus(String userId, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    final tr = ref.read(translationProvider).tr;
    try {
      await _client.from('driver_profiles').update({'vehicle_approval_status': status}).eq('user_id', userId);
      messenger.showSnackBar(SnackBar(content: Text('${tr('vehicle_updated')} $status')));
      _fetchPendingVehicles();
    } catch (e) { messenger.showSnackBar(SnackBar(content: Text('${tr('error_occurred_prefix')} $e'))); }
  }

  Future<void> _updateReportStatus(String reportId, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    final tr = ref.read(translationProvider).tr;
    try {
      await _client.from('safety_reports').update({'status': status}).eq('id', reportId);
      messenger.showSnackBar(SnackBar(content: Text('${tr('complaint_updated')} $status')));
      _fetchSafetyReports();
    } catch (e) { messenger.showSnackBar(SnackBar(content: Text('${tr('error_occurred_prefix')} $e'))); }
  }

  Future<void> _updateDriverVerification(String userId, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    final tr = ref.read(translationProvider).tr;
    try {
      await _client.from('user_profiles').update({'verification_status': status}).eq('user_id', userId);
      messenger.showSnackBar(SnackBar(content: Text('${tr('verification_updated')} $status')));
      _fetchPendingDrivers();
    } catch (e) { messenger.showSnackBar(SnackBar(content: Text('${tr('error_occurred_prefix')} $e'))); }
  }

  Future<void> _updateFareSetting(String wilaya, Map<String, dynamic> data) async {
    final messenger = ScaffoldMessenger.of(context);
    final tr = ref.read(translationProvider).tr;
    try {
      await _client.from('fare_settings').update(data).eq('wilaya', wilaya);
      messenger.showSnackBar(SnackBar(content: Text(tr('fares_saved_success'))));
    } catch (e) { messenger.showSnackBar(SnackBar(content: Text('${tr('error_occurred_prefix')} $e'))); }
  }



  Future<void> _sendPushNotification() async {
    if (_notifTitleCtrl.text.isEmpty || _notifBodyCtrl.text.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final tr = ref.read(translationProvider).tr;
    setState(() => _isSendingNotif = true);
    try {
      await _client.from('notifications').insert({
        'user_id': null,
        'type': 'admin_broadcast',
        'title': _notifTitleCtrl.text.trim(),
        'body': _notifBodyCtrl.text.trim(),
        'data': {'sent_by': 'admin'},
      });
      _notifTitleCtrl.clear();
      _notifBodyCtrl.clear();
      messenger.showSnackBar(SnackBar(content: Text(tr('notification_sent_success'))));
    } catch (e) { messenger.showSnackBar(SnackBar(content: Text('${tr('error_occurred_prefix')} $e'))); }
    setState(() => _isSendingNotif = false);
  }

  void _showFareEditDialog(Map<String, dynamic> fare) {
    final tr = ref.read(translationProvider).tr;
    final baseFareCtrl = TextEditingController(text: fare['base_fare']?.toString() ?? '');
    final perKmCtrl = TextEditingController(text: fare['per_km_rate']?.toString() ?? '');
    final perMinCtrl = TextEditingController(text: fare['per_min_rate']?.toString() ?? '');
    final minFareCtrl = TextEditingController(text: fare['min_fare']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${tr('edit_fares_title')} ${fare['wilaya']}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: baseFareCtrl, decoration: InputDecoration(labelText: tr('base_fare_input')), keyboardType: TextInputType.number),
            TextField(controller: perKmCtrl, decoration: InputDecoration(labelText: tr('per_km_input')), keyboardType: TextInputType.number),
            TextField(controller: perMinCtrl, decoration: InputDecoration(labelText: tr('per_min_input')), keyboardType: TextInputType.number),
            TextField(controller: minFareCtrl, decoration: InputDecoration(labelText: tr('min_fare_input')), keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel_btn'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateFareSetting(fare['wilaya'], {
                'base_fare': double.tryParse(baseFareCtrl.text) ?? fare['base_fare'],
                'per_km_rate': double.tryParse(perKmCtrl.text) ?? fare['per_km_rate'],
                'per_min_rate': double.tryParse(perMinCtrl.text) ?? fare['per_min_rate'],
                'min_fare': double.tryParse(minFareCtrl.text) ?? fare['min_fare'],
              });
            },
            child: Text(tr('save_fares_btn')),
          ),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Build
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider).tr;
    return DefaultTabController(
      length: 11,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('admin_dashboard_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: () {
              if (_tabController.index == 0) _fetchPendingDrivers();
              if (_tabController.index == 1) _fetchPendingDocuments();
              if (_tabController.index == 2) _fetchPendingVehicles();
              if (_tabController.index == 3) _fetchSafetyReports();
              if (_tabController.index == 4) _fetchActiveRides();
              if (_tabController.index == 5) _fetchFareSettings();
              if (_tabController.index == 6) _fetchPromoCodes();
              if (_tabController.index == 7) _fetchLostItems();
              if (_tabController.index == 8) _fetchDisputes();
              if (_tabController.index == 9) _fetchFinancials();
            }),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            isScrollable: true,
            tabs: [
              Tab(icon: const Icon(Icons.drive_eta, size: 18), text: tr('drivers_tab')),
              Tab(icon: const Icon(Icons.badge, size: 18), text: tr('identity_tab')),
              Tab(icon: const Icon(Icons.directions_car, size: 18), text: tr('vehicles_tab')),
              Tab(icon: const Icon(Icons.report_problem, size: 18), text: tr('complaints_tab')),
              Tab(icon: const Icon(Icons.map, size: 18), text: tr('rides_tab')),
              Tab(icon: const Icon(Icons.attach_money, size: 18), text: tr('fares_tab')),
              Tab(icon: const Icon(Icons.local_offer, size: 18), text: tr('discounts_tab')),
              Tab(icon: const Icon(Icons.find_in_page, size: 18), text: tr('lost_items_tab')),
              Tab(icon: const Icon(Icons.gavel, size: 18), text: tr('disputes_tab')),
              Tab(icon: const Icon(Icons.account_balance_wallet, size: 18), text: 'الماليات'),
              Tab(icon: const Icon(Icons.star, size: 18), text: 'التقييمات'),
            ],
          ),
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDriversTab(),
              _buildDocumentsTab(),
              _buildVehiclesTab(),
              _buildReportsTab(),
              _buildLiveRidesTab(),
              _buildFareSettingsTab(),
              _buildPromoCodesTab(),
              _buildLostItemsTab(),
              _buildDisputesTab(),
              _buildFinancialsTab(),
              _buildRatingsTab(),
            ],
          ),
        ),
        // Ø²Ø± Ø§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª Ø§Ù„Ø¹Ø§Ù…Ø©
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showNotificationDialog,
          backgroundColor: const Color(0xFF00897B),
          icon: const Icon(Icons.notifications_active, color: Colors.white),
          label: Text(tr('broadcast_notification_btn'), style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Future<void> _grantGiftOrExemption(String userId, String type, dynamic value) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (type == 'topup') {
        await _client.rpc('topup_wallet', params: {'p_user_id': userId, 'p_amount': value});
        messenger.showSnackBar(const SnackBar(content: Text('ØªÙ… Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ø±ØµÙŠØ¯ Ø¨Ù†Ø¬Ø§Ø­!'), backgroundColor: Colors.green));
      } else if (type == 'exemption') {
        await _client.rpc('renew_subscription', params: {'p_user_id': userId, 'p_months': value});
        messenger.showSnackBar(const SnackBar(content: Text('ØªÙ… ØªÙ…Ø¯ÙŠØ¯ Ø§Ù„Ø§Ø´ØªØ±Ø§Ùƒ/Ø§Ù„Ø¥Ø¹ÙØ§Ø¡ Ø¨Ù†Ø¬Ø§Ø­!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Ø­Ø¯Ø« Ø®Ø·Ø£: $e'), backgroundColor: Colors.red));
    }
  }

  void _showGiftsAndExemptionsDialog(String userId, String userName) {
    final amountCtrl = TextEditingController();
    int selectedMonths = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('ðŸŽ Ø¥Ø¯Ø§Ø±Ø© Ø§Ù„Ù…ÙƒØ§ÙØ¢Øª: $userName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFE91E63))),
                    const SizedBox(height: 24),
                    
                    // Ø§Ù„Ù‚Ø³Ù… Ø§Ù„Ø£ÙˆÙ„: Ø´Ø­Ù† Ø§Ù„Ø±ØµÙŠØ¯
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance_wallet, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Ø¥Ù‡Ø¯Ø§Ø¡ Ø±ØµÙŠØ¯ Ù„Ù„Ù…Ø­ÙØ¸Ø©', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: amountCtrl,
                                  decoration: const InputDecoration(labelText: 'Ø§Ù„Ù…Ø¨Ù„Øº (Ø¯Ø¬)', border: OutlineInputBorder(), isDense: true),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  final amount = double.tryParse(amountCtrl.text);
                                  if (amount != null && amount > 0) {
                                    Navigator.pop(ctx);
                                    _grantGiftOrExemption(userId, 'topup', amount);
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('Ø¥Ø¶Ø§ÙØ©', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Ø§Ù„Ù‚Ø³Ù… Ø§Ù„Ø«Ø§Ù†ÙŠ: Ø§Ù„Ø¥Ø¹ÙØ§Ø¡ ÙˆØ§Ù„Ø§Ø´ØªØ±Ø§Ùƒ
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.purple.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.workspace_premium, color: Colors.purple),
                              SizedBox(width: 8),
                              Text('Ù…Ù†Ø­ Ø§Ø´ØªØ±Ø§Ùƒ Ù…Ø¬Ø§Ù†ÙŠ (Ø¥Ø¹ÙØ§Ø¡)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: selectedMonths,
                                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                                  items: const [
                                    DropdownMenuItem(value: 1, child: Text('Ø´Ù‡Ø± ÙˆØ§Ø­Ø¯ (1)')),
                                    DropdownMenuItem(value: 3, child: Text('3 Ø£Ø´Ù‡Ø±')),
                                    DropdownMenuItem(value: 6, child: Text('6 Ø£Ø´Ù‡Ø±')),
                                    DropdownMenuItem(value: 12, child: Text('Ø³Ù†Ø© ÙƒØ§Ù…Ù„Ø© (12)')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() => selectedMonths = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _grantGiftOrExemption(userId, 'exemption', selectedMonths);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                                child: const Text('Ù…Ù†Ø­', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // ── Tab: التقييمات
  // ════════════════════════════════════════════════════════════════════
  
  Widget _buildRatingsTab() {
    if (_isLoadingRatings) return const Center(child: CircularProgressIndicator());
    if (_ratings.isEmpty) return const Center(child: Text('لا توجد تقييمات حالياً'));

    return ListView.builder(
      itemCount: _ratings.length,
      itemBuilder: (ctx, i) {
        final r = _ratings[i];
        final reviewerName = r['reviewer']?['full_name'] ?? 'مجهول';
        final revieweeName = r['reviewee']?['full_name'] ?? 'مجهول';
        final score = r['score'] ?? 0;
        final comment = r['comment'] ?? 'لا يوجد تعليق';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFD700).withValues(alpha: 0.2),
              child: const Icon(Icons.star, color: Color(0xFFFFD700)),
            ),
            title: Text('$reviewerName  ➡️  $revieweeName', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) => Icon(
                    index < score ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFD700),
                    size: 16,
                  )),
                ),
                const SizedBox(height: 4),
                Text(comment),
              ],
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Tab: الماليات
  // ──────────────────────────────────────────────────────────────────
  Widget _buildFinancialsTab() {
    if (_isLoadingFinancials) {
      _fetchFinancials();
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.green, size: 32),
                      const SizedBox(height: 8),
                      const Text('Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ø§Ù„Ø´Ø­Ù† (Ø§Ù„ØªØ³Ø¨ÙŠÙ‚)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green), textAlign: TextAlign.center),
                      Text('${_totalTopups.toStringAsFixed(0)} Ø¯Ø¬', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.blue, size: 32),
                      const SizedBox(height: 8),
                      const Text('Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ø§Ù„Ø¹Ù…ÙˆÙ„Ø§Øª Ø§Ù„Ù…Ù‚ØªØ·Ø¹Ø©', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue), textAlign: TextAlign.center),
                      Text('${_totalCommissions.toStringAsFixed(0)} Ø¯Ø¬', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(alignment: Alignment.centerRight, child: Text('Ø¢Ø®Ø± Ø§Ù„Ø¹Ù…Ù„ÙŠØ§Øª Ø§Ù„Ù…Ø§Ù„ÙŠØ©', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        ),
        Expanded(
          child: _financialTransactions.isEmpty
              ? const Center(child: Text('Ù„Ø§ ØªÙˆØ¬Ø¯ Ø¹Ù…Ù„ÙŠØ§Øª Ù…Ø§Ù„ÙŠØ© Ø­Ø§Ù„ÙŠØ§Ù‹'))
              : ListView.builder(
                  itemCount: _financialTransactions.length,
                  itemBuilder: (ctx, i) {
                    final t = _financialTransactions[i];
                    final user = t['user'] ?? {};
                    final type = t['type'] ?? '';
                    final amount = (t['amount'] as num?)?.toDouble() ?? 0;
                    
                    IconData icon;
                    Color color;
                    String title;
                    
                    if (type == 'topup') {
                      icon = Icons.add_circle; color = Colors.green; title = 'Ø´Ø­Ù† Ù…Ø­ÙØ¸Ø©';
                    } else if (type == 'commission') {
                      icon = Icons.remove_circle; color = Colors.blue; title = 'Ø§Ù‚ØªØ·Ø§Ø¹ Ø¹Ù…ÙˆÙ„Ø©';
                    } else if (type == 'referral_bonus') {
                      icon = Icons.card_giftcard; color = Colors.purple; title = 'Ù…ÙƒØ§ÙØ£Ø© Ø¥Ø­Ø§Ù„Ø©';
                    } else {
                      icon = Icons.swap_horiz; color = Colors.grey; title = type;
                    }
                    
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), child: Icon(icon, color: color)),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${user['full_name'] ?? 'Ù…Ø¬Ù‡ÙˆÙ„'} â€¢ ${t['description'] ?? ''}'),
                      trailing: Text('${amount > 0 ? '+' : ''}${amount.toStringAsFixed(0)} Ø¯Ø¬', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Tab: Ø§Ù„Ø³Ø§Ø¦Ù‚Ø§Øª
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildDriversTab() {
    final tr = ref.watch(translationProvider).tr;
    if (_isLoadingDrivers) return const Center(child: CircularProgressIndicator());
    if (_pendingDrivers.isEmpty) return Center(child: Text(tr('no_drivers_registered')));
    return ListView.builder(
      itemCount: _pendingDrivers.length,
      itemBuilder: (context, index) {
        final d = _pendingDrivers[index];
        final status = d['verification_status'] ?? 'pending';
        Color statusColor = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(d['full_name'] ?? tr('no_name'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Chip(label: Text(status == 'pending' ? tr('pending_status') : status, style: const TextStyle(color: Colors.white, fontSize: 11)), backgroundColor: statusColor),
              ]),
              Text('ðŸ“ž ${d['phone'] ?? ''}', style: const TextStyle(color: Colors.grey)),
              Text('ðŸ“ ${d['wilaya'] ?? ''}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: () => _updateDriverVerification(d['user_id'], 'approved'),
                  icon: const Icon(Icons.check, color: Colors.green),
                  label: Text(tr('accept_btn'), style: const TextStyle(color: Colors.green)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green)),
                ),
                OutlinedButton.icon(
                  onPressed: () => _updateDriverVerification(d['user_id'], 'rejected'),
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: Text(tr('reject_btn'), style: const TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              ]),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showGiftsAndExemptionsDialog(d['user_id'], d['full_name'] ?? 'Ø§Ù„Ø³Ø§Ø¦Ù‚Ø©'),
                  icon: const Icon(Icons.card_giftcard, color: Colors.white),
                  label: const Text('Ù‡Ø¯Ø§ÙŠØ§ ÙˆØ¥Ø¹ÙØ§Ø¡Ø§Øª', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Tab: Ù‚Ø§Ø¦Ù…Ø© Ø§Ù†ØªØ¸Ø§Ø± Ø§Ù„Ù‡ÙˆÙŠØ© (CNI + Selfie)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildDocumentsTab() {
    final tr = ref.watch(translationProvider).tr;
    if (_isLoadingDocs) {
      _fetchPendingDocuments();
      return const Center(child: CircularProgressIndicator());
    }
    if (_pendingDocuments.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green, size: 64), const SizedBox(height: 16), Text(tr('no_pending_documents'), style: const TextStyle(fontSize: 16))]));

    return ListView.builder(
      itemCount: _pendingDocuments.length,
      itemBuilder: (ctx, i) {
        final doc = _pendingDocuments[i];
        final user = doc['user'] ?? {};
        final fileUrl = doc['file_url'] ?? '';
        final type = doc['type'] ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ListTile(
              title: Text(user['full_name'] ?? tr('unknown'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${user['phone'] ?? ''} â€” ${tr('document_type')} $type'),
              trailing: Chip(label: Text(tr('pending_status'), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.orange),
            ),
            if (fileUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    fileUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      color: Colors.grey.shade200,
                      child: const Center(child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey)),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                ElevatedButton.icon(
                  onPressed: () => _updateDocumentStatus(doc['id'], 'approved'),
                  icon: const Icon(Icons.check),
                  label: Text(tr('approve_btn')),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: () => _updateDocumentStatus(doc['id'], 'rejected'),
                  icon: const Icon(Icons.close),
                  label: Text(tr('reject_btn')),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Tab: Ù‚Ø§Ø¦Ù…Ø© Ø§Ù†ØªØ¸Ø§Ø± Ø§Ù„Ø³ÙŠØ§Ø±Ø§Øª
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildVehiclesTab() {
    final tr = ref.watch(translationProvider).tr;
    if (_isLoadingVehicles) {
      _fetchPendingVehicles();
      return const Center(child: CircularProgressIndicator());
    }
    if (_pendingVehicles.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green, size: 64), const SizedBox(height: 16), Text(tr('no_pending_vehicles'))]));

    return ListView.builder(
      itemCount: _pendingVehicles.length,
      itemBuilder: (ctx, i) {
        final v = _pendingVehicles[i];
        final user = v['user'] ?? {};
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ListTile(
              title: Text(user['full_name'] ?? tr('unknown'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('ðŸ“ž ${user['phone'] ?? ''}'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ðŸš— ${v['car_brand'] ?? ''} ${v['car_model'] ?? ''} ${v['car_year'] ?? ''}'),
                Text('ðŸŽ¨ ${tr('car_color')} ${v['car_color'] ?? ''}'),
                Text('ðŸ”¢ ${tr('car_plate')} ${v['car_plate'] ?? ''}'),
              ]),
            ),
            if (v['car_photo_url'] != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(v['car_photo_url'], height: 180, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(height: 100, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.directions_car, size: 48, color: Colors.grey)))),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                ElevatedButton(onPressed: () => _updateVehicleStatus(v['user_id'], 'approved'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: Text(tr('approve_btn'))),
                ElevatedButton(onPressed: () => _updateVehicleStatus(v['user_id'], 'rejected'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: Text(tr('reject_btn'))),
              ]),
            ),
          ]),
        );
      },
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Tab: Ø§Ù„Ø´ÙƒØ§ÙˆÙ‰ (safety_reports)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildReportsTab() {
    final tr = ref.watch(translationProvider).tr;
    if (_isLoadingReports) {
      _fetchSafetyReports();
      return const Center(child: CircularProgressIndicator());
    }
    if (_safetyReports.isEmpty) return Center(child: Text(tr('no_complaints_currently')));

    return ListView.builder(
      itemCount: _safetyReports.length,
      itemBuilder: (ctx, i) {
        final r = _safetyReports[i];
        final reporter = r['reporter'] ?? {};
        final reported = r['reported'] ?? {};
        final status = r['status'] ?? 'open';
        Color statusColor = status == 'open' ? Colors.red : (status == 'resolved' ? Colors.green : Colors.orange);
        String statusText = {'open': tr('status_open'), 'reviewing': tr('status_reviewing'), 'resolved': tr('status_resolved'), 'dismissed': tr('status_dismissed')}[status] ?? status;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text('${tr('reason_label')} ${r['reason'] ?? 'â€”'}', style: const TextStyle(fontWeight: FontWeight.bold))),
                Chip(label: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 11)), backgroundColor: statusColor),
              ]),
              const Divider(),
              Text('${tr('reporter_label')} ${reporter['full_name'] ?? tr('unknown')} (${reporter['phone'] ?? ''})'),
              if (reported['full_name'] != null) Text('${tr('against_label')} ${reported['full_name']}', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(r['details'] ?? '', style: const TextStyle(height: 1.5))),
              const SizedBox(height: 12),
              if (status != 'resolved' && status != 'dismissed')
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (status == 'open') OutlinedButton(onPressed: () => _updateReportStatus(r['id'], 'reviewing'), child: Text(tr('review_btn'))),
                  ElevatedButton(onPressed: () => _updateReportStatus(r['id'], 'resolved'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: Text(tr('resolve_and_close_btn'))),
                  ElevatedButton(onPressed: () => _updateReportStatus(r['id'], 'dismissed'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey), child: Text(tr('reject_btn'))),
                ]),
            ]),
          ),
        );
      },
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Tab: Ø§Ù„Ø±Ø­Ù„Ø§Øª Ø§Ù„Ù†Ø´Ø·Ø© (Live Map)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildLiveRidesTab() {
    final tr = ref.watch(translationProvider).tr;
    if (_isLoadingRides) {
      _fetchActiveRides();
      return const Center(child: CircularProgressIndicator());
    }
    return Column(children: [
      // Ø®Ø±ÙŠØ·Ø© ØµØºÙŠØ±Ø© ØªÙØ¸Ù‡Ø± Ù†Ù‚Ø§Ø· Ø§Ù„Ø±Ø­Ù„Ø§Øª
      SizedBox(
        height: 220,
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(36.7525, 3.042),
            initialZoom: 6,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // Ù…Ù†Ø¹ ØªØ¯ÙˆÙŠØ± Ø§Ù„Ø®Ø±ÙŠØ·Ø© Ù„ØªØ®ÙÙŠÙ Ø§Ù„Ø§Ø³ØªÙ‡Ù„Ø§Ùƒ
            ),
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            MarkerLayer(markers: _activeRides.where((r) => r['pickup_lat'] != null).map((r) {
              return Marker(
                point: LatLng((r['pickup_lat'] as num).toDouble(), (r['pickup_lng'] as num).toDouble()),
                child: const Icon(Icons.location_on, color: Colors.red, size: 28),
              );
            }).toList()),
          ],
        ),
      ),
      Expanded(
        child: _activeRides.isEmpty
            ? Center(child: Text(tr('no_active_rides_now')))
            : ListView.builder(
                itemCount: _activeRides.length,
                itemBuilder: (ctx, i) {
                  final ride = _activeRides[i];
                  return ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFF00897B), child: Icon(Icons.directions_car, color: Colors.white)),
                    title: Text('${ride['rider']?['full_name'] ?? '?'} â†’ ${ride['driver']?['full_name'] ?? '?'}'),
                    subtitle: Text('${ride['pickup_address'] ?? ''} â†’ ${ride['dropoff_address'] ?? ''}\n${tr('status_label')} ${ride['status']}'),
                    trailing: Text('${ride['agreed_fare'] ?? ride['proposed_fare'] ?? 0} Ø¯Ø¬', style: const TextStyle(fontWeight: FontWeight.bold)),
                    isThreeLine: true,
                  );
                },
              ),
      ),
    ]);
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Tab: ØªØ¹Ø¯ÙŠÙ„ Ø£Ø³Ø¹Ø§Ø± Ø§Ù„ÙˆÙ„Ø§ÙŠØ§Øª
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildFareSettingsTab() {
    final tr = ref.watch(translationProvider).tr;
    if (_isLoadingFares) {
      _fetchFareSettings();
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: _fareSettings.length,
      itemBuilder: (ctx, i) {
        final f = _fareSettings[i];
        return ListTile(
          title: Text(f['wilaya'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${tr('base_fare_label')} ${f['base_fare']} Ø¯Ø¬ | ${tr('per_km_label')} ${f['per_km_rate']} | ${tr('per_min_label')} ${f['per_min_rate']} | ${tr('min_fare_label')} ${f['min_fare']}'),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF00897B)),
            onPressed: () => _showFareEditDialog(f),
          ),
        );
      },
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Dialog: Ø¥Ø±Ø³Ø§Ù„ Ø¥Ø´Ø¹Ø§Ø± Ø¬Ù…Ø§Ø¹ÙŠ
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  void _showNotificationDialog() {
    final tr = ref.read(translationProvider).tr;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(tr('send_broadcast_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(controller: _notifTitleCtrl, decoration: InputDecoration(labelText: tr('notification_title_hint'), border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _notifBodyCtrl, maxLines: 3, decoration: InputDecoration(labelText: tr('notification_body_hint'), border: const OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSendingNotif ? null : () { Navigator.pop(ctx); _sendPushNotification(); },
              icon: const Icon(Icons.send),
              label: Text(tr('send_notification_btn')),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _addPromoCode(String code, double amount, String expiresAt) async {
    final messenger = ScaffoldMessenger.of(context);
    final tr = ref.read(translationProvider).tr;
    try {
      await _client.from('promo_codes').insert({
        'code': code.toUpperCase(),
        'discount_amount': amount,
        'expires_at': expiresAt,
        'is_active': true,
      });
      messenger.showSnackBar(SnackBar(content: Text('ØªÙ…Øª Ø¥Ø¶Ø§ÙØ© ÙƒÙˆØ¯ Ø§Ù„Ø®ØµÙ… Ø¨Ù†Ø¬Ø§Ø­!'), backgroundColor: Colors.green));
      _fetchPromoCodes();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('${tr('error_occurred_prefix')} $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _togglePromoCode(String promoId, bool currentStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    final tr = ref.read(translationProvider).tr;
    try {
      await _client.from('promo_codes').update({'is_active': !currentStatus}).eq('id', promoId);
      _fetchPromoCodes();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('${tr('error_occurred_prefix')} $e'), backgroundColor: Colors.red));
    }
  }

  void _showAddPromoDialog() {
    final codeCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final daysCtrl = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ø¥Ø¶Ø§ÙØ© ÙƒÙˆØ¯ Ø®ØµÙ… Ø¬Ø¯ÙŠØ¯'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Ø±Ù…Ø² Ø§Ù„Ø®ØµÙ… (Ù…Ø«Ø§Ù„: DORA2026)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Ù‚ÙŠÙ…Ø© Ø§Ù„Ø®ØµÙ… (Ø¯Ø¬)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: daysCtrl, decoration: const InputDecoration(labelText: 'ØµÙ„Ø§Ø­ÙŠØ© Ø§Ù„ÙƒÙˆØ¯ (Ø¨Ø§Ù„Ø£ÙŠØ§Ù…)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ø¥Ù„ØºØ§Ø¡')),
          ElevatedButton(
            onPressed: () {
              final code = codeCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text);
              final days = int.tryParse(daysCtrl.text) ?? 30;
              if (code.isNotEmpty && amount != null && amount > 0) {
                Navigator.pop(ctx);
                final expiresAt = DateTime.now().add(Duration(days: days)).toIso8601String();
                _addPromoCode(code, amount, expiresAt);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
            child: const Text('Ø¥Ø¶Ø§ÙØ© Ø§Ù„ÙƒÙˆØ¯'),
          ),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Tab: Ø§Ù„Ø®ØµÙˆÙ…Ø§Øª
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildPromoCodesTab() {
    final tr = ref.watch(translationProvider).tr;
    if (_isLoadingPromo) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddPromoDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(tr('create_new_promo_code'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        Expanded(
          child: _promoCodes.isEmpty 
              ? Center(child: Text(tr('no_promo_codes')))
              : ListView.builder(
                  itemCount: _promoCodes.length,
                  itemBuilder: (ctx, i) {
                    final p = _promoCodes[i];
                    final isActive = p['is_active'] ?? true;
                    return ListTile(
                      leading: Icon(Icons.local_offer, color: isActive ? Colors.green : Colors.grey),
                      title: Text(p['code'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey)),
                      subtitle: Text('${tr('discount_amount_label')} ${p['discount_amount']} Ø¯Ø¬'),
                      trailing: Switch(
                        value: isActive,
                        activeThumbColor: const Color(0xFF00897B),
                        onChanged: (val) => _togglePromoCode(p['id'].toString(), isActive),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Tab: Ø§Ù„Ù…ÙÙ‚ÙˆØ¯Ø§Øª
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildLostItemsTab() {
    final tr = ref.watch(translationProvider).tr;
    if (_isLoadingLost) return const Center(child: CircularProgressIndicator());
    if (_lostItems.isEmpty) return Center(child: Text(tr('no_lost_items')));
    return ListView.builder(
      itemCount: _lostItems.length,
      itemBuilder: (ctx, i) {
        final item = _lostItems[i];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: const Icon(Icons.find_in_page, color: Colors.orange),
            title: Text(item['description'] ?? tr('lost_item_default'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${tr('ride_label')} ${item['ride']?['pickup_address']} â†’ ${item['ride']?['dropoff_address']}\n${tr('status_label')} ${item['status']}'),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () {
                // Ø³ÙŠØªÙ… Ù„Ø§Ø­Ù‚Ø§Ù‹: Mark as resolved
              },
            ),
          ),
        );
      },
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Tab: Ø§Ù„Ù†Ø²Ø§Ø¹Ø§Øª
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildDisputesTab() {
    final tr = ref.watch(translationProvider).tr;
    if (_isLoadingDisputes) return const Center(child: CircularProgressIndicator());
    if (_disputes.isEmpty) return Center(child: Text(tr('no_open_disputes')));
    return ListView.builder(
      itemCount: _disputes.length,
      itemBuilder: (ctx, i) {
        final d = _disputes[i];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: const Icon(Icons.gavel, color: Colors.red),
            title: Text('${tr('financial_dispute_ride')}${(d['ride_id'] ?? '').toString().substring(0, 4)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${tr('details_label')} ${d['reason']}\n${tr('status_label')} ${d['status']}'),
            isThreeLine: true,
            trailing: ElevatedButton(
              onPressed: () {
                // Ø³ÙŠØªÙ… Ù„Ø§Ø­Ù‚Ø§Ù‹: Review Dispute
              },
              child: Text(tr('review_btn')),
            ),
          ),
        );
      },
    );
  }
}

