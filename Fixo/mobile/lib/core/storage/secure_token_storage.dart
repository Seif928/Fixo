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
    for (final field in ['accessToken', 'refreshToken', 'userId']) {
      if (json[field] is! String || (json[field] as String).isEmpty) {
        throw const FormatException('Invalid stored session.');
      }
    }
    if (!const ['CUSTOMER', 'PRO', 'ADMIN'].contains(json['role'])) {
      throw const FormatException('Invalid stored session.');
    }
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
  Future<bool> replaceTokensIfCurrent(
    StoredAuthTokens? expected,
    StoredAuthTokens? replacement,
  );
}

class _TokenStorageQueue {
  Future<void> _tail = Future<void>.value();
  Future<T> run<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }
}

abstract class _SerializedTokenStorage implements SecureTokenStorage {
  _SerializedTokenStorage({_TokenStorageQueue? queue})
    : _queue = queue ?? _TokenStorageQueue();
  final _TokenStorageQueue _queue;
  Future<StoredAuthTokens?> readBackend();
  Future<void> writeBackend(StoredAuthTokens? tokens);
  @override
  Future<void> saveTokens(StoredAuthTokens tokens) =>
      _queue.run(() => writeBackend(tokens));
  @override
  Future<StoredAuthTokens?> readTokens() => _queue.run(readBackend);
  @override
  Future<String?> readAccessToken() async => (await readTokens())?.accessToken;
  @override
  Future<String?> readRefreshToken() async =>
      (await readTokens())?.refreshToken;
  @override
  Future<void> clearTokens() => _queue.run(() => writeBackend(null));
  @override
  Future<bool> replaceTokensIfCurrent(
    StoredAuthTokens? expected,
    StoredAuthTokens? replacement,
  ) => _queue.run(() async {
    final current = await readBackend();
    if (current?.userId != expected?.userId ||
        current?.accessToken != expected?.accessToken ||
        current?.refreshToken != expected?.refreshToken) {
      return false;
    }
    await writeBackend(replacement);
    return true;
  });
}

/// Platform keychain/keystore storage; no embedded encryption keys or memory fallback.
class VaultTokenStorage extends _SerializedTokenStorage {
  VaultTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(),
      super(queue: _vaultQueue);
  static final _vaultQueue = _TokenStorageQueue();
  final FlutterSecureStorage _storage;
  static const _storageKey = "fixo.auth.session.v1";
  @override
  Future<void> writeBackend(StoredAuthTokens? tokens) => tokens == null
      ? _storage.delete(key: _storageKey)
      : _storage.write(key: _storageKey, value: jsonEncode(tokens.toJson()));
  @override
  Future<StoredAuthTokens?> readBackend() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null) return null;
    try {
      return StoredAuthTokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      await _storage.delete(key: _storageKey);
      return null;
    } on TypeError {
      await _storage.delete(key: _storageKey);
      return null;
    }
  }
}

/// Explicit test fixture. Never selected by the production provider.
class MemoryTokenStorage extends _SerializedTokenStorage {
  StoredAuthTokens? _tokens;
  @override
  Future<void> writeBackend(StoredAuthTokens? tokens) async {
    _tokens = tokens;
  }

  @override
  Future<StoredAuthTokens?> readBackend() async => _tokens;
}

final secureTokenStorageProvider = Provider<SecureTokenStorage>(
  (ref) => VaultTokenStorage(),
);

/// Raised only when the server rejects the stored refresh credential.
final sessionExpiredProvider = StateProvider<int>((ref) => 0);

/// Identity currently presented by the app; stored tokens alone do not choose a UI account.
final activeSessionOwnerProvider = StateProvider<String?>((ref) => null);
