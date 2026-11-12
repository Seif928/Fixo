import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'feature domain files stay independent of Flutter, transport and outer layers',
    () {
      final files = Directory('lib/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.replaceAll('\\', '/').contains('/domain/') &&
                f.path.endsWith('.dart'),
          );
      for (final file in files) {
        final directives = RegExp(
          r'''(?:import|export)\s+['"]([^'"]+)['"]''',
        ).allMatches(file.readAsStringSync());
        for (final directive in directives) {
          final uri = directive.group(1)!;
          expect(
            uri,
            isNot(
              matches(
                r'package:(flutter|flutter_riverpod|dio|firebase_|postgres)|/data/|/presentation/|/infrastructure/|core/network|dart:io',
              ),
            ),
            reason: '${file.path} depends on $uri',
          );
        }
      }
    },
  );
  test(
    'profile abstraction belongs to domain and composition belongs to app',
    () {
      expect(
        File(
          'lib/features/profile/domain/profile_repository.dart',
        ).existsSync(),
        true,
      );
      final source = File(
        'lib/features/profile/presentation/controllers/profile_controller.dart',
      ).readAsStringSync();
      expect(source, isNot(contains("../../data/profile_repository.dart")));
      expect(
        File('lib/app/providers/profile_providers.dart').existsSync(),
        true,
      );
    },
  );
}
