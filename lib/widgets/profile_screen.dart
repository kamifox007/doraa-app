import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../providers/locale_provider.dart';

import '../services/auth_service.dart';
import '../widgets/admin_dashboard.dart';
import '../widgets/auth_flow.dart';
import '../widgets/subscription_screen.dart';
import '../widgets/support_screen.dart';
import '../widgets/privacy_policy_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/driver_registration_screen.dart';

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

  @override
  void initState() {
    super.initState();
    final supaUser = Supabase.instance.client.auth.currentUser;
    _nameController.text = supaUser?.userMetadata?['full_name'] ?? '';
    _phoneController.text = supaUser?.phone ?? '';
    _checkRole();
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
      backgroundColor: const Color(0xFFF9F5FF),
      body: CustomScrollView(
        slivers: [
            // ── رأس الصفحة مع خلفية متدرجة ──
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: const Color(0xFFE91E63),
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(tr('my_profile_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              centerTitle: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE91E63), Color(0xFF880E4F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      // صورة الملف الشخصي مع إطار متوهج
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage: _avatarUrl != null 
                                  ? CachedNetworkImageProvider(_avatarUrl!) 
                                  : null,
                              child: _avatarUrl == null
                                  ? const Icon(Icons.person_rounded, size: 60, color: Color(0xFFE91E63))
                                  : null,
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
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE91E63),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── تعديل البيانات ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('my_info_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: tr('full_name_label'),
                              prefixIcon: const Icon(Icons.person_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: tr('phone_number_label'),
                              prefixIcon: const Icon(Icons.phone_rounded),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Text(tr('save_changes_btn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── روابط سريعة ──
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          // محفظة الاشتراك
                          ListTile(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFE91E63)),
                            ),
                            title: Text(tr('wallet_and_subscription'), style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(tr('wallet_and_subscription_subtitle')),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                          ),

                          const Divider(height: 1, indent: 20),
                          // المساعدة والدعم
                          ListTile(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.headset_mic_rounded, color: Colors.indigo),
                            ),
                            title: Text(tr('help_and_complaints'), style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                          ),

                          const Divider(height: 1, indent: 20),
                          // سياسة الخصوصية
                          ListTile(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.privacy_tip_rounded, color: Colors.teal),
                            ),
                            title: Text(tr('privacy_policy_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                          ),

                          if (_userRole == 'admin') ...{
                            const Divider(height: 1, indent: 20),
                            ListTile(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00897B).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF00897B)),
                              ),
                              title: Text(tr('admin_dashboard_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(tr('admin_dashboard_subtitle')),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                            ),
                          },

                          if (_userRole == 'rider' || _userRole == null) ...{
                            const Divider(height: 1, indent: 20),
                            ListTile(
                              onTap: () async {
                                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverRegistrationScreen()));
                                if (result == true) {
                                  _checkRole(); // Refresh role to 'pending_driver'
                                }
                              },
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.directions_car_rounded, color: Colors.orange),
                              ),
                              title: Text(tr('become_driver_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                              subtitle: Text(tr('become_driver_subtitle')),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                            ),
                          } else if (_userRole == 'pending_driver' || _userRole == 'pending') ...{
                            const Divider(height: 1, indent: 20),
                            ListTile(
                              onTap: () {},
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.hourglass_empty_rounded, color: Colors.grey),
                              ),
                              title: Text(tr('request_under_review'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              subtitle: Text(tr('admin_reviewing_data')),
                            ),
                          } else if (_userRole == 'driver') ...{
                            const Divider(height: 1, indent: 20),
                            ListTile(
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('ready_to_drive_msg'))));
                              },
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.power_settings_new_rounded, color: Colors.green),
                              ),
                              title: Text(tr('start_driving_btn'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              subtitle: Text(tr('start_driving_subtitle')),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                            ),
                          },

                          const Divider(height: 1, indent: 20),

                          // تغيير اللغة
                          ListTile(
                            onTap: () {
                              _showLanguageDialog(context);
                            },
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.language_rounded, color: Colors.blue),
                            ),
                            title: Text(tr('change_language_btn'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                          ),

                          const Divider(height: 1, indent: 20),

                          // تسجيل الخروج
                          ListTile(
                            onTap: () async {
                              await Supabase.instance.client.auth.signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const AuthFlowScreen()),
                                  (route) => false,
                                );
                              }
                            },

                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.logout_rounded, color: Colors.red),
                            ),
                            title: Text(tr('logout_btn'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        tr('app_version'),
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  // Removed _showBecomeDriverDialog as it's no longer needed since we use DriverRegistrationScreen inline.

  void _showLanguageDialog(BuildContext context) {
    final tr = ref.read(translationProvider).tr;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('choose_language_dialog')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('العربية 🇩🇿'),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale('ar');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Français 🇫🇷'),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale('fr');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('English 🇬🇧'),
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
