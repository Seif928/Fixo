import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/chat/data/communications_repository.dart';
import 'package:fixo_mobile/features/chat/presentation/notification_sheet.dart';

class NotificationFixture extends CommunicationsRepository {
  NotificationFixture() : super(Dio());
  bool fail = true;
  @override
  Future<List<Map<String, dynamic>>> notifications() async {
    if (fail) throw Exception('Test network failure');
    return [];
  }
}
void main() {
  testWidgets('notification errors remain visible and retry shows a genuine empty feed', (tester) async {
    final repository = NotificationFixture();
    await tester.pumpWidget(ProviderScope(overrides: [communicationsRepositoryProvider.overrideWithValue(repository)], child: MaterialApp(theme: FixoTheme.light(), home: const Scaffold(body: NotificationSheet()))));
    await tester.pumpAndSettle();
    expect(find.text('Could not load alerts. Retry.'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Could not load alerts. Retry.'));
    await tester.pumpAndSettle();
    expect(find.text('No alerts yet.'), findsOneWidget);
    expect(find.textContaining('Hassan'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
