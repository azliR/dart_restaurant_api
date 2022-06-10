import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:validators/validators.dart';

import '../common/constants.dart';
import '../common/response_wrapper.dart';
import '../db/connection.dart';
import '../models/order/order.dart';
import '../models/order/order_detail.dart';
import '../models/order/orders.dart';

class OrderService {
  final DatabaseConnection connection;

  OrderService(this.connection);

  Router get router => Router()
    ..get('/', _getOrderByCustomerIdHandler)
    ..get('/<orderId>', _getOrderByIdHandler);

  Future<Response> _getOrderByCustomerIdHandler(Request request) async {
    final customerId = request.requestedUri.queryParameters['customer_id'];
    final page =
        int.tryParse(request.requestedUri.queryParameters['page'] ?? '');
    final pageLimit =
        int.tryParse(request.requestedUri.queryParameters['page_limit'] ?? '');

    if (customerId == null || !isUUID(customerId)) {
      return Response.badRequest(
        headers: headers,
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 400,
            message: '{customer_id} query parameter is required or invalid',
          ).toJson(),
        ),
      );
    } else if (page == null || page <= 0) {
      return Response.badRequest(
        headers: headers,
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 400,
            message: '{page} query parameter is required or invalid',
          ).toJson(),
        ),
      );
    } else if (pageLimit == null || pageLimit <= 0) {
      return Response.badRequest(
        headers: headers,
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 400,
            message: '{page_limit} query parameter is required or invalid',
          ).toJson(),
        ),
      );
    }

    final postgresResult = await connection.db.query(
      _getOrderByCustomerIdQuery,
      substitutionValues: {
        'customer_id': customerId,
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
      jsonEncode(ResponseWrapper(statusCode: 200, data: listResult).toJson()),
    );
  }

  Future<Response> _getOrderByIdHandler(Request request) async {
    final orderId = request.params['orderId'];

    if (!isUUID(orderId)) {
      return Response.badRequest(
        headers: headers,
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 400,
            message: '{order_id} path parameter is invalid',
          ).toJson(),
        ),
      );
    }

    final orderResult = await connection.db.query(
      _getOrderByIdQuery,
      substitutionValues: {'id': orderId},
    );

    if (orderResult.isEmpty) {
      return Response.notFound(
        headers: headers,
        jsonEncode(
          ResponseWrapper(
            statusCode: 404,
            message: 'Order not found',
          ).toJson(),
        ),
      );
    } else if (orderResult.length > 1) {
      return Response.internalServerError(
        headers: headers,
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 500,
            message: 'Multiple orders found',
          ).toJson(),
        ),
      );
    }

    final orderDetailResult = await connection.db.query(
      _getOrderDetailByOrderIdQuery,
      substitutionValues: {'order_id': orderId},
    );

    if (orderDetailResult.isEmpty) {
      return Response.internalServerError(
        headers: headers,
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 500,
            message: 'Order detail not found',
          ).toJson(),
        ),
      );
    }

    final orderMap = Order.fromJson(orderResult.first.toColumnMap())
        .copyWith(
          orderDetails: orderDetailResult
              .map((e) => OrderDetail.fromJson(e.toColumnMap()))
              .toList(),
        )
        .toJson();

    return Response.ok(
      headers: headers,
      jsonEncode(ResponseWrapper(statusCode: 200, data: orderMap).toJson()),
    );
  }

  static const _getOrderByCustomerIdQuery = '''
    SELECT orders.*,
        COUNT(order_details) AS total_item
    FROM orders
        LEFT JOIN order_details ON orders.id = order_details.order_id
    WHERE customer_id = @customer_id
    GROUP BY orders.id
    ORDER BY created_at DESC
    LIMIT @page_limit OFFSET @page_offset
    ''';

  static const _getOrderByIdQuery = '''
    SELECT *
    FROM orders
    WHERE id = @id
    ''';

  static const _getOrderDetailByOrderIdQuery = '''
    SELECT *
    FROM order_details
    WHERE order_id = @order_id
    ''';
}
