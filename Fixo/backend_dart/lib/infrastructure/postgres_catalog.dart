import 'package:postgres/postgres.dart';
import '../domain/catalog.dart';

/// Read-only first migration slice. Never seeds or changes the live schema.
final class PostgresCatalog implements CatalogRepository, DatabaseProbe {
  PostgresCatalog._(this.connection);
  final Connection connection;

  static Future<PostgresCatalog> open(String databaseUrl) async {
    final uri = Uri.parse(databaseUrl);
    if (!['postgresql', 'postgres'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.path.length < 2) {
      throw ArgumentError('A PostgreSQL DATABASE_URL is required.');
    }
    final local = ['localhost', '127.0.0.1', '::1'].contains(uri.host);
    if (uri.queryParameters['schema'] != null &&
        uri.queryParameters['schema'] != 'public') {
      throw ArgumentError(
        'Only the existing public database schema is supported.',
      );
    }
    final parameters = Map<String, String>.from(uri.queryParameters)
      ..remove('schema');
    final configured = uri.replace(
      queryParameters: {
        ...parameters,
        'sslmode': local ? 'disable' : 'verify-full',
        'connect_timeout': '5',
        'query_timeout': '5',
      },
    );
    return PostgresCatalog._(
      await Connection.openFromUrl(configured.toString()),
    );
  }

  @override
  Future<bool> ping() async {
    try {
      await connection.execute('SELECT 1');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<CatalogSnapshot> categories() => connection.runTx((tx) async {
    await tx.execute('SET TRANSACTION READ ONLY');
    final rows = await tx.execute(
      'SELECT "id", "slug", "nameEn", "nameAr", "subtitleEn", "subtitleAr", "iconName", "startingPriceEgp", "sortOrder" FROM "ServiceCategory" WHERE "isActive" = true ORDER BY "sortOrder" ASC',
    );
    final zones = await tx.execute(
      'SELECT "id", "slug", "nameEn", "nameAr", "governorate" FROM "CoverageZone" WHERE "isActive" = true',
    );
    return CatalogSnapshot(
      categories: rows.map((r) {
        final m = r.toColumnMap();
        return Category(
          id: m['id'] as String,
          slug: m['slug'] as String,
          nameEn: m['nameEn'] as String,
          nameAr: m['nameAr'] as String,
          subtitleEn: m['subtitleEn'] as String,
          subtitleAr: m['subtitleAr'] as String,
          iconName: m['iconName'] as String,
          startingPriceEgp: m['startingPriceEgp'] as int,
          sortOrder: m['sortOrder'] as int,
        );
      }).toList(),
      zones: zones.map((r) {
        final m = r.toColumnMap();
        return Zone(
          id: m['id'] as String,
          slug: m['slug'] as String,
          nameEn: m['nameEn'] as String,
          nameAr: m['nameAr'] as String,
          governorate: m['governorate'] as String,
        );
      }).toList(),
    );
  });

  Future<void> close() => connection.close();
}
