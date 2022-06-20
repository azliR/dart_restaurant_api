import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_dart/auth.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../common/constants.dart';
import '../../common/response_wrapper.dart';
import '../../db/connection.dart';
import '../../models/auth/store_admin.dart';
import '../../models/enums/enums.dart';

class StoreAccountService {
  StoreAccountService(this._connection, this._firebaseAuth);

  final DatabaseConnection _connection;
  final FirebaseAuth _firebaseAuth;

  Router get router => Router()..post('/auth', _loginStoreHandler);

  Future<Response> _loginStoreHandler(Request request) async {
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final token = body['token'] as String?;

      if (token == null) {
        return Response(
          HttpStatus.unauthorized,
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              message: 'Unauthorized',
              statusCode: HttpStatus.unauthorized,
            ).toJson(),
          ),
        );
      }

      final userCredential = await _firebaseAuth.signInWithCustomToken(token);
      final user = userCredential.user!;

      if (userCredential.additionalUserInfo!.isNewUser) {
        StoreAdmin? storeAdmin;
        final transaction =
            await _connection.db.transaction((connection) async {
          final storeAccountResult = await _connection.db.query(
            _createStoreAccountQuery,
            substitutionValues: {
              'full_name': user.displayName ?? '',
              'role': StoreRole.admin.name,
              'language_code': 'en',
            },
          );

          if (storeAccountResult.isEmpty) {
            connection.cancelTransaction(
              reason: 'Failed to create store account',
            );
          }

          storeAdmin =
              StoreAdmin.fromJson(storeAccountResult.first.toColumnMap());

          final storeAdminResult = await _connection.db.query(
            _createStoreAdminQuery,
            substitutionValues: {
              'store_account_id': storeAdmin?.id,
              'email': user.email,
            },
          );

          if (storeAdminResult.isEmpty) {
            connection.cancelTransaction(
              reason: 'Failed to create store admin',
            );
          }

          storeAdmin = storeAdmin?.copyWith(
            email: user.email,
          );
        });

        if (transaction is PostgreSQLRollback) {
          return Response(
            HttpStatus.internalServerError,
            headers: headers,
            body: jsonEncode(
              ResponseWrapper(
                message: transaction.reason,
                statusCode: HttpStatus.internalServerError,
              ).toJson(),
            ),
          );
        } else {
          return Response.ok(
            jsonEncode(
              ResponseWrapper(
                statusCode: HttpStatus.ok,
                data: storeAdmin,
              ).toJson(),
            ),
            headers: headers,
          );
        }
      } else {
        final postgresResult = await _connection.db.query(
          _getStoreAdminQuery,
          substitutionValues: {
            'email': user.email,
          },
        );
        if (postgresResult.isEmpty) {
          return Response.internalServerError(
            headers: headers,
            body: jsonEncode(
              ResponseWrapper(
                statusCode: HttpStatus.internalServerError,
                message: 'Store admin not found',
              ).toJson(),
            ),
          );
        }

        final storeAdmin = postgresResult.first;
        return Response.ok(
          jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.ok,
              data: StoreAdmin.fromJson(storeAdmin.toColumnMap()),
            ).toJson(),
          ),
          headers: headers,
        );
      }
    } on PostgreSQLException catch (e, stackTrace) {
      log(e.toString(), stackTrace: stackTrace);
      return Response.internalServerError(
        headers: headers,
        body: jsonEncode(
          ResponseWrapper(
            statusCode: HttpStatus.internalServerError,
            message: e.message,
          ).toJson(),
        ),
      );
    } catch (e, stackTrace) {
      log(e.toString(), stackTrace: stackTrace);
      return Response.internalServerError(
        headers: headers,
        body: jsonEncode(
          ResponseWrapper(
            statusCode: HttpStatus.internalServerError,
            message: e.toString(),
          ).toJson(),
        ),
      );
    }
  }

  static const _getStoreAdminQuery = '''
    SELECT *
    FROM store_admin
    WHERE email = @email
    LEFT JOIN store_account ON store_account.id = store_admin.store_account_id
    ''';

  static const _createStoreAccountQuery = '''
    INSERT INTO store_account (
      full_name,
      role,
      language_code
    ) VALUES (
      @full_name,
      @role,
      @language_code
    ) RETURNING *
  ''';

  static const _createStoreAdminQuery = '''
    INSERT INTO store_account (
      store_account_id,
      email
    ) VALUES (
      @store_account_id,
      @email
    ) RETURNING *
  ''';
}
