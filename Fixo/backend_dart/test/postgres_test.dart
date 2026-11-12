import 'dart:io';
import 'package:fixo_backend/infrastructure/postgres_catalog.dart';
import 'package:test/test.dart';

void main() {
  test(
    'reads only explicit local fixo_test through the real PostgreSQL driver',
    () async {
      final url = Platform.environment['TEST_DATABASE_URL'];
      if (url == null) fail('Explicit TEST_DATABASE_URL required.');
      final uri = Uri.parse(url);
      expect(['postgres', 'postgresql'], contains(uri.scheme));
      expect(['localhost', '127.0.0.1'], contains(uri.host));
      expect(uri.port, 5432);
      expect(uri.path, '/fixo_test');
      final db = await PostgresCatalog.open(url);
      try {
        expect(await db.ping(), true);
        final snapshot = await db.categories();
        expect(
          snapshot.categories.map((e) => e.id).toSet().length,
          snapshot.categories.length,
        );
        expect(
          snapshot.zones.map((e) => e.id).toSet().length,
          snapshot.zones.length,
        );
      } finally {
        await db.close();
      }
    },
    skip: Platform.environment['FIXO_DART_DB_TEST'] != 'true',
  );
}
