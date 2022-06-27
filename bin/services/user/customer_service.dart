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
import '../../models/auth/customer.dart';
import '../../models/token_payload/token_payload.dart';

class CustomerService {
  CustomerService(this._connection);

  final DatabaseConnection _connection;

  Router get router => Router()
    ..get('/profile', _getCustomerByIdHandler)
    ..put('/profile', _updateCustomerHandler)
    ..post('/auth', _loginCustomerHandler);

  Future<Response> _getCustomerByIdHandler(Request request) async {
    try {
      final auth = request.context['authDetails']! as JWT;
      final tokenPayload =
          TokenPayload.fromJson(auth.payload as Map<String, dynamic>);

      final postgresResult = await _connection.db.query(
        _getCustomerByIdQuery,
        substitutionValues: {
          'customer_id': 'firebase:{tokenPayload.userId}',
        },
      );
      if (postgresResult.isEmpty) {
        return Response.notFound(
          headers: headers,
          jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.notFound,
              message: 'Customer not found',
            ).toJson(),
          ),
        );
      }

      final customer = postgresResult.first;
      return Response.ok(
        headers: headers,
        jsonEncode(
          ResponseWrapper(
            statusCode: HttpStatus.ok,
            data: Customer.fromJson(customer.toColumnMap()),
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

  Future<Response> _updateCustomerHandler(Request request) async {
    try {
      final auth = request.context['authDetails']! as JWT;
      final tokenPayload =
          TokenPayload.fromJson(auth.payload as Map<String, dynamic>);

      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final name = body['full_name'] as String?;
      final languageCode = body['language'] as String?;

      if (name == null || name.isEmpty) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              message: '{full_name} is required',
              statusCode: HttpStatus.badRequest,
            ).toJson(),
          ),
        );
      } else if (languageCode == null || languageCode.isEmpty) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              message: '{language} is required',
              statusCode: HttpStatus.badRequest,
            ).toJson(),
          ),
        );
      } else if (!kSupportedLanguages.contains(languageCode)) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              message: '{language} is not supported',
              statusCode: HttpStatus.badRequest,
            ).toJson(),
          ),
        );
      }

      final postgresResult = await _connection.db.query(
        _updateCustomerQuery,
        substitutionValues: {
          'customer_id': 'firebase:${tokenPayload.userId}',
          'full_name': name,
          'language_code': languageCode,
        },
      );
      if (postgresResult.isEmpty) {
        return Response.notFound(
          headers: headers,
          jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.notFound,
              message: 'Customer not found',
            ).toJson(),
          ),
        );
      }

      final customer = postgresResult.first;
      return Response.ok(
        jsonEncode(
          ResponseWrapper(
            statusCode: HttpStatus.ok,
            data: Customer.fromJson(customer.toColumnMap()),
          ).toJson(),
        ),
        headers: headers,
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

  Future<Response> _loginCustomerHandler(Request request) async {
    try {
      final auth = request.context['authDetails']! as JWT;
      final tokenPayload =
          TokenPayload.fromJson(auth.payload as Map<String, dynamic>);

      final loginResult = await _connection.db.query(
        _loginCustomerQuery,
        substitutionValues: {
          'id': 'firebase:${tokenPayload.userId}',
        },
      );

      if (loginResult.isEmpty) {
        final postgresResult = await _connection.db.query(
          _createCustomerQuery,
          substitutionValues: {
            'id': 'firebase:${tokenPayload.userId}',
            'full_name': '',
            'phone': tokenPayload.phoneNumber,
            'language_code': 'en',
          },
        );
        if (postgresResult.isEmpty) {
          return Response.internalServerError(
            headers: headers,
            body: jsonEncode(
              ResponseWrapper(
                statusCode: HttpStatus.internalServerError,
                message: 'Customer not created',
              ).toJson(),
            ),
          );
        }

        final customer = postgresResult.first;
        return Response.ok(
          headers: headers,
          jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.ok,
              data: Customer.fromJson(customer.toColumnMap()),
            ).toJson(),
          ),
        );
      } else {
        return Response.ok(
          headers: headers,
          jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.ok,
              data: Customer.fromJson(loginResult.first.toColumnMap()),
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

  static const _getCustomerByIdQuery = '''
    SELECT *
    FROM customers
    WHERE id = @customer_id
    ''';

  static const _updateCustomerQuery = '''
    UPDATE customers
    SET full_name = @full_name,
        language_code = @language_code
    WHERE id = @customer_id
    RETURNING *
    ''';

  static const _loginCustomerQuery = '''
    SELECT *
    FROM customers
    WHERE id = @id
    ''';

  static const _createCustomerQuery = '''
    INSERT INTO customers (id, full_name, phone, language_code)
    VALUES (@id, @full_name, @phone, @language_code)
    RETURNING *
    ''';
}
