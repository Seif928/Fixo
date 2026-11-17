import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/features/auth/data/email_access_service.dart';

class GoogleAuthFixture implements FirebaseAuth {
  int popups = 0;
  Object? popupError;
  @override
  Stream<User?> authStateChanges() => Stream.value(null);
  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) {
    popups++;
    return popupError == null
        ? Future.value(GoogleCredentialFixture())
        : Future.error(popupError!);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class GoogleCredentialFixture implements UserCredential {
  @override
  User get user => UnverifiedGoogleFixture();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class UnverifiedGoogleFixture implements User {
  @override
  bool get emailVerified => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('cold Web calls do not defer a popup past the user gesture', () async {
    final auth = GoogleAuthFixture();
    final service = EmailAccessService(
      Dio(),
      isWeb: true,
      authInitializer: () async => auth,
    );
    await expectLater(
      service.signInWithGoogle(),
      throwsA(
        isA<FirebaseAuthException>().having(
          (e) => e.code,
          'code',
          'auth-not-ready',
        ),
      ),
    );
    expect(auth.popups, 0);
  });
  test(
    'preparation is coalesced and a ready popup opens synchronously on the first click',
    () async {
      final auth = GoogleAuthFixture();
      final gate = Completer<FirebaseAuth>();
      var preparations = 0;
      final service = EmailAccessService(
        Dio(),
        isWeb: true,
        authInitializer: () {
          preparations++;
          return gate.future;
        },
      );
      final first = service.prepareGoogle();
      final second = service.prepareGoogle();
      expect(preparations, 1);
      gate.complete(auth);
      await Future.wait([first, second]);
      final result = service.signInWithGoogle();
      expect(
        auth.popups,
        1,
        reason:
            'No initialization await may precede opening a prepared Web popup.',
      );
      expect(
        await result,
        isNull,
        reason:
            'Unverified identities never receive a fabricated FIXO session.',
      );
    },
  );
  test(
    'failed initialization is retryable without opening an identity prompt',
    () async {
      final auth = GoogleAuthFixture();
      var attempts = 0;
      final service = EmailAccessService(
        Dio(),
        isWeb: true,
        authInitializer: () async {
          if (++attempts == 1) throw StateError('offline');
          return auth;
        },
      );
      await expectLater(service.prepareGoogle(), throwsStateError);
      await service.prepareGoogle();
      final result = service.signInWithGoogle();
      expect(auth.popups, 1);
      await result;
      expect(attempts, 2);
    },
  );
  test(
    'cancelled/blocked popup is not retried or turned into a local session',
    () async {
      final auth = GoogleAuthFixture()
        ..popupError = FirebaseAuthException(code: 'popup-closed-by-user');
      final service = EmailAccessService(
        Dio(),
        isWeb: true,
        authInitializer: () async => auth,
      );
      await service.prepareGoogle();
      await expectLater(
        service.signInWithGoogle(),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(auth.popups, 1);
    },
  );
}
