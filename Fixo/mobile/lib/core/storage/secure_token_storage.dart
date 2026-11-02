import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stored authentication token bundle persisted securely across sessions.
class StoredAuthTokens {
  const StoredAuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.phone,
    required this.role,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String phone;
  final String role;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'userId': userId,
    'phone': phone,
    'role': role,
  };

  factory StoredAuthTokens.fromJson(Map<String, dynamic> json) {
    return StoredAuthTokens(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'CUSTOMER',
    );
  }
}

/// Abstract contract for secure JWT token storage.
abstract class SecureTokenStorage {
  Future<void> saveTokens(StoredAuthTokens tokens);
  Future<StoredAuthTokens?> readTokens();
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> clearTokens();
}

/// Platform keychain/keystore storage; no embedded encryption keys or memory fallback.
class VaultTokenStorage implements SecureTokenStorage {
  VaultTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _storageKey = "fixo.auth.session.v1";
  @override
  Future<void> saveTokens(StoredAuthTokens tokens) =>
      _storage.write(key: _storageKey, value: jsonEncode(tokens.toJson()));
  @override
  Future<StoredAuthTokens?> readTokens() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null) return null;
    try {
      return StoredAuthTokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      await clearTokens();
      return null;
    }
  }

  @override
  Future<String?> readAccessToken() async => (await readTokens())?.accessToken;
  @override
  Future<String?> readRefreshToken() async =>
      (await readTokens())?.refreshToken;
  @override
  Future<void> clearTokens() => _storage.delete(key: _storageKey);
}

/// Explicit test fixture. Never selected by the production provider.
class MemoryTokenStorage implements SecureTokenStorage {
  StoredAuthTokens? _tokens;
  @override
  Future<void> saveTokens(StoredAuthTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<StoredAuthTokens?> readTokens() async => _tokens;
  @override
  Future<String?> readAccessToken() async => _tokens?.accessToken;
  @override
  Future<String?> readRefreshToken() async => _tokens?.refreshToken;
  @override
  Future<void> clearTokens() async {
    _tokens = null;
  }
}

final secureTokenStorageProvider = Provider<SecureTokenStorage>(
  (ref) => VaultTokenStorage(),
);

/// Raised only when the server rejects the stored refresh credential.
final sessionExpiredProvider = StateProvider<int>((ref) => 0);
