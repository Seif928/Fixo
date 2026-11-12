import 'package:flutter/foundation.dart';

bool allowsAppleSignIn({
  required bool isWeb,
  required TargetPlatform platform,
}) => !isWeb && platform == TargetPlatform.iOS;

bool get appleSignInAvailable =>
    allowsAppleSignIn(isWeb: kIsWeb, platform: defaultTargetPlatform);
