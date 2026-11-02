import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('sessions persist across storage instances and sign-out deletes them', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final first = VaultTokenStorage();
    await first.saveTokens(const StoredAuthTokens(accessToken: 'TEST-ACCESS', refreshToken: 'TEST-REFRESH', userId: 'test-user', phone: '', role: 'CUSTOMER'));
    final next = VaultTokenStorage();
    expect(await next.readAccessToken(), 'TEST-ACCESS');
    await next.clearTokens();
    expect(await first.readTokens(), isNull);
  });
}
