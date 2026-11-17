import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercise the fonts shipped to users, not the Ahem rectangle test font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final entry in {
    'Cairo': 'assets/fonts/cairo/Cairo.ttf',
    'Manrope': 'assets/fonts/manrope/Manrope.ttf',
    'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    'packages/cupertino_icons/CupertinoIcons':
        'packages/cupertino_icons/assets/CupertinoIcons.ttf',
  }.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
  await testMain();
}
