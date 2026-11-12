import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:fixo_mobile/core/auth/platform_auth_capabilities.dart';
import 'package:fixo_mobile/features/auth/data/email_access_service.dart';

void main() {
  for (final platform in TargetPlatform.values) {
    test('Apple visibility policy for $platform', () {
      expect(
        allowsAppleSignIn(isWeb: false, platform: platform),
        platform == TargetPlatform.iOS,
      );
      expect(allowsAppleSignIn(isWeb: true, platform: platform), false);
    });
  }
  test(
    'unsupported calls stop before initializing Firebase or opening OAuth',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await expectLater(
        EmailAccessService(Dio()).signInWithApple(),
        throwsUnsupportedError,
      );
    },
  );
}
