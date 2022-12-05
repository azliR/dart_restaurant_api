import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../common/constants.dart';
import '../../common/response_wrapper.dart';
import '../../db/connection.dart';
import '../../models/auth/store_admin.dart';
import '../../models/enums/enums.dart';
import '../../models/token_payload/token_payload.dart';

class StoreAccountService {
  StoreAccountService(this._connection);

  final DatabaseConnection _connection;

  Router get router => Router()..post('/auth', _loginStoreHandler);

  Future<Response> _loginStoreHandler(Request request) async {
    try {
      final auth = request.context['authDetails']! as JWT;
      final tokenPayload =
          TokenPayload.fromJson(auth.payload as Map<String, dynamic>);

      final loginResult = await _connection.db.query(
        _getStoreAdminQuery,
        substitutionValues: {
          'id': 'firebase:${tokenPayload.userId}',
        },
      );
      if (loginResult.isEmpty) {
        StoreAdmin? storeAdmin;
        final transaction =
            await _connection.db.transaction((connection) async {
          final storeAccountResult = await connection.query(
            _createStoreAccountQuery,
            substitutionValues: {
              'id': 'firebase:${tokenPayload.userId}',
              'full_name': '',
              'role': StoreRole.admin.name,
              'language_code': 'en',
            },
          );
          if (storeAccountResult.isEmpty) {
            return connection.cancelTransaction(
              reason: 'Failed to create store account',
            );
          }
          final storeAdminResult = await connection.query(
            _createStoreAdminQuery,
            substitutionValues: {
              'store_account_id': 'firebase:${tokenPayload.userId}',
              'email': tokenPayload.email,
            },
          );
          if (storeAdminResult.isEmpty) {
            return connection.cancelTransaction(
              reason: 'Failed to create store admin',
            );
          }
          final storeAdminJson = storeAccountResult.first.toColumnMap();
          final email = storeAdminResult.first.toColumnMap()['email'] as String;
          storeAdmin =
              StoreAdmin.fromJson(storeAdminJson).copyWith(email: email);
        });

        if (transaction is PostgreSQLRollback) {
          return Response.internalServerError(
            headers: headers,
            body: jsonEncode(
              ResponseWrapper(
                statusCode: HttpStatus.internalServerError,
                message: transaction.reason,
              ).toJson(),
            ),
          );
        } else {
          return Response.ok(
            headers: headers,
            jsonEncode(
              ResponseWrapper(
                statusCode: HttpStatus.ok,
                data: storeAdmin,
              ).toJson(),
            ),
          );
        }
      } else {
        return Response.ok(
          headers: headers,
          jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.ok,
              data: StoreAdmin.fromJson(loginResult.first.toColumnMap()),
            ).toJson(),
          ),
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

  // Future<Response> _refreshTokenHandler(Request request) async {
  //   final auth = request.context['authDetails'] as JWT?;
  //   if (auth is JWT) {
  //     return Response.badRequest(
  //       body: ResponseWrapper(
  //         statusCode: HttpStatus.badRequest,
  //         message: 'Id token is still valid!',
  //       ).toJson(),
  //     );
  //   }

  //   final payload = await request.readAsString();
  //   final payloadMap = json.decode(payload) as Map<String, dynamic>;

  //   // Verify current token pair
  //   late JWT token;

  //   try {
  //     token = JWT.verify(
  //       payloadMap['refreshToken'].toString(),
  //       SecretKey(_tokenService.secret),
  //     );
  //     final dbToken = await _tokenService.getRefreshToken(token.jwtId!);

  //     if (dbToken == null) {
  //       return Response.badRequest(
  //         body: ResponseWrapper(
  //           statusCode: HttpStatus.badRequest,
  //           message: 'Refresh token is not recognised',
  //         ).toJson(),
  //       );
  //     }
  //   } on JWTExpiredError {
  //     return Response.badRequest(
  //       body: ResponseWrapper(
  //         statusCode: HttpStatus.badRequest,
  //         message: 'Refresh token is expired',
  //       ).toJson(),
  //     );
  //   } catch (e) {
  //     return Response.badRequest(
  //       body: ResponseWrapper(
  //         statusCode: HttpStatus.badRequest,
  //         message: e.toString(),
  //       ).toJson(),
  //     );
  //   }

  //   // Generate new pair
  //   try {
  //     final tokenPair = await _tokenService.createTokenPair(token.subject!);
  //     return Response.ok(
  //       headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
  //       ResponseWrapper(
  //         statusCode: HttpStatus.ok,
  //         data: json.encode(tokenPair.toJson()),
  //       ).toJson(),
  //     );
  //   } catch (e) {
  //     return Response.internalServerError(
  //       body: ResponseWrapper(
  //         statusCode: HttpStatus.internalServerError,
  //         message:
  //             'There was a problem creating a new token. Please try again.',
  //       ).toJson(),
  //     );
  //   }
  // }

  static const _getStoreAdminQuery = '''
    SELECT *
    FROM store_admins
    LEFT JOIN store_accounts ON store_accounts.id = store_admins.store_account_id
    WHERE id = @id
    ''';

  static const _createStoreAccountQuery = '''
    INSERT INTO store_accounts (
      id,
      full_name,
      role,
      language_code
    ) VALUES (
      @id,
      @full_name,
      @role,
      @language_code
    ) RETURNING *
  ''';

  static const _createStoreAdminQuery = '''
    INSERT INTO store_admins (
      store_account_id,
      email
    ) VALUES (
      @store_account_id,
      @email
    ) RETURNING *
  ''';
}
