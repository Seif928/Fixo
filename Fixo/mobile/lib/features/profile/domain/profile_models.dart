import '../../auth/domain/auth_models.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
    this.email,
    this.preferredLocale = 'en',
    this.rewardPoints = 0,
    this.requiresProfileSetup = false,
    this.hasAvatar = false,
    this.avatarVersion,
    this.arrivalAlertsEnabled = false,
    this.addresses = const <Map<String, dynamic>>[],
  });

  final String id;
  final String phone;
  final String fullName;
  final String role;
  final String? email;
  final String preferredLocale;
  final int rewardPoints;
  final bool requiresProfileSetup;
  final bool hasAvatar;
  final String? avatarVersion;
  final bool arrivalAlertsEnabled;
  final List<Map<String, dynamic>> addresses;

  bool get isPro => role == 'PRO';
  bool get isAdmin => role == 'ADMIN';
  bool get isCustomer => role == 'CUSTOMER';

  dynamic operator [](String key) {
    switch (key) {
      case 'id':
        return id;
      case 'phone':
        return phone;
      case 'fullName':
        return fullName;
      case 'role':
        return role;
      case 'email':
        return email;
      case 'preferredLocale':
        return preferredLocale;
      case 'rewardPoints':
        return rewardPoints;
      case 'requiresProfileSetup':
        return requiresProfileSetup;
      case 'hasAvatar':
        return hasAvatar;
      case 'avatarVersion':
        return avatarVersion;
      case 'arrivalAlertsEnabled':
        return arrivalAlertsEnabled;
      case 'addresses':
        return addresses;
      default:
        return null;
    }
  }

  UserProfile copyWith({
    String? id,
    String? phone,
    String? fullName,
    String? role,
    String? email,
    String? preferredLocale,
    int? rewardPoints,
    bool? requiresProfileSetup,
    bool? hasAvatar,
    String? avatarVersion,
    bool? arrivalAlertsEnabled,
    List<Map<String, dynamic>>? addresses,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      email: email ?? this.email,
      preferredLocale: preferredLocale ?? this.preferredLocale,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      requiresProfileSetup: requiresProfileSetup ?? this.requiresProfileSetup,
      hasAvatar: clearAvatar ? false : (hasAvatar ?? this.hasAvatar),
      avatarVersion: clearAvatar ? null : (avatarVersion ?? this.avatarVersion),
      arrivalAlertsEnabled: arrivalAlertsEnabled ?? this.arrivalAlertsEnabled,
      addresses: addresses ?? this.addresses,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Support both wrapped { "user": { ... } } and raw flat map { "id": ... }
    final data = (json['user'] is Map)
        ? Map<String, dynamic>.from(json['user'] as Map)
        : json;

    return UserProfile(
      id: data['id'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      fullName: (data['fullName'] as String?)?.trim().isNotEmpty == true
          ? data['fullName'] as String
          : '',
      role: data['role'] as String? ?? 'CUSTOMER',
      email: data['email'] as String?,
      preferredLocale: data['preferredLocale'] as String? ?? 'en',
      rewardPoints: (data['rewardPoints'] as num?)?.toInt() ?? 0,
      requiresProfileSetup: data['requiresProfileSetup'] == true,
      hasAvatar: data['hasAvatar'] == true,
      avatarVersion: data['avatarVersion'] as String?,
      arrivalAlertsEnabled: data['arrivalAlertsEnabled'] == true,
      addresses: (data['addresses'] as List<dynamic>?)
              ?.whereType<Map<dynamic, dynamic>>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList() ??
          const <Map<String, dynamic>>[],
    );
  }

  AuthUser toAuthUser() => AuthUser(
    id: id,
    phone: phone,
    fullName: fullName,
    role: role,
    email: email,
    preferredLocale: preferredLocale,
    rewardPoints: rewardPoints,
    requiresProfileSetup: requiresProfileSetup,
    hasAvatar: hasAvatar,
    avatarVersion: avatarVersion,
  );

  factory UserProfile.fromAuthUser(
    AuthUser user, {
    bool arrivalAlertsEnabled = false,
    List<Map<String, dynamic>> addresses = const [],
  }) => UserProfile(
    id: user.id,
    phone: user.phone,
    fullName: user.fullName,
    role: user.role,
    email: user.email,
    preferredLocale: user.preferredLocale,
    rewardPoints: user.rewardPoints,
    requiresProfileSetup: user.requiresProfileSetup,
    hasAvatar: user.hasAvatar,
    avatarVersion: user.avatarVersion,
    arrivalAlertsEnabled: arrivalAlertsEnabled,
    addresses: addresses,
  );
}
