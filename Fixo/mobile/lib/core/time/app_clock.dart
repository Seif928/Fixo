import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A live clock in the app; visual tests can supply a fixed civil date.
final appNowProvider = Provider<DateTime Function()>((ref) => DateTime.now);
