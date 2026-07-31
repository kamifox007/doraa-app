enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.message,
    this.isAuthenticated = false,
    this.userId,
  });

  final AuthStatus status;
  final String? message;
  final bool isAuthenticated;
  final String? userId;

  AuthState copyWith({
    AuthStatus? status,
    String? message,
    bool? isAuthenticated,
    String? userId,
  }) {
    return AuthState(
      status: status ?? this.status,
      message: message ?? this.message,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    this.email,
    this.fullName = '',
    this.wilaya = '',
    this.role = 'rider',
    this.verificationStatus = 'pending',
    this.verificationReviewedAt,
    this.verificationReviewedBy,
    this.avatarUrl,
  });

  final String id;
  final String? email;
  final String fullName;
  final String wilaya;
  final String role;
  final String verificationStatus;
  final DateTime? verificationReviewedAt;
  final String? verificationReviewedBy;
  final String? avatarUrl;

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? wilaya,
    String? role,
    String? verificationStatus,
    DateTime? verificationReviewedAt,
    String? verificationReviewedBy,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      wilaya: wilaya ?? this.wilaya,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationReviewedAt: verificationReviewedAt ?? this.verificationReviewedAt,
      verificationReviewedBy: verificationReviewedBy ?? this.verificationReviewedBy,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class DriverProfile {
  const DriverProfile({
    required this.userId,
    this.carBrand = '',
    this.carModel = '',
    this.carYear = '',
    this.carColor = '',
    this.carPlate = '',
    this.carPhotoUrl,
    this.vehicleApprovalStatus = 'pending',
    this.vehicleApprovedAt,
    this.vehicleApprovedBy,
    this.vehicleApprovalNotes,
    this.isOnline = false,
    this.rating = 5.0,
    this.totalRides = 0,
  });

  final String userId;
  final String carBrand;
  final String carModel;
  final String carYear;
  final String carColor;
  final String carPlate;
  final String? carPhotoUrl;
  final String vehicleApprovalStatus;
  final DateTime? vehicleApprovedAt;
  final String? vehicleApprovedBy;
  final String? vehicleApprovalNotes;
  final bool isOnline;
  final double rating;
  final int totalRides;

  DriverProfile copyWith({
    String? userId,
    String? carBrand,
    String? carModel,
    String? carYear,
    String? carColor,
    String? carPlate,
    String? carPhotoUrl,
    String? vehicleApprovalStatus,
    DateTime? vehicleApprovedAt,
    String? vehicleApprovedBy,
    String? vehicleApprovalNotes,
    bool? isOnline,
    double? rating,
    int? totalRides,
  }) {
    return DriverProfile(
      userId: userId ?? this.userId,
      carBrand: carBrand ?? this.carBrand,
      carModel: carModel ?? this.carModel,
      carYear: carYear ?? this.carYear,
      carColor: carColor ?? this.carColor,
      carPlate: carPlate ?? this.carPlate,
      carPhotoUrl: carPhotoUrl ?? this.carPhotoUrl,
      vehicleApprovalStatus: vehicleApprovalStatus ?? this.vehicleApprovalStatus,
      vehicleApprovedAt: vehicleApprovedAt ?? this.vehicleApprovedAt,
      vehicleApprovedBy: vehicleApprovedBy ?? this.vehicleApprovedBy,
      vehicleApprovalNotes: vehicleApprovalNotes ?? this.vehicleApprovalNotes,
      isOnline: isOnline ?? this.isOnline,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
    );
  }
}

class EmergencyContact {
  const EmergencyContact({
    this.name = '',
    this.phone = '',
    this.relationship = '',
    this.isPrimary = false,
  });

  final String name;
  final String phone;
  final String relationship;
  final bool isPrimary;

  EmergencyContact copyWith({
    String? name,
    String? phone,
    String? relationship,
    bool? isPrimary,
  }) {
    return EmergencyContact(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

class UploadState {
  const UploadState({
    this.isUploading = false,
    this.message,
    this.uploadedPath,
  });

  final bool isUploading;
  final String? message;
  final String? uploadedPath;

  UploadState copyWith({bool? isUploading, String? message, String? uploadedPath}) {
    return UploadState(
      isUploading: isUploading ?? this.isUploading,
      message: message ?? this.message,
      uploadedPath: uploadedPath ?? this.uploadedPath,
    );
  }
}

class RegistrationState {
  const RegistrationState({
    this.phone = '',
    this.otp = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.fullName = '',
    this.wilaya = '',
    this.role = 'rider',
    this.cniFrontPath,
    this.cniBackPath,
    this.selfiePath,
    this.carPhotoPath,
    this.carBrand = '',
    this.carModel = '',
    this.carYear = '',
    this.carColor = '',
    this.carPlate = '',
    this.emergencyContacts = const [],
    this.isSubmitting = false,
  });

  final String phone;
  final String otp;
  final String email;
  final String password;
  final String confirmPassword;
  final String fullName;
  final String wilaya;
  final String role;
  final String? cniFrontPath;
  final String? cniBackPath;
  final String? selfiePath;
  final String? carPhotoPath;
  final String carBrand;
  final String carModel;
  final String carYear;
  final String carColor;
  final String carPlate;
  final List<EmergencyContact> emergencyContacts;
  final bool isSubmitting;

  RegistrationState copyWith({
    String? phone,
    String? otp,
    String? email,
    String? password,
    String? confirmPassword,
    String? fullName,
    String? wilaya,
    String? role,
    String? cniFrontPath,
    String? cniBackPath,
    String? selfiePath,
    String? carPhotoPath,
    String? carBrand,
    String? carModel,
    String? carYear,
    String? carColor,
    String? carPlate,
    List<EmergencyContact>? emergencyContacts,
    bool? isSubmitting,
  }) {
    return RegistrationState(
      phone: phone ?? this.phone,
      otp: otp ?? this.otp,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      fullName: fullName ?? this.fullName,
      wilaya: wilaya ?? this.wilaya,
      role: role ?? this.role,
      cniFrontPath: cniFrontPath ?? this.cniFrontPath,
      cniBackPath: cniBackPath ?? this.cniBackPath,
      selfiePath: selfiePath ?? this.selfiePath,
      carPhotoPath: carPhotoPath ?? this.carPhotoPath,
      carBrand: carBrand ?? this.carBrand,
      carModel: carModel ?? this.carModel,
      carYear: carYear ?? this.carYear,
      carColor: carColor ?? this.carColor,
      carPlate: carPlate ?? this.carPlate,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
