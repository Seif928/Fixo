import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Returns `true` when the user dismissed a browser sign-in popup deliberately.
bool isCancelledAuthError(Object error) =>
    error is FirebaseAuthException &&
    const [
      'popup-closed-by-user',
      'cancelled-popup-request',
    ].contains(error.code);

/// Maps Firebase Auth, Google Sign-In, and FIXO API errors into clear bilingual
/// user-facing messages while preserving existing test contract wording.
String formatAuthErrorMessage(
  Object error, {
  required bool isArabic,
  bool forPhonePassword = false,
}) {
  if (error is GoogleSignInException) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return isArabic
            ? 'تم إلغاء تسجيل الدخول بحساب Google.'
            : 'Google sign-in was cancelled.';
      case GoogleSignInExceptionCode.uiUnavailable:
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.clientConfigurationError:
        return isArabic
            ? 'تعذر فتح نافذة Google على هذا الجهاز. تأكد من خدمات Google Play وحاول مجددًا.'
            : 'Google Sign-In is unavailable on this device. Check Google Play services and retry.';
      default:
        return isArabic
            ? 'تعذر إتمام الدخول بحساب Google (${error.code.name}).'
            : 'Could not complete Google sign-in (${error.code.name}).';
    }
  }

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'popup-blocked':
        return isArabic
            ? 'اسمح بنافذة جوجل المنبثقة من إعدادات المتصفح، ثم حاول مجددًا.'
            : 'Allow the Google popup in your browser, then try again.';
      case 'auth-not-ready':
        return isArabic
            ? 'جارٍ الاتصال بجوجل. حاول بعد لحظة.'
            : 'Google is still connecting. Try again in a moment.';
      case 'invalid-email':
        return isArabic
            ? 'صيغة البريد الإلكتروني غير صحيحة.'
            : 'Enter a valid email address.';
      case 'email-already-in-use':
        return isArabic
            ? 'البريد مستخدم بالفعل. سجّل الدخول أو استعد كلمة المرور.'
            : 'Email already registered. Sign in or reset your password.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return isArabic
            ? 'بيانات الدخول غير صحيحة. تأكد من البريد وكلمة المرور أو اختر إنشاء حساب جديد.'
            : 'Invalid sign-in details. Check your email/password or create a new account.';
      case 'too-many-requests':
        return isArabic
            ? 'محاولات كثيرة. انتظر قليلًا ثم حاول مجددًا.'
            : 'Too many attempts. Wait before retrying.';
      case 'weak-password':
        return isArabic
            ? 'اختر كلمة مرور أقوى (12 حرفًا على الأقل).'
            : 'Choose a stronger password (at least 12 characters).';
      case 'operation-not-allowed':
      case 'admin-restricted-operation':
        return isArabic
            ? 'طريقة الدخول غير مفعلة حاليًا في إعدادات Firebase.'
            : 'This sign-in method is not enabled in Firebase configuration.';
      case 'network-request-failed':
        return isArabic
            ? 'تعذر الاتصال بخوادم Firebase. تأكد من الإنترنت أو DNS الجهاز.'
            : 'Could not reach Firebase authentication servers. Check internet and DNS.';
      case 'user-disabled':
        return isArabic
            ? 'تم إيقاف هذا الحساب مؤقتًا.'
            : 'This account has been disabled.';
      case 'requires-recent-login':
        return isArabic
            ? 'يلزم تأكيد الدخول من جديد قبل إتمام هذا الإجراء.'
            : 'Please sign in again before completing this action.';
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return isArabic
            ? 'هذا البريد مرتبط بطريقة دخول أخرى بالفعل.'
            : 'This email is already linked to another sign-in method.';
      default:
        return isArabic
            ? 'تعذر إتمام التسجيل عبر Firebase (${error.code}).'
            : 'Firebase authentication error (${error.code}).';
    }
  }

  if (error is DioException) {
    final status = error.response?.statusCode;
    final path = error.requestOptions.path;
    if (status == 401) {
      if (path == '/auth/phone-password') {
        return isArabic
            ? 'رقم الموبايل أو كلمة المرور غير صحيحة. راجعهم أو استخدم «نسيت كلمة المرور؟».'
            : 'Incorrect phone number or password. Check both or use "Forgot password?".';
      }
      if (forPhonePassword) {
        return isArabic
            ? 'تعذّر التحقق من تسجيل الدخول. تابع بحساب جوجل وحاول مرة أخرى.'
            : 'Your sign-in could not be verified. Continue with Google and try again.';
      }
      final serverMsg = error.response?.data is Map
          ? (error.response!.data as Map)['message']?.toString() ?? ''
          : '';
      if (serverMsg.toLowerCase().contains('verify your email')) {
        return isArabic
            ? 'يرجى تأكيد بريدك الإلكتروني أولًا قبل تسجيل الدخول.'
            : 'Please verify your email address before signing in.';
      }
      return isArabic
          ? 'تعذّر التحقق من الجلسة. حاول تسجيل الدخول مجددًا.'
          : 'Your sign-in could not be verified. Please try again.';
    }
    if (status == 409) {
      if (path == '/auth/firebase/session') {
        return forPhonePassword
            ? (isArabic
                  ? 'البريد ده مرتبط بطريقة دخول تانية. استخدم حسابك الأصلي للمتابعة.'
                  : 'This Google email already uses another sign-in method. Use the original account to continue.')
            : (isArabic
                  ? 'البريد مرتبط بحساب سابق؛ يلزم تسجيل الدخول بالطريقة الأصلية لربطه.'
                  : 'This email belongs to an existing account. Sign in using the original method to link it.');
      }
      return isArabic
          ? 'تعذّر استخدام هذا الرقم لهذا الحساب. جرّب رقمك الآخر أو حسابك الأصلي.'
          : 'This phone cannot be used for this account. Use your other number or original account.';
    }
    if (status == 503) {
      return isArabic
          ? 'خادم التسجيل غير متاح مؤقتًا. حاول بعد قليل.'
          : 'Authentication service is temporarily unavailable. Please retry shortly.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return isArabic
          ? 'تعذر الوصول إلى خادم FIXO. تأكد من اتصال الإنترنت وحاول مجددًا.'
          : 'Could not reach the FIXO server. Check your internet connection and retry.';
    }
  }

  if (error is PlatformException) {
    return isArabic
        ? 'تعذر إتمام التحقق عبر الجهاز (${error.code}).'
        : 'Device sign-in error (${error.code}).';
  }

  if (error is StateError) {
    final msg = error.message;
    if (msg.contains('Verified Google identity required')) {
      return isArabic
          ? 'يرجى تأكيد حسابك عبر Google أولًا.'
          : 'Please verify your Google account first.';
    }
  }

  return isArabic
      ? 'تعذّر إكمال الطلب. تحقق من الاتصال وحاول مرة أخرى.'
      : 'Could not complete the request. Check your connection and retry.';
}
