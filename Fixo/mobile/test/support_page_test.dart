import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';
import 'package:fixo_mobile/features/support/support_repository.dart';
import 'package:fixo_mobile/features/support/support_page.dart';

class FakeSupport extends SupportRepository {
  FakeSupport() : super(Dio());
  bool fail = false;
  bool closed = false;
  @override
  Future<void> close(String thread) async {
    closed = true;
  }

  @override
  Future<String> create(String subject, String body) async => 'thread';
  final sent = <String>[];
  @override
  Future<List<Map<String, dynamic>>> list({
    bool admin = false,
    String? thread,
  }) async => thread == null
      ? [
          {'id': 'thread', 'subject': 'Question', 'updatedAt': '2026-11-09'},
        ]
      : [
          {'body': 'How can we help?', 'fromAdmin': true},
        ];
  @override
  Future<void> send(String thread, String body, {bool admin = false}) async {
    if (fail) throw Exception('Offline');
    sent.add(body);
  }
}

void main() {
  testWidgets(
    'support opens a conversation and preserves unsent text after failure',
    (tester) async {
      final repo = FakeSupport();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportRepositoryProvider.overrideWithValue(repo),
            secureTokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          ],
          child: const MaterialApp(home: SupportPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Question'));
      await tester.pumpAndSettle();
      expect(find.text('FIXO support'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'My question');
      repo.fail = true;
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();
      expect(find.text('My question'), findsOneWidget);
      expect(repo.sent, isEmpty);
      repo.fail = false;
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();
      expect(repo.sent, ['My question']);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Question'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('administrator can close a conversation from its toolbar', (
    tester,
  ) async {
    final repo = FakeSupport();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWithValue(repo),
          secureTokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
        ],
        child: const MaterialApp(home: SupportPage(admin: true)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Question'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close conversation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(repo.closed, isTrue);
    expect(find.text('Question'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
