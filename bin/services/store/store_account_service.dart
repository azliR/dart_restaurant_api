import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_dart/auth.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../common/constants.dart';
import '../../common/response_wrapper.dart';
import '../../db/connection.dart';
import '../../db/token_service.dart';
import '../../db/utils.dart';
import '../../models/auth/store_admin.dart';
import '../../models/enums/enums.dart';
import '../../models/token_payload/token_payload.dart';

class StoreAccountService {
  StoreAccountService(
    this._connection,
    this._firebaseAuth,
    this._tokenService,
  );

  final DatabaseConnection _connection;
  final FirebaseAuth _firebaseAuth;
  final TokenService _tokenService;

  Router get router => Router()
    ..post('/auth', _loginStoreHandler)
    ..post('/refreshtoken', _refreshTokenHandler);

  Future<Response> _registerStoreHandler(Request request) async {
    final payload = await request.readAsString();
    final userInfo = json.decode(payload) as Map<String, dynamic>;
    final fullName = userInfo['full_name'] as String?;
    final email = userInfo['email'] as String?;
    final password = userInfo['password'] as String?;

    // Ensure email and password fields are present
    if (email == null || email.isEmpty) {
      return Response(
        HttpStatus.badRequest,
        body: ResponseWrapper(
          statusCode: HttpStatus.badRequest,
          message: '{email} is required',
        ).toJson(),
      );
    }

    StoreAdmin? storeAdmin;
    final transaction = await _connection.db.transaction((connection) async {
      final storeAccountResult = await _connection.db.query(
        _createStoreAccountQuery,
        substitutionValues: {
          'full_name': fullName,
          'role': StoreRole.admin.name,
          'language_code': 'en',
        },
      );

      if (storeAccountResult.isEmpty) {
        connection.cancelTransaction(
          reason: 'Failed to create store account',
        );
      }

      storeAdmin = StoreAdmin.fromJson(storeAccountResult.first.toColumnMap());

      final storeAdminResult = await _connection.db.query(
        _createStoreAdminQuery,
        substitutionValues: {
          'store_account_id': storeAdmin?.id,
          'email': email,
        },
      );

      if (storeAdminResult.isEmpty) {
        connection.cancelTransaction(
          reason: 'Failed to create store admin',
        );
      }

      storeAdmin = storeAdmin?.copyWith(
        email: email,
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
  }

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

      final jwt = await verifyFirebaseToken(token);

      final postgresResult = await _connection.db.query(
        _getStoreAdminQuery,
        substitutionValues: {
          'email':
              TokenPayload.fromJson(jwt.payload as Map<String, dynamic>).email,
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

      final tokenPair = await _tokenService.createTokenPair(token);

      return Response.ok(
        headers: headers,
        jsonEncode(
          ResponseWrapper(
            statusCode: HttpStatus.ok,
            data: {
              'user': StoreAdmin.fromJson(storeAdmin.toColumnMap()),
              'token': tokenPair.toJson(),
            },
          ).toJson(),
        ),
      );
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

  Future<Response> _refreshTokenHandler(Request request) async {
    final auth = request.context['authDetails'] as JWT?;
    if (auth is JWT) {
      return Response.badRequest(
        body: ResponseWrapper(
          statusCode: HttpStatus.badRequest,
          message: 'Id token is still valid!',
        ).toJson(),
      );
    }

    final payload = await request.readAsString();
    final payloadMap = json.decode(payload) as Map<String, dynamic>;

    // Verify current token pair
    late JWT token;

    try {
      token = JWT.verify(
        payloadMap['refreshToken'].toString(),
        SecretKey(_tokenService.secret),
      );
      final dbToken = await _tokenService.getRefreshToken(token.jwtId!);

      if (dbToken == null) {
        return Response.badRequest(
          body: ResponseWrapper(
            statusCode: HttpStatus.badRequest,
            message: 'Refresh token is not recognised',
          ).toJson(),
        );
      }
    } on JWTExpiredError {
      return Response.badRequest(
        body: ResponseWrapper(
          statusCode: HttpStatus.badRequest,
          message: 'Refresh token is expired',
        ).toJson(),
      );
    } catch (e) {
      return Response.badRequest(
        body: ResponseWrapper(
          statusCode: HttpStatus.badRequest,
          message: e.toString(),
        ).toJson(),
      );
    }

    // Generate new pair
    try {
      final tokenPair = await _tokenService.createTokenPair(token.subject!);
      return Response.ok(
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
        ResponseWrapper(
          statusCode: HttpStatus.ok,
          data: json.encode(tokenPair.toJson()),
        ).toJson(),
      );
    } catch (e) {
      return Response.internalServerError(
        body: ResponseWrapper(
          statusCode: HttpStatus.internalServerError,
          message:
              'There was a problem creating a new token. Please try again.',
        ).toJson(),
      );
    }
  }

  static const _getStoreAdminQuery = '''
    SELECT *
    FROM store_admins
    LEFT JOIN store_accounts ON store_accounts.id = store_admins.store_account_id
    WHERE email = @email
    ''';

  static const _createStoreAccountQuery = '''
    INSERT INTO store_accounts (
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
    INSERT INTO store_accounts (
      store_account_id,
      email
    ) VALUES (
      @store_account_id,
      @email
    ) RETURNING *
  ''';
}
