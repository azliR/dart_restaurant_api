import 'package:envied/envied.dart';

part 'config.g.dart';

@Envied()
abstract class Env {
  @EnviedField(varName: 'DATABASE_HOST')
  static const String databaseHost = _Env.databaseHost;
  @EnviedField(varName: 'DATABASE_PORT')
  static const int databasePort = _Env.databasePort;
  @EnviedField(varName: 'DATABASE_NAME')
  static const String databaseName = _Env.databaseName;
  @EnviedField(varName: 'DATABASE_USER')
  static const String databaseUser = _Env.databaseUser;
  @EnviedField(varName: 'DATABASE_PASSWORD')
  static const String databasePassword = _Env.databasePassword;
}
