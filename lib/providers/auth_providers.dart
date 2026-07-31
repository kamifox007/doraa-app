import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../services/ai_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(authServiceProvider));
});

final registrationProvider = StateNotifierProvider<RegistrationController, RegistrationState>(
  (ref) => RegistrationController(),
);

final uploadProvider = StateNotifierProvider<UploadController, UploadState>(
  (ref) => UploadController(),
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authService) : super(const AuthState());

  final AuthService _authService;

  Future<void> signInWithOtp({required String phone}) async {
    state = state.copyWith(status: AuthStatus.loading, message: 'جاري إرسال الرمز...');
    try {
      await _authService.signInWithOtp(phone: phone);
      state = state.copyWith(status: AuthStatus.authenticated, message: 'تم إرسال الرمز');
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, message: e.toString());
    }
  }

  Future<void> verifyOtp({required String phone, required String token}) async {
    state = state.copyWith(status: AuthStatus.loading, message: 'جاري التحقق...');
    try {
      final res = await _authService.verifyOtp(phone: phone, token: token);
      if (res.session != null) {
        state = state.copyWith(status: AuthStatus.authenticated, isAuthenticated: true, userId: res.user?.id);
      } else {
        state = state.copyWith(status: AuthStatus.error, message: 'رمز غير صالح');
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, message: e.toString());
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, message: 'جاري إنشاء الحساب...');
    try {
      final res = await _authService.signUpWithEmail(email: email, password: password);
      if (res.user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, isAuthenticated: true, userId: res.user?.id);
      } else {
        state = state.copyWith(status: AuthStatus.error, message: 'تعذر إنشاء الحساب');
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, message: e.toString());
    }
  }

  Future<void> signInWithEmail({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, message: 'جاري تسجيل الدخول...');
    try {
      final res = await _authService.signInWithEmail(email: email, password: password);
      if (res.user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, isAuthenticated: true, userId: res.user?.id);
      } else {
        state = state.copyWith(status: AuthStatus.error, message: 'بيانات الدخول غير صحيحة');
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, message: e.toString());
    }
  }

  Future<void> completeRegistration(RegistrationState registration) async {
    state = state.copyWith(status: AuthStatus.loading, message: 'جاري حفظ الملف الشخصي...');
    try {
      final userId = state.userId ?? _authService.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        throw StateError('لم يتم العثور على مستخدم مصادق عليه. يرجى إكمال التحقق أولًا.');
      }
      String? cniFrontUrl;
      String? cniBackUrl;
      String? selfieUrl;
      String? carPhotoUrl;

      if (registration.role == 'driver') {
        if (registration.cniFrontPath != null) {
          cniFrontUrl = await _authService.uploadIdentityDocument(userId: userId, filePath: registration.cniFrontPath!, type: 'cni_front');
        }
        if (registration.cniBackPath != null) {
          cniBackUrl = await _authService.uploadIdentityDocument(userId: userId, filePath: registration.cniBackPath!, type: 'cni_back');
        }
        if (registration.selfiePath != null) {
          selfieUrl = await _authService.uploadIdentityDocument(userId: userId, filePath: registration.selfiePath!, type: 'selfie');
        }
        if (registration.carPhotoPath != null) {
          carPhotoUrl = await _authService.uploadIdentityDocument(userId: userId, filePath: registration.carPhotoPath!, type: 'car_photo');
        }
      }

      await _authService.saveUserProfile(
        userId: userId,
        data: {
          'email': registration.email,
          'full_name': registration.fullName,
          'wilaya': registration.wilaya,
          'role': registration.role,
          'verification_status': registration.role == 'driver' ? 'pending' : 'approved',
          'phone': registration.phone,
          'cni_front_url': ?cniFrontUrl,
          'cni_back_url': ?cniBackUrl,
          'selfie_url': ?selfieUrl,
        },
      );
      if (registration.role == 'driver') {
        await _authService.saveVehicleData(
          userId: userId,
          data: {
            'car_brand': registration.carBrand,
            'car_model': registration.carModel,
            'car_year': registration.carYear,
            'car_color': registration.carColor,
            'car_plate': registration.carPlate,
            'car_photo_url': ?carPhotoUrl,
          },
        );
      }
      if (registration.emergencyContacts.isNotEmpty) {
        await _authService.saveEmergencyContacts(userId: userId, contacts: registration.emergencyContacts);
      }
      // تحقق AI من تطابق الوجه مع بطاقة الهوية بعد الرفع
      if (registration.role == 'driver' && selfieUrl != null && cniFrontUrl != null) {
        state = state.copyWith(status: AuthStatus.loading, message: 'جاري التحقق من الهوية بالذكاء الاصطناعي...');
        await AIService.verifyDriverIdentity(
          userId: userId,
          selfieUrl: selfieUrl,
          cniUrl: cniFrontUrl,
        );
      }
      state = state.copyWith(status: AuthStatus.authenticated, isAuthenticated: true, userId: userId, message: 'تم حفظ الملف الشخصي');
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, message: e.toString());
    }
  }
}

class RegistrationController extends StateNotifier<RegistrationState> {
  RegistrationController() : super(const RegistrationState());

  void updatePhone(String value) => state = state.copyWith(phone: value);
  void updateOtp(String value) => state = state.copyWith(otp: value);
  void updateEmail(String value) => state = state.copyWith(email: value);
  void updatePassword(String value) => state = state.copyWith(password: value);
  void updateConfirmPassword(String value) => state = state.copyWith(confirmPassword: value);
  void updateFullName(String value) => state = state.copyWith(fullName: value);
  void updateWilaya(String value) => state = state.copyWith(wilaya: value);
  void updateRole(String value) => state = state.copyWith(role: value);
  void updateCniFront(String value) => state = state.copyWith(cniFrontPath: value);
  void updateCniBack(String value) => state = state.copyWith(cniBackPath: value);
  void updateSelfie(String value) => state = state.copyWith(selfiePath: value);
  void updateCarPhoto(String value) => state = state.copyWith(carPhotoPath: value);
  void updateCarBrand(String value) => state = state.copyWith(carBrand: value);
  void updateCarModel(String value) => state = state.copyWith(carModel: value);
  void updateCarYear(String value) => state = state.copyWith(carYear: value);
  void updateCarColor(String value) => state = state.copyWith(carColor: value);
  void updateCarPlate(String value) => state = state.copyWith(carPlate: value);
  void updateEmergencyContacts(List<EmergencyContact> value) => state = state.copyWith(emergencyContacts: value);
  void setSubmitting(bool value) => state = state.copyWith(isSubmitting: value);
}

class UploadController extends StateNotifier<UploadState> {
  UploadController() : super(const UploadState());

  void setUploading(bool value) => state = state.copyWith(isUploading: value);
  void setMessage(String? value) => state = state.copyWith(message: value);
  void setUploadedPath(String? value) => state = state.copyWith(uploadedPath: value);
}
