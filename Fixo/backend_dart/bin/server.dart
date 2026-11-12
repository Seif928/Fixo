import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:fixo_backend/infrastructure/postgres_catalog.dart';
import 'package:fixo_backend/presentation/api.dart';

Future<void> main() async {
  final url = Platform.environment['DATABASE_URL'];
  final port = int.tryParse(Platform.environment['PORT'] ?? '3080');
  if (url == null || port == null || port < 1 || port > 65535) {
    stderr.writeln('Set a valid DATABASE_URL and PORT.');
    exitCode = 1;
    return;
  }
  PostgresCatalog? database;
  try {
    database = await PostgresCatalog.open(url);
    final server = await shelf_io.serve(
      createApi(database, database),
      Platform.environment['HOST'] ?? '127.0.0.1',
      port,
    );
    stdout.writeln(
      'FIXO Dart migration service listening on port ${server.port}. Cutover disabled.',
    );
    var closing = false;
    Future<void> close() async {
      if (closing) return;
      closing = true;
      await server.close(force: true);
      await database!.close();
      exit(0);
    }

    ProcessSignal.sigint.watch().listen((_) => close());
    if (!Platform.isWindows)
      ProcessSignal.sigterm.watch().listen((_) => close());
  } catch (_) {
    await database?.close();
    stderr.writeln(
      'Dart API startup failed. Check server configuration/database availability.',
    );
    exitCode = 1;
  }
}
