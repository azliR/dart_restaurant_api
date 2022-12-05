import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../common/constants.dart';
import '../../common/response_wrapper.dart';
import '../../db/connection.dart';
import '../../models/order/order.dart';
import '../../models/order/orders.dart';

class StoreOrderService {
  StoreOrderService(this._connection);

  final DatabaseConnection _connection;

  Router get router => Router()
    ..get('/', _getOrdersByStoreIdHandler)
    ..get('/id/<orderId>', _getOrderByIdHandler);

  Future<Response> _getOrdersByStoreIdHandler(Request request) async {
    try {
      final token = request.headers[HttpHeaders.authorizationHeader];
      final page =
          int.tryParse(request.requestedUri.queryParameters['page'] ?? '');
      final pageLimit = int.tryParse(
        request.requestedUri.queryParameters['page_limit'] ?? '',
      );

      if (token == null) {
        return Response(
          HttpStatus.unauthorized,
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.unauthorized,
              message: 'Unauthorized',
            ).toJson(),
          ),
        );
      } else if (page == null || page <= 0) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.badRequest,
              message: '{page} query parameter is required or invalid',
            ).toJson(),
          ),
        );
      } else if (pageLimit == null || pageLimit <= 0) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.badRequest,
              message: '{page_limit} query parameter is required or invalid',
            ).toJson(),
          ),
        );
      }

      final postgresResult = await _connection.db.query(
        _getOrdersByStoreIdQuery,
        substitutionValues: {
          'customer_id': token,
          'page_offset': (page - 1) * pageLimit,
          'page_limit': pageLimit,
        },
      );

      final listResult = postgresResult
          .toList()
          .map((e) => Orders.fromJson(e.toColumnMap()).toJson())
          .toList();

      return Response.ok(
        headers: headers,
        jsonEncode(
          ResponseWrapper(statusCode: HttpStatus.ok, data: listResult).toJson(),
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

  Future<Response> _getOrderByIdHandler(Request request) async {
    try {
      final token = request.headers[HttpHeaders.authorizationHeader]
          ?.replaceFirst('Bearer ', '');

      if (token == null) {
        return Response(
          HttpStatus.unauthorized,
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.unauthorized,
              message: 'Unauthorized',
            ).toJson(),
          ),
        );
      }

      final orderId = request.url.pathSegments.last;

      final postgresResult = await _connection.db.query(
        _getOrderByIdQuery,
        substitutionValues: {'order_id': orderId},
      );

      final order = postgresResult.map((row) {
        return Order.fromJson(row.toColumnMap());
      }).toList();

      return Response.ok(
        headers: headers,
        jsonEncode(
          ResponseWrapper(
            statusCode: HttpStatus.ok,
            data: order,
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

  static const _getOrdersByStoreIdQuery = '''
    SELECT *
    FROM orders
    WHERE store_id = @store_id
    ORDER BY created_at DESC
    LIMIT @page_limit OFFSET @page_offset
    ''';

  static const _getOrderByIdQuery = '''
    SELECT *
    FROM orders
    WHERE id = @order_id
    ''';
}
