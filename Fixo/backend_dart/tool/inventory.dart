import 'dart:io';

/// Migration checklist only. Legacy TypeScript is not imported by the Dart server.
void main() {
  final files =
      Directory('../backend/src/modules')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.controller.ts'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final controller = RegExp(r'''@Controller\(\s*(?:'([^']*)')?\s*\)''');
  final route = RegExp(
    r'''@(Get|Post|Put|Patch|Delete)\(\s*(?:'([^']*)')?\s*\)''',
  );
  const migrated = {
    'GET /api/v1/health',
    'GET /api/v1/health/ready',
    'GET /api/v1/services/categories',
  };
  final lines = <String>[
    '# Dart API migration route checklist',
    '',
    'Generated from legacy decorators; manually confirm dynamic/implicit routes before cutover.',
    'Readiness is deliberately blocked until migration is complete.',
    '',
    '| Route | Dart implementation |',
    '| --- | --- |',
  ];
  var count = 0;
  for (final file in files) {
    final source = file.readAsStringSync();
    final declarations = controller.allMatches(source).toList();
    for (var i = 0; i < declarations.length; i++) {
      final declaration = declarations[i];
      final section = source.substring(
        declaration.end,
        i + 1 < declarations.length ? declarations[i + 1].start : source.length,
      );
      for (final match in route.allMatches(section)) {
        final path =
            '/api/v1/${declaration.group(1) ?? ''}/${match.group(2) ?? ''}'
                .replaceAll(RegExp('/+'), '/')
                .replaceFirst(RegExp(r'/$'), '');
        final key = '${match.group(1)!.toUpperCase()} $path';
        lines.add(
          '| `$key` | ${migrated.contains(key) ? 'Implemented (readiness cutover gate remains closed)' : 'Pending'} |',
        );
        count++;
      }
    }
  }
  lines.add(
    '\n$count explicitly decorated routes; ${migrated.length} initial ports. Protected business flows are not migrated.',
  );
  File(
    '../docs/DART_ROUTE_MIGRATION.md',
  ).writeAsStringSync('${lines.join('\n')}\n');
  stdout.writeln('Inventoried $count routes.');
}
