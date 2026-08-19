import 'package:flutter/foundation.dart';
import '../core/utils/file_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/auth_models.dart' as app_models;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'app_config.dart';

class AuthService {
  static SupabaseClient get client => Supabase.instance.client;

  void _requireConfigured() {
    if (!AppConfig.isSupabaseConfigured) {
      throw StateError('Supabase is not configured. Set the real URL and anon key before continuing.');
    }
  }

  Future<void> signInWithOtp({required String phone}) async {
    _requireConfigured();
    await client.auth.signInWithOtp(phone: phone);
  }

  Future<AuthResponse> verifyOtp({required String phone, required String token}) async {
    _requireConfigured();
    return client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    _requireConfigured();
    return client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _requireConfigured();
    return client.auth.signInWithPassword(email: email, password: password);
  }


  Future<AuthResponse> signUpWithPhonePassword({
    required String phone,
    required String password,
  }) async {
    _requireConfigured();
    return client.auth.signUp(phone: phone, password: password);
  }

  Future<AuthResponse> signInWithPhonePassword({
    required String phone,
    required String password,
  }) async {
    _requireConfigured();
    return client.auth.signInWithPassword(phone: phone, password: password);
  }

  Future<void> saveUserProfile({

    required String userId,
    required Map<String, dynamic> data,
  }) async {
    _requireConfigured();
    await client.from('users').upsert({
      'id': userId,
      ...data,
    });

    try {
      await client.from('user_profiles').upsert({
        'user_id': userId,
        'full_name': data['full_name'],
        'email': data['email'],
        'phone': data['phone'],
        'wilaya': data['wilaya'],
        'role': data['role'],
        'verification_status': data['verification_status'],
        if (data.containsKey('avatar_url')) 'avatar_url': data['avatar_url'],
      });
    } catch (_) {
      // Ignore optional sync failures so auth flow remains usable.
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    _requireConfigured();
    // Update users table
    if (data.containsKey('full_name') || data.containsKey('email') || data.containsKey('phone')) {
      final userUpdates = <String, dynamic>{};
      if (data.containsKey('full_name')) userUpdates['full_name'] = data['full_name'];
      if (data.containsKey('email')) userUpdates['email'] = data['email'];
      if (data.containsKey('phone')) userUpdates['phone'] = data['phone'];
      await client.from('users').update(userUpdates).eq('id', userId);
    }
    
    // Update user_profiles table
    try {
      await client.from('user_profiles').update(data).eq('user_id', userId);
    } catch (_) {
      // Ignore if profile doesn't exist
    }
  }

  Future<void> saveVehicleData({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    _requireConfigured();
    await client.from('driver_profiles').upsert({
      'user_id': userId,
      ...data,
    });
  }

  Future<void> saveEmergencyContacts({
    required String userId,
    required List<app_models.EmergencyContact> contacts,
  }) async {
    _requireConfigured();
    final rows = contacts
        .where((contact) => contact.name.trim().isNotEmpty || contact.phone.trim().isNotEmpty)
        .map((contact) => {
              'user_id': userId,
              'contact_name': contact.name,
              'contact_phone': contact.phone,
              'relationship': contact.relationship,
              'is_primary': contact.isPrimary,
            })
        .toList();

    if (rows.isNotEmpty) {
      await client.from('emergency_contacts').insert(rows);
    }
  }

  Future<String?> uploadIdentityDocument({
    required String userId,
    required String filePath,
    required String type,
  }) async {
    _requireConfigured();
    try {
      if (!kIsWeb && !fileExists(filePath)) return null;
      
      final ext = filePath.split('.').last.toLowerCase();
      
      // 1. Validate file type
      final allowedExtensions = ['jpg', 'jpeg', 'png'];
      if (!allowedExtensions.contains(ext)) {
        debugPrint('Error: Invalid file type ($ext)');
        return null;
      }

      // 2. Validate file size (max 5MB)
      final fileSize = kIsWeb ? 0 : await getFileLength(getPlatformFile(filePath));
      if (!kIsWeb && fileSize > 5 * 1024 * 1024) {
        debugPrint('Error: File size exceeds 5MB limit');
        return null;
      }

      final fileName = '${userId}_${type}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storagePath = '$userId/$fileName';
      
      final compressedFile = kIsWeb ? null : await _compressImage(getPlatformFile(filePath));
      if (!kIsWeb && compressedFile == null) return null;
      
      await client.storage.from('identity_documents').upload(storagePath, kIsWeb ? filePath : compressedFile);
      
      // 3. Security: Use createSignedUrl instead of getPublicUrl (valid for 10 years as a secure reference)
      // For ultimate security, the DB should store 'storagePath' and UI should request signed URLs on the fly.
      final signedUrl = await client.storage.from('identity_documents').createSignedUrl(storagePath, 315360000); // 10 years
      return signedUrl;
    } catch (e) {
      debugPrint('Error uploading $type: $e');
      return null;
    }
  }

  Future<dynamic> _compressImage(dynamic file) async {
    if (kIsWeb) return file;
    final filePath = getFilePath(file);
    final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
    if (lastIndex == -1) return file; // Might not be compressable easily or already png
    
    final splitted = filePath.substring(0, (lastIndex));
    final outPath = "${splitted}_out${filePath.substring(lastIndex)}";
    
    var result = await FlutterImageCompress.compressAndGetFile(
      filePath, 
      outPath,
      quality: 70,
    );
    
    if (result != null) {
      return getPlatformFile(result.path);
    }
    return file; // Fallback to original
  }

  Future<String?> uploadPublicAvatar({
    required String userId,
    required String filePath,
  }) async {
    _requireConfigured();
    try {
      if (!kIsWeb && !fileExists(filePath)) return null;
      
      final ext = filePath.split('.').last.toLowerCase();
      final fileName = '${userId}_avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storagePath = 'avatars/$fileName';
      
      final compressedFile = kIsWeb ? null : await _compressImage(getPlatformFile(filePath));
      if (!kIsWeb && compressedFile == null) return null;

      // Ensure the 'public_profiles' bucket exists and is public
      await client.storage.from('public_profiles').upload(storagePath, kIsWeb ? filePath : compressedFile);
      
      final publicUrl = client.storage.from('public_profiles').getPublicUrl(storagePath);
      
      // Update the user profile with the new avatar
      await updateUserProfile(userId: userId, data: {'avatar_url': publicUrl});
      
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    _requireConfigured();
    await client.auth.signOut();
  }

  User? get currentUser => AppConfig.isSupabaseConfigured ? client.auth.currentUser : null;

  Stream<AuthState> get authStateChanges => AppConfig.isSupabaseConfigured
      ? client.auth.onAuthStateChange
      : const Stream.empty();
}
