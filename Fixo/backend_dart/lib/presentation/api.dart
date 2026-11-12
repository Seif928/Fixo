import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../domain/catalog.dart';
import '../application/list_categories.dart';

Response _json(int status, Map<String, Object?> value) => Response(
  status,
  body: jsonEncode(value),
  headers: {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    'x-content-type-options': 'nosniff',
  },
);

Handler createApi(CatalogRepository catalog, DatabaseProbe database) {
  final list = ListCategories(catalog);
  return (request) async {
    final path = request.url.path;
    if (![
      'api/v1/health',
      'api/v1/health/ready',
      'api/v1/services/categories',
    ].contains(path)) {
      return _json(404, {'statusCode': 404, 'message': 'Route not migrated.'});
    }
    if (request.method != 'GET')
      return _json(405, {'message': 'Method not allowed.'});
    try {
      if (path == 'api/v1/health') {
        final connected = await database.ping();
        return _json(200, {
          'status': 'ok',
          'service': 'fixo-backend',
          'market': 'EG',
          'currency': 'EGP',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'persistence': {
            'storageMode': connected ? 'POSTGRESQL_PRISMA' : 'UNAVAILABLE',
            'databaseConnected': connected,
          },
        });
      }
      if (path == 'api/v1/health/ready') {
        // Deliberate cutover gate: a read-only slice cannot replace the full API.
        return _json(503, {
          'status': 'not_ready',
          'code': 'MIGRATION_INCOMPLETE',
          'service': 'fixo-backend',
        });
      }
      final data = await list();
      return _json(200, {
        'categories': data.categories
            .map(
              (c) => {
                'id': c.id,
                'slug': c.slug,
                'nameEn': c.nameEn,
                'nameAr': c.nameAr,
                'subtitleEn': c.subtitleEn,
                'subtitleAr': c.subtitleAr,
                'iconName': c.iconName,
                'startingPriceEgp': c.startingPriceEgp,
                'sortOrder': c.sortOrder,
                'isActive': true,
              },
            )
            .toList(),
        'zones': data.zones
            .map(
              (z) => {
                'id': z.id,
                'slug': z.slug,
                'nameEn': z.nameEn,
                'nameAr': z.nameAr,
                'governorate': z.governorate,
                'isActive': true,
              },
            )
            .toList(),
        // Keep this legacy wire value until the client contract can be versioned.
        // Persistence is direct PostgreSQL; the Dart implementation does not use Prisma.
        'meta': {
          'total': data.categories.length,
          'currency': 'EGP',
          'market': 'EG',
          'storageMode': 'POSTGRESQL_PRISMA',
          'databaseConnected': true,
        },
      });
    } catch (_) {
      return _json(503, {
        'statusCode': 503,
        'message': 'Database unavailable. Please retry.',
      });
    }
  };
}
