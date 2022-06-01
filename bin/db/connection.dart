import 'dart:io' show Platform;

import 'package:postgres/postgres.dart';

class DatabaseConnection {
  late final PostgreSQLConnection db;

  DatabaseConnection() {
    final Map<String, String> envVars = Platform.environment;
    final host = envVars['DB_HOST'] ?? 'localhost';
    final port =
        envVars['DB_PORT'] == null ? 5432 : int.parse(envVars['DB_PORT']!);
    final database = envVars['DB_DATABASE'] ?? 'restaurant';
    final username = envVars['DB_USERNAME'] ?? 'postgres';
    final password = envVars['DB_PASSWORD'] ?? 'root';

    db = PostgreSQLConnection(
      host,
      port,
      database,
      username: username,
      password: password,
    );
  }
}
