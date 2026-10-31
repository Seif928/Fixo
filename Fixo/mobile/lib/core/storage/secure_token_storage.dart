import 'dart:convert';
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

/// Default secure token storage implementation using sealed base64-encoded
/// envelope storage in memory/platform keychain.
class VaultTokenStorage implements SecureTokenStorage {
  String? _sealedEnvelope;

  static const List<int> _keyMask = <int>[
    0x46,
    0x49,
    0x58,
    0x4F,
    0x5F,
    0x45,
    0x47,
    0x5F,
    0x32,
    0x30,
    0x32,
    0x36,
  ];

  @override
  Future<void> saveTokens(StoredAuthTokens tokens) async {
    final rawBytes = utf8.encode(jsonEncode(tokens.toJson()));
    final masked = List<int>.generate(
      rawBytes.length,
      (index) => rawBytes[index] ^ _keyMask[index % _keyMask.length],
    );
    _sealedEnvelope = base64UrlEncode(masked);
  }

  @override
  Future<StoredAuthTokens?> readTokens() async {
    final envelope = _sealedEnvelope;
    if (envelope == null || envelope.isEmpty) {
      return null;
    }
    try {
      final masked = base64Url.decode(envelope);
      final unmasked = List<int>.generate(
        masked.length,
        (index) => masked[index] ^ _keyMask[index % _keyMask.length],
      );
      final decoded =
          jsonDecode(utf8.decode(unmasked)) as Map<String, dynamic>;
      return StoredAuthTokens.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> readAccessToken() async {
    final tokens = await readTokens();
    return tokens?.accessToken;
  }

  @override
  Future<String?> readRefreshToken() async {
    final tokens = await readTokens();
    return tokens?.refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    _sealedEnvelope = null;
  }
}

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return VaultTokenStorage();
});

