import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';

const _old = StoredAuthTokens(
  accessToken: 'old',
  refreshToken: 'old-refresh',
  userId: 'a',
  phone: '',
  role: 'CUSTOMER',
);
const _rotated = StoredAuthTokens(
  accessToken: 'rotated',
  refreshToken: 'new-refresh',
  userId: 'a',
  phone: '',
  role: 'CUSTOMER',
);
const _other = StoredAuthTokens(
  accessToken: 'b-token',
  refreshToken: 'b-refresh',
  userId: 'b',
  phone: '',
  role: 'CUSTOMER',
);

class _DelayedVault extends FlutterSecureStorage {
  String? data;
  bool pauseRotatedWrite = false, pauseDelete = false;
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (pauseRotatedWrite &&
        value != null &&
        jsonDecode(value)['accessToken'] == 'rotated') {
      entered.complete();
      await release.future;
    }
    data = value;
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => data;
  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (pauseDelete) {
      entered.complete();
      await release.future;
    }
    data = null;
  }
}

void main() {
  test(
    'a delayed refresh write cannot finish over a newer account sign-in',
    () async {
      final plugin = _DelayedVault()..pauseRotatedWrite = true;
      final storage = VaultTokenStorage(storage: plugin);
      await storage.saveTokens(_old);
      final stale = storage.saveTokens(_rotated);
      await plugin.entered.future;
      final current = storage.saveTokens(_other);
      await Future<void>.delayed(Duration.zero);
      plugin.release.complete();
      await Future.wait([stale, current]);
      expect((await storage.readTokens())?.userId, 'b');
    },
  );
  test(
    'a delayed old-session clear cannot delete a newer account sign-in',
    () async {
      final plugin = _DelayedVault()..pauseDelete = true;
      final storage = VaultTokenStorage(storage: plugin);
      await storage.saveTokens(_old);
      final stale = storage.clearTokens();
      await plugin.entered.future;
      final current = storage.saveTokens(_other);
      await Future<void>.delayed(Duration.zero);
      plugin.release.complete();
      await Future.wait([stale, current]);
      expect((await storage.readTokens())?.userId, 'b');
    },
  );
  test(
    'compare-and-swap never replaces or removes another account or a newer token',
    () async {
      final storage = MemoryTokenStorage();
      await storage.saveTokens(_other);
      expect(await storage.replaceTokensIfCurrent(_old, _rotated), isFalse);
      expect(await storage.replaceTokensIfCurrent(_old, null), isFalse);
      expect((await storage.readTokens())?.userId, 'b');
      await storage.saveTokens(_rotated);
      expect(await storage.replaceTokensIfCurrent(_old, null), isFalse);
      expect(await storage.replaceTokensIfCurrent(_rotated, null), isTrue);
      expect(await storage.readTokens(), isNull);
    },
  );
}
