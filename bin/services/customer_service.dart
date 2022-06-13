import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../common/constants.dart';
import '../common/response_wrapper.dart';
import '../db/connection.dart';
import '../models/auth/customer.dart';

class CustomerService {
  final DatabaseConnection connection;

  CustomerService(this.connection);

  Router get router => Router()..get('/<customerId>', _getCustomerByIdHandler);

  Future<Response> _getCustomerByIdHandler(Request request) async {
    try {
      final customerId = request.requestedUri.pathSegments.last;
      final postgresResult = await connection.db.query(
        _getCustomerByIdQuery,
        substitutionValues: {
          'customer_id': customerId,
        },
      );
      if (postgresResult.isEmpty) {
        return Response.notFound(
          headers: headers,
          jsonEncode(
            ResponseWrapper(
              statusCode: 404,
              message: 'Customer not found',
            ).toJson(),
          ),
        );
      } else if (postgresResult.length > 1) {
        return Response.internalServerError(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: 500,
              message: 'Multiple customers found',
            ).toJson(),
          ),
        );
      }
      final customer = postgresResult.first;
      return Response.ok(
        jsonEncode(
          ResponseWrapper(
            statusCode: 200,
            data: Customer.fromJson(customer.toColumnMap()),
          ).toJson(),
        ),
        headers: headers,
      );
    } on PostgreSQLException catch (e) {
      return Response.internalServerError(
        headers: headers,
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 500,
            message: e.message,
          ).toJson(),
        ),
      );
    } catch (e) {
      return Response.badRequest(
        headers: headers,
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 400,
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
}
