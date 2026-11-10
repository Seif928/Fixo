import 'dart:convert';
import 'package:fixo_backend/domain/catalog.dart';
import 'package:fixo_backend/presentation/api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class CatalogFixture implements CatalogRepository, DatabaseProbe {
  bool available = true;
  @override
  Future<bool> ping() async => available;
  @override
  Future<CatalogSnapshot> categories() async {
    if (!available) throw StateError('PRIVATE DATABASE DETAILS');
    return CatalogSnapshot(categories: [], zones: []);
  }
}

void main() {
  late CatalogFixture fixture;
  late Handler api;
  setUp(() {
    fixture = CatalogFixture();
    api = createApi(fixture, fixture);
  });
  test(
    'live health reflects the database rather than fabricating persistence',
    () async {
      fixture.available = false;
      final response = await api(
        Request('GET', Uri.parse('http://localhost/api/v1/health')),
      );
      final data = jsonDecode(await response.readAsString());
      expect(response.statusCode, 200);
      expect(data['persistence']['databaseConnected'], false);
      expect(data['persistence']['storageMode'], 'UNAVAILABLE');
    },
  );
  test('incomplete migration never claims production readiness', () async {
    final response = await api(
      Request('GET', Uri.parse('http://localhost/api/v1/health/ready')),
    );
    expect(response.statusCode, 503);
    expect(
      jsonDecode(await response.readAsString())['code'],
      'MIGRATION_INCOMPLETE',
    );
  });
  test(
    'category response preserves real empty collections and metadata',
    () async {
      final response = await api(
        Request(
          'GET',
          Uri.parse('http://localhost/api/v1/services/categories'),
        ),
      );
      final data = jsonDecode(await response.readAsString());
      expect(response.statusCode, 200);
      expect(data['categories'], isEmpty);
      expect(data['zones'], isEmpty);
      expect(data['meta']['currency'], 'EGP');
      expect(data['meta']['storageMode'], 'POSTGRESQL_PRISMA');
    },
  );
  test('database errors fail closed without leaking private details', () async {
    fixture.available = false;
    final response = await api(
      Request('GET', Uri.parse('http://localhost/api/v1/services/categories')),
    );
    expect(response.statusCode, 503);
    expect(
      await response.readAsString(),
      isNot(contains('PRIVATE DATABASE DETAILS')),
    );
  });
  test('unported auth is unavailable, never a synthetic session', () async {
    final response = await api(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/auth/firebase/session'),
      ),
    );
    expect(response.statusCode, 404);
  });
  test('category writes are not accepted by the read-only port', () async {
    final response = await api(
      Request('POST', Uri.parse('http://localhost/api/v1/services/categories')),
    );
    expect(response.statusCode, 405);
  });
}
