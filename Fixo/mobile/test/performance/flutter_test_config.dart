import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../flutter_test_config.dart' as shared;

// Production-path regressions must not silently disable the effects under test.
class ProductionMotionBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  Type get runtimeType => WidgetsFlutterBinding;
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  ProductionMotionBinding();
  await shared.testExecutable(testMain);
}
