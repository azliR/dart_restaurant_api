import 'dart:io' show Platform;

import 'package:postgres/postgres.dart';

import 'config.dart';

class DatabaseConnection {
  late final PostgreSQLConnection db;

  DatabaseConnection() {
    final Map<String, String> envVars = Platform.environment;
    final host = envVars['DATABASE_HOST'] ?? Env.databaseHost;
    final port = envVars['DATABASE_PORT'] == null
        ? Env.databasePort
        : int.parse(envVars['DATABASE_PORT']!);
    final database = envVars['DATABASE_NAME'] ?? Env.databaseName;
    final username = envVars['DATABASE_USER'] ?? Env.databaseUser;
    final password = envVars['DATABASE_PASSWORD'] ?? Env.databasePassword;

    db = PostgreSQLConnection(
      host,
      port,
      database,
      username: username,
      password: password,
      useSSL: envVars['DATABASE_HOST'] != null,
    );
  }
}
