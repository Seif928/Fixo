import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../firebase_options.dart';
import '../domain/auth_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/auth/platform_auth_capabilities.dart';

/// Firebase proves email ownership; NestJS alone issues FIXO roles and sessions.
class EmailAccessService {
  EmailAccessService(this.dio);
  final Dio dio;
  Future<FirebaseAuth> _auth() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return FirebaseAuth.instance;
  }

  Future<AuthSession?> signIn(
    String email,
    String password, {
    bool create = false,
  }) async {
    final auth = await _auth();
    final credential = create
        ? await auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
        : await auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
    final user = credential.user!;
    if (!user.emailVerified) {
      if (create) await user.sendEmailVerification();
      return null;
    }
    return _exchange(user);
  }

  Future<AuthSession?> checkVerification() async {
    final auth = await _auth();
    await auth.currentUser?.reload();
    final user = auth.currentUser;
    return user != null && user.emailVerified ? _exchange(user) : null;
  }

  Future<AuthSession?> signInWithGoogle() async {
    final auth = await _auth();
    UserCredential credential;
    if (kIsWeb) {
      credential = await auth.signInWithPopup(GoogleAuthProvider());
    } else {
      await GoogleSignIn.instance.initialize();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw StateError('Google identity token unavailable.');
      }
      credential = await auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    }
    final user = credential.user!;
    return user.emailVerified ? _exchange(user) : null;
  }

  Future<AuthSession?> signInWithApple() async {
    if (!appleSignInAvailable) {
      throw UnsupportedError('Apple sign-in is available in the iOS app only.');
    }
    final auth = await _auth();
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    final credential = kIsWeb
        ? await auth.signInWithPopup(provider)
        : await auth.signInWithProvider(provider);
    final user = credential.user;
    if (user == null) {
      throw StateError('Apple identity is unavailable. Please retry.');
    }
    final idToken = await user.getIdToken(true);
    if (idToken == null) throw StateError('Apple identity token unavailable.');
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/firebase/apple',
      data: {'idToken': idToken},
    );
    if (response.data == null) {
      throw StateError('Unable to establish a verified session.');
    }
    return AuthSession.fromJson(response.data!);
  }

  Future<void> resendVerification() async {
    final auth = await _auth();
    final user = auth.currentUser;
    if (user == null) throw StateError('Sign in first.');
    await user.sendEmailVerification();
  }

  Future<void> resetPassword(String email) async {
    final auth = await _auth();
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    if (Firebase.apps.isNotEmpty) await FirebaseAuth.instance.signOut();
  }

  Future<void> signOutIfCurrent(String? expectedEmail) async {
    if (Firebase.apps.isEmpty) {
      await signOut();
      return;
    }
    final current = FirebaseAuth.instance.currentUser;
    if (current == null ||
        (expectedEmail != null &&
            current.email?.toLowerCase() == expectedEmail.toLowerCase())) {
      await signOut();
    }
  }

  Future<AuthSession> signInWithPhone(String phone, String password) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/phone-password',
      data: {'phone': phone, 'password': password},
    );
    return AuthSession.fromJson(response.data!);
  }

  Future<AuthUser> completePhoneProfile(
    String name,
    String phone,
    String password,
  ) async {
    final auth = await _auth();
    final user = auth.currentUser;
    if (user == null || !user.emailVerified || user.email == null) {
      throw StateError('Sign in with your verified Google account first.');
    }
    if (user.providerData.any(
      (provider) => provider.providerId == 'password',
    )) {
      await user.updatePassword(password);
    } else {
      await user.linkWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
    }
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/first-profile',
      data: {'fullName': name.trim(), 'phone': phone},
    );
    return AuthUser.fromJson(response.data!);
  }

  Future<AuthSession> _exchange(User user) async {
    final idToken = await user.getIdToken(true);
    if (idToken == null) throw StateError('Identity token unavailable.');
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/firebase/session',
      data: {'idToken': idToken},
    );
    return AuthSession.fromJson(response.data!);
  }

  /// The provider owns the identity prompt; never collect an Apple email locally.
  Future<AuthSession?> promptAndSignInWithApple(
    BuildContext context, {
    required bool isArabic,
  }) => signInWithApple();
}

final emailAccessProvider = Provider<EmailAccessService>(
  (ref) => EmailAccessService(ref.watch(dioClientProvider)),
);
