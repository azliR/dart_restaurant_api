import 'dart:io' show Platform;

import 'package:postgres/postgres.dart';

class DatabaseConnection {
  late final PostgreSQLConnection db;

  DatabaseConnection() {
    final Map<String, String> envVars = Platform.environment;
    final host = envVars['DATABASE_HOST'] ?? 'localhostd';
    final port = envVars['DATABASE_PORT'] == null
        ? 5432
        : int.parse(envVars['DATABASE_PORT']!);
    final database = envVars['DATABASE_NAME'] ?? 'restaurant';
    final username = envVars['DATABASE_USER'] ?? 'postgres';
    final password = envVars['DATABASE_PASSWORD'] ?? 'root';

    db = PostgreSQLConnection(
      host,
      port,
      database,
      username: username,
      password: password,
    );
  }
}
