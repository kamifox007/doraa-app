import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doraa/services/translation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doraa/providers/auth_providers.dart';
import 'package:doraa/providers/locale_provider.dart';

import 'package:doraa/services/auth_service.dart';
import 'package:doraa/features/admin/presentation/screens/admin_dashboard.dart';
import 'package:doraa/features/auth/presentation/screens/auth_flow.dart';
import 'package:doraa/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:doraa/features/support/presentation/screens/support_screen.dart';
import 'package:doraa/features/legal/screens/privacy_policy_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:doraa/features/auth/presentation/screens/driver_registration_screen.dart';
import 'package:doraa/features/wallet/presentation/screens/driver_wallet_screen.dart';
import 'package:doraa/features/wallet/presentation/screens/agent_dashboard_screen.dart';
import 'package:doraa/features/admin/presentation/screens/admin_recharge_dashboard.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _userRole;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;

  // Referral state - Ø§Ù„Ø³Ø§Ø¦Ù‚Ø§Øª
  String? _referralCode;
  int _totalReferrals = 0;
  double _totalEarned = 0;
  bool _loadingReferral = true;

  // Referral state - Ø§Ù„Ø±Ø§ÙƒØ¨Ø§Øª
  int _riderReferrals = 0;
  bool _hasRideDiscount = false;
  int _rideDiscountPct = 0;
  int _remainingForDiscount = 5;

  @override
  void initState() {
    super.initState();
    final supaUser = Supabase.instance.client.auth.currentUser;
    _nameController.text = supaUser?.userMetadata?['full_name'] ?? '';
    _phoneController.text = supaUser?.phone ?? '';
    _checkRole();
    _loadReferralStats();
  }

  Future<void> _loadReferralStats() async {
    setState(() => _loadingReferral = true);
    final userId = ref.read(authProvider).userId;
    if (userId == null) { setState(() => _loadingReferral = false); return; }
    try {
      final stats = await Supabase.instance.client.rpc(
        'get_referral_stats',
        params: {'p_user_id': userId},
      );
      if (mounted && stats != null) {
        setState(() {
          _referralCode         = stats['referral_code'] as String?;
          _totalReferrals       = (stats['total_referrals'] as num?)?.toInt() ?? 0;
          _totalEarned          = (stats['total_earned'] as num?)?.toDouble() ?? 0;
          _riderReferrals       = (stats['rider_referrals'] as num?)?.toInt() ?? 0;
          _hasRideDiscount      = stats['has_ride_discount'] as bool? ?? false;
          _rideDiscountPct      = (stats['ride_discount_pct'] as num?)?.toInt() ?? 0;
          _remainingForDiscount = (stats['remaining_for_discount'] as num?)?.toInt() ?? 5;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _referralCode = (userId.replaceAll('-', '').substring(0, 8)).toUpperCase());
      }
    } finally {
      if (mounted) setState(() => _loadingReferral = false);
    }
  }

  Future<void> _checkRole() async {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('role, avatar_url')
          .eq('user_id', userId)
          .maybeSingle();
      if (response != null && mounted) {
        setState(() {
          _userRole = response['role'];
          _avatarUrl = response['avatar_url'];
        });
      }
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final userId = ref.read(authProvider).userId;
    if (userId != null) {
      await AuthService().updateUserProfile(
        userId: userId,
        data: {
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
        },
      );
      if (mounted) {
        final tr = ref.read(translationProvider).tr;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('profile_updated_success'))));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() => _isUploadingAvatar = true);
      final userId = ref.read(authProvider).userId;
      
      if (userId != null) {
        final newUrl = await AuthService().uploadPublicAvatar(
          userId: userId,
          filePath: pickedFile.path,
        );
        
        if (newUrl != null && mounted) {
          setState(() => _avatarUrl = newUrl);
          final tr = ref.read(translationProvider).tr;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('avatar_updated_success')))
          );
        } else if (mounted) {
          final tr = ref.read(translationProvider).tr;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('avatar_update_failed')))
          );
        }
      }
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider).tr;
    ref.watch(authProvider);
    final supaUser = Supabase.instance.client.auth.currentUser;
    final name = supaUser?.userMetadata?['full_name'] ?? tr('dora_user');
    final email = supaUser?.email ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(tr('my_profile_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black26, blurRadius: 10)])),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  children: [
                    // â”€â”€ Glassmorphism Profile Card â”€â”€
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF121212),
                                  border: Border.all(color: const Color(0xFFFFD700), width: 2),
                                  boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 3)],
                                ),
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: const Color(0xFF121212),
                                  backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                                  child: _avatarUrl == null ? const Icon(Icons.person_rounded, size: 60, color: Color(0xFFFFD700)) : null,
                                ),
                              ),
                                if (_isUploadingAvatar)
                                  const CircularProgressIndicator(color: Color(0xFFE91E63)),
                                if (_userRole == 'driver')
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFE5C100)]),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
                                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                                        ),
                                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            if (email.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // â”€â”€ My Info (Data Editing) â”€â”€
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.2)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('my_info_title'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
                            const SizedBox(height: 20),
                            // Frosted TextFields
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF121212),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                              ),
                              child: TextField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: tr('full_name_label'),
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFFFFD700)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF121212),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                              ),
                              child: TextField(
                                controller: _phoneController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: tr('phone_number_label'),
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFFFFD700)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Gradient Save Button
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: const Color(0xFFFFD700),
                                boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                                    : Text(tr('save_changes_btn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // â”€â”€ Referral Card â”€â”€
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFD700), size: 26),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Ø§Ø¯Ø¹ÙŠ ØµØ¯ÙŠÙ‚Ø§ØªÙƒ ÙˆØ§ÙƒØ³Ø¨ÙŠ!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 2),
                                        Text('Ø§Ø­ØµÙ„ÙŠ Ø¹Ù„Ù‰ 1000 Ø¯Ø¬ Ù„ÙƒÙ„ Ø³Ø§Ø¦Ù‚Ø© ØªÙ†Ø¶Ù… Ø¨ÙƒÙˆØ¯Ùƒ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Referral Code Box
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: _loadingReferral
                                    ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                                    : Row(
                                        children: [
                                          const Icon(Icons.qr_code_rounded, color: Colors.white70, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _referralCode ?? 'DORA-XXXX',
                                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: 'https://doraapp.dz/join?ref=${_referralCode ?? ''}'));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('ØªÙ… Ù†Ø³Ø® Ø±Ø§Ø¨Ø· Ø§Ù„Ø¥Ø­Ø§Ù„Ø©!'), backgroundColor: Colors.green),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.25),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 16),

                              // Stats Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        children: [
                                          Text('$_totalReferrals', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                          const Text('Ø³Ø§Ø¦Ù‚Ø© Ù…Ø¯Ø¹ÙˆØ©', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        children: [
                                          Text('${_totalEarned.toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                          const Text('Ù…Ø¬Ù…ÙˆØ¹ Ø§Ù„Ù…ÙƒØ§ÙØ¢Øª', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Share Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final link = 'https://doraapp.dz/join?ref=${_referralCode ?? ''}';
                                    Clipboard.setData(ClipboardData(text: 'Ø¯Ø¹ÙˆØ© DORA Ø§Ù„Ø®Ø§ØµØ© Ø¨ÙŠ! Ø³Ø¬Ù„ÙŠ ÙƒØ³Ø§Ø¦Ù‚Ø© ÙˆØ§Ø­ØµÙ„ÙŠ Ø¹Ù„Ù‰ Ø¨Ø¯Ø§ÙŠØ© Ù…Ø¬Ø§Ù†ÙŠØ©. \nÙƒÙˆØ¯ÙŠ: ${_referralCode ?? ''}\n$link'));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('ØªÙ… Ù†Ø³Ø® Ø±Ø³Ø§Ù„Ø© Ø§Ù„Ø¯Ø¹ÙˆØ©! Ø´Ø§Ø±ÙƒÙŠÙ‡Ø§ Ù…Ø¹ ØµØ¯ÙŠÙ‚Ø§ØªÙƒ Ø¨ÙˆØ§ØªØ³Ø§Ø¨ Ø£Ùˆ ÙˆØ³Ø§Ø¦Ù„ Ø£Ø®Ø±Ù‰.'), backgroundColor: Colors.green),
                                    );
                                  },
                                  icon: const Icon(Icons.share_rounded, color: Colors.black),
                                  label: const Text('Ø´Ø§Ø±ÙƒÙŠ Ø±Ø§Ø¨Ø· Ø§Ù„Ø¯Ø¹ÙˆØ©', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFD700),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // â”€â”€ Rider Referral Card (5 Ø±ÙƒØ§Ø¨ = Ø®ØµÙ… 20%) â”€â”€
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.discount_rounded, color: Color(0xFFFFD700), size: 26),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Ø§Ø¯Ø¹ÙŠ ØµØ¯ÙŠÙ‚Ø§ØªÙƒ ÙˆØ§Ø­ØµÙ„ÙŠ Ø®ØµÙ…!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 2),
                                        Text('ÙƒÙ„ 5 Ø±Ø§ÙƒØ¨Ø§Øª ØªØ¯Ø¹ÙŠÙ†Ù‡Ù† = Ø®ØµÙ… 20% Ø¹Ù„Ù‰ Ø±Ø­Ù„ØªÙƒ Ø§Ù„Ù‚Ø§Ø¯Ù…Ø© âœ¨', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Active discount banner
                              if (_hasRideDiscount)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.yellowAccent.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.yellowAccent.withValues(alpha: 0.6)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.yellow, size: 22),
                                      const SizedBox(width: 8),
                                      Text('Ù„Ø¯ÙŠÙƒ Ø®ØµÙ… Ù…ÙØ¹Ù‘Ù„ $_rideDiscountPct% Ø¹Ù„Ù‰ Ø±Ø­Ù„ØªÙƒ Ø§Ù„Ù‚Ø§Ø¯Ù…Ø©!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),

                              // Progress bar (from 0 to 5)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('ØªÙ‚Ø¯Ù…Ùƒ Ù†Ø­Ùˆ Ø§Ù„Ø®ØµÙ…:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      Text('${_riderReferrals % 5}/5 Ø±Ø§ÙƒØ¨Ø§Øª', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: (_riderReferrals % 5) / 5.0,
                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                                      minHeight: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (_remainingForDiscount < 5)
                                    Text('Ø¨Ù‚ÙŠ $_remainingForDiscount Ø±Ø§ÙƒØ¨Ø© Ù„ØªØ­ØµÙ„ÙŠ Ø¹Ù„Ù‰ Ø®ØµÙ… 20%!', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Stats Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        children: [
                                          Text('$_riderReferrals', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                          const Text('Ø±Ø§ÙƒØ¨Ø© Ù…Ø¯Ø¹ÙˆØ©', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        children: [
                                          Text('${(_riderReferrals ~/ 5)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                          const Text('Ø®ØµÙ… 20% Ù…ÙƒØªØ³Ø¨', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Share Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final link = 'https://doraapp.dz/join?ref=${_referralCode ?? ''}&type=rider';
                                    Clipboard.setData(ClipboardData(text: 'Ø¬Ø±Ø¨ÙŠ DORA Ù…Ø¹ÙŠ! ØªØ·Ø¨ÙŠÙ‚ Ù†Ù‚Ù„ Ø­ØµØ±ÙŠ Ù„Ù„Ù†Ø³Ø§Ø¡ ÙÙ‚Ø·. Ø³Ø¬Ù„ÙŠ ÙˆØ§Ø­ØµÙ„ÙŠ Ø¹Ù„Ù‰ Ø¹Ø±ÙˆØ¶ Ø­ØµØ±ÙŠØ©!\n$link'));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('ØªÙ… Ù†Ø³Ø® Ø§Ù„Ø±Ø³Ø§Ù„Ø©! Ø´Ø§Ø±ÙƒÙŠÙ‡Ø§ Ù…Ø¹ ØµØ¯ÙŠÙ‚Ø§ØªÙƒ Ù„Ø¬Ù…Ø¹ Ø§Ù„Ø®ØµÙ… Ø¨Ø³Ø±Ø¹Ø©!'),
                                        backgroundColor: Color(0xFF00897B),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.share_rounded, color: Colors.black),
                                  label: const Text('Ø´Ø§Ø±ÙƒÙŠ Ø±Ø§Ø¨Ø· Ø¯Ø¹ÙˆØ© Ø§Ù„Ø±ÙƒØ§Ø¨', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFD700),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // â”€â”€ Quick Links â”€â”€
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.2)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Column(
                          children: [
                            _buildSettingsTile(
                              icon: Icons.account_balance_wallet_rounded, 
                              color: const Color(0xFFE91E63), 
                              title: tr('wallet_and_subscription'), 
                              subtitle: tr('wallet_and_subscription_subtitle'),
                              onTap: () {
                                if (_userRole == 'driver') {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverWalletScreen()));
                                } else {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                                }
                              },
                            ),
                            const Divider(height: 1, indent: 70, endIndent: 20, color: Color(0xFFEEEEEE)),
                            _buildSettingsTile(
                              icon: Icons.headset_mic_rounded, 
                              color: Colors.indigo, 
                              title: tr('help_and_complaints'), 
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
                            ),
                            const Divider(height: 1, indent: 70, endIndent: 20, color: Color(0xFFEEEEEE)),
                            _buildSettingsTile(
                              icon: Icons.privacy_tip_rounded, 
                              color: Colors.teal, 
                              title: tr('privacy_policy_title'), 
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                            ),
                            
                            if (_userRole == 'admin') ...[
                              const Divider(height: 1, indent: 70, endIndent: 20, color: Color(0xFF333333)),
                              _buildSettingsTile(
                                icon: Icons.admin_panel_settings_rounded, 
                                color: const Color(0xFF00897B), 
                                title: tr('admin_dashboard_title'), 
                                subtitle: tr('admin_dashboard_subtitle'),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                              ),
                              const Divider(height: 1, indent: 70, endIndent: 20, color: Color(0xFF333333)),
                              _buildSettingsTile(
                                icon: Icons.account_balance, 
                                color: const Color(0xFF673AB7), 
                                title: 'Ø´Ø­Ù† Ø£Ø±ØµØ¯Ø© Ø§Ù„ÙˆÙƒÙ„Ø§Ø¡ (Top-up)', 
                                subtitle: 'Ù†Ø¸Ø§Ù… Ø§Ù„Ø´Ø­Ù† Ø§Ù„Ø«Ù„Ø§Ø«ÙŠ (Tier 1)',
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRechargeDashboard())),
                              ),
                            ],

                            if (_userRole == 'agent') ...[
                              const Divider(height: 1, indent: 70, endIndent: 20, color: Color(0xFF333333)),
                              _buildSettingsTile(
                                icon: Icons.point_of_sale_rounded, 
                                color: const Color(0xFF00897B), 
                                title: 'Ù„ÙˆØ­Ø© ØªØ­ÙƒÙ… Ø§Ù„ÙˆÙƒÙŠÙ„', 
                                subtitle: 'Ø´Ø­Ù† Ù…Ø­Ø§ÙØ¸ Ø§Ù„Ø³Ø§Ø¦Ù‚ÙŠÙ†',
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentDashboardScreen())),
                              ),
                            ],

                            if (_userRole == 'rider' || _userRole == null) ...[
                              const Divider(height: 1, indent: 70, endIndent: 20, color: Color(0xFF333333)),
                              _buildSettingsTile(
                                icon: Icons.directions_car_rounded, 
                                color: Colors.orange, 
                                title: tr('become_driver_title'), 
                                subtitle: tr('become_driver_subtitle'),
                                onTap: () async {
                                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverRegistrationScreen()));
                                  if (result == true) _checkRole();
                                },
                              ),
                            ] else if (_userRole == 'pending_driver' || _userRole == 'pending') ...[
                              const Divider(height: 1, indent: 70, endIndent: 20, color: Color(0xFF333333)),
                              _buildSettingsTile(
                                icon: Icons.hourglass_empty_rounded, 
                                color: Colors.grey, 
                                title: tr('request_under_review'), 
                                subtitle: tr('admin_reviewing_data'),
                                onTap: () {},
                              ),
                            ] else if (_userRole == 'driver') ...[
                              const Divider(height: 1, indent: 70, endIndent: 20, color: Color(0xFF333333)),
                              _buildSettingsTile(
                                icon: Icons.power_settings_new_rounded, 
                                color: Colors.green, 
                                title: tr('start_driving_btn'), 
                                subtitle: tr('start_driving_subtitle'),
                                onTap: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('ready_to_drive_msg'))));
                                },
                              ),
                            ],

                            const Divider(height: 1, indent: 70, endIndent: 20, color: Color(0xFF333333)),
                            _buildSettingsTile(
                              icon: Icons.language_rounded, 
                              color: Colors.blue, 
                              title: tr('change_language_btn'), 
                              onTap: () => _showLanguageDialog(context),
                            ),
                            const Divider(height: 1, indent: 70, endIndent: 20, color: Color(0xFF333333)),
                            _buildSettingsTile(
                              icon: Icons.logout_rounded, 
                              color: Colors.red, 
                              title: tr('logout_btn'), 
                              onTap: () async {
                                await Supabase.instance.client.auth.signOut();
                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthFlowScreen()), (route) => false);
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      Text(tr('app_version'), style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required Color color, required String title, String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: const Color(0xFFFFD700), size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)) : null,
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFFFD700)),
      ),
    );
  }

  // Removed _showBecomeDriverDialog as it's no longer needed since we use DriverRegistrationScreen inline.

  void _showLanguageDialog(BuildContext context) {
    final tr = ref.read(translationProvider).tr;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5))),
        title: Text(tr('choose_language_dialog'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Ø§Ù„Ø¹Ø±Ø¨ÙŠØ© ðŸ‡©ðŸ‡¿', style: TextStyle(color: Colors.white)),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale('ar');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('FranÃ§ais ðŸ‡«ðŸ‡·', style: TextStyle(color: Colors.white)),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale('fr');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('English ðŸ‡¬ðŸ‡§', style: TextStyle(color: Colors.white)),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale('en');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}


