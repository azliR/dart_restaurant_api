import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:validators/validators.dart';

import '../common/constants.dart';
import '../common/response_wrapper.dart';
import '../db/connection.dart';
import '../models/auth/customer.dart';
import '../models/enums/enums.dart';
import '../models/item/item.dart';
import '../models/item/item_addon.dart';
import '../models/order/order.dart';
import '../models/order/order_detail.dart';
import '../models/order/order_detail_addon.dart';
import '../models/order/orders.dart';
import '../models/store/store.dart';

class OrderService {
  final DatabaseConnection _connection;

  OrderService(this._connection);

  Router get router => Router()
    ..get('/', _getOrdersByCustomerIdHandler)
    ..get('/<orderId>', _getOrderByIdHandler)
    ..post('/', _placeOrderHandler);

  Future<Response> _getOrdersByCustomerIdHandler(Request request) async {
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
        _getOrdersByCustomerIdQuery,
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
      final orderId = request.params['orderId'];

      if (!isUUID(orderId)) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.badRequest,
              message: '{order_id} path parameter is invalid',
            ).toJson(),
          ),
        );
      }

      final orderResult = await _connection.db.query(
        _getOrderByIdQuery,
        substitutionValues: {'id': orderId},
      );

      if (orderResult.isEmpty) {
        return Response.notFound(
          headers: headers,
          jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.notFound,
              message: 'Order not found',
            ).toJson(),
          ),
        );
      }

      final orderDetailResult = await _connection.db.query(
        _getOrderDetailByOrderIdQuery,
        substitutionValues: {'order_id': orderId},
      );

      if (orderDetailResult.isEmpty) {
        return Response.internalServerError(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.internalServerError,
              message: 'Order detail not found',
            ).toJson(),
          ),
        );
      }

      final orderDetails = await Future.wait(
        orderDetailResult.map((orderDetailMap) async {
          final orderDetail =
              OrderDetail.fromJson(orderDetailMap.toColumnMap());
          final orderDetailAddonResult = await _connection.db.query(
            _getOrderDetailAddonByOrderDetailIdQuery,
            substitutionValues: {
              'order_detail_id': orderDetail.id,
            },
          );
          return orderDetail.copyWith(
            addons: orderDetailAddonResult
                .map(
                  (orderDetailAddonMap) => OrderDetailAddon.fromJson(
                    orderDetailAddonMap.toColumnMap(),
                  ),
                )
                .toList(),
          );
        }).toList(),
      );

      final orderMap = Order.fromJson(orderResult.first.toColumnMap())
          .copyWith(
            orderDetails: orderDetails,
          )
          .toJson();

      return Response.ok(
        headers: headers,
        jsonEncode(
          ResponseWrapper(statusCode: HttpStatus.ok, data: orderMap).toJson(),
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

  Future<Response> _placeOrderHandler(Request request) async {
    try {
      final authToken = request.headers[HttpHeaders.authorizationHeader];
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final storeId = body['store_id'] as String?;
      final tableId = body['table_id'] as String?;
      final couponCode = body['coupon_code'] as String?;
      final orderType = body['order_type'] as String?;
      final pickupType = body['pickup_type'] as String?;
      final scheduleAt = body['schedule_at'] as int?;
      final itemMaps =
          (body['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>();

      if (storeId == null || storeId.isEmpty) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.badRequest,
              message: '{store_id} is required',
            ).toJson(),
          ),
        );
      } else if (orderType == null || orderType.isEmpty) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.badRequest,
              message: '{order_type} is required',
            ).toJson(),
          ),
        );
      } else if (pickupType == null || pickupType.isEmpty) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.badRequest,
              message: '{pickup_type} is required',
            ).toJson(),
          ),
        );
      } else if (scheduleAt != null && (scheduleAt < 0 || scheduleAt > 120)) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.badRequest,
              message: '{schedule_at} should be between 0 and 120',
            ).toJson(),
          ),
        );
      }
      if (itemMaps == null || itemMaps.isEmpty) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.badRequest,
              message: '{items} is required',
            ).toJson(),
          ),
        );
      } else {
        for (final item in itemMaps) {
          final itemId = item['item_id'] as String?;
          final quantity = item['quantity'] as int?;

          if (itemId == null || itemId.isEmpty) {
            return Response.badRequest(
              headers: headers,
              body: jsonEncode(
                ResponseWrapper(
                  statusCode: HttpStatus.badRequest,
                  message: '{item_id} is required',
                ).toJson(),
              ),
            );
          } else if (quantity == null || quantity < 1) {
            return Response.badRequest(
              headers: headers,
              body: jsonEncode(
                ResponseWrapper(
                  statusCode: HttpStatus.badRequest,
                  message: '{quantity} is required',
                ).toJson(),
              ),
            );
          }
        }
      }

      Order? order;
      final transaction = await _connection.db.transaction((connection) async {
        final customerResult = await connection.query(
          'SELECT id, full_name FROM customers WHERE id = @customer_id',
          substitutionValues: {'customer_id': authToken},
        );
        late final Customer customer;
        if (customerResult.isEmpty) {
          return connection.cancelTransaction(reason: 'Customer not found');
        } else {
          customer = Customer.fromJson(customerResult.first.toColumnMap());
        }

        final storeResult = await connection.query(
          'SELECT id, name, image FROM stores WHERE id = @store_id',
          substitutionValues: {'store_id': storeId},
        );
        late final Store store;
        if (storeResult.isEmpty) {
          return connection.cancelTransaction(reason: 'Store not found');
        } else {
          store = Store.fromJson(storeResult.first.toColumnMap());
        }

        final orderDetails = <OrderDetail>[];
        final orderDetailAddonMaps = <String, List<OrderDetailAddon>>{};

        for (final itemMap in itemMaps) {
          final itemResult = await connection.query(
            'SELECT id, name, price, picture, description FROM items WHERE id = @item_id',
            substitutionValues: {
              'item_id': itemMap['item_id'],
            },
          );
          if (itemResult.isEmpty) {
            return connection.cancelTransaction(
              reason: 'Item with id ${itemMap['item_id']} not found',
            );
          }
          final item = Item.fromJson(itemResult.first.toColumnMap());

          final addonMaps = (itemMap['addons'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>();
          if (addonMaps != null && addonMaps.isNotEmpty) {
            final orderDetailAddons = <OrderDetailAddon>[];
            for (final addonMap in addonMaps) {
              final addonResult = await connection.query(
                'SELECT id, name, price FROM item_addons WHERE id = @addon_id',
                substitutionValues: {
                  'addon_id': addonMap['addon_id'],
                },
              );
              if (addonResult.isEmpty) {
                return connection.cancelTransaction(
                  reason: 'Addon with id ${addonMap['addon_id']} not found',
                );
              }
              final addon = ItemAddon.fromJson(addonResult.first.toColumnMap());
              orderDetailAddons.add(
                OrderDetailAddon(
                  addonId: addon.id,
                  addonName: addon.name,
                  addonPrice: addon.price,
                ),
              );
            }
            orderDetailAddonMaps[item.id!] = orderDetailAddons;
          }

          final priceTotalItem = item.price! * (itemMap['quantity'] as int);
          final priceTotalAddon = orderDetailAddonMaps.isEmpty
              ? 0
              : orderDetailAddonMaps.values.fold<List<OrderDetailAddon>>(
                  [],
                  (previousValue, element) => previousValue..addAll(element),
                ).fold<double>(
                  0,
                  (total, addon) => total + (addon.addonPrice ?? 0),
                );

          final orderDetail = OrderDetail(
            itemId: item.id,
            itemName: item.name,
            quantity: itemMap['quantity'] as int,
            price: item.price,
            total: priceTotalItem + priceTotalAddon,
            picture: item.picture,
            itemDetail: item.description,
          );
          orderDetails.add(orderDetail);
        }
        final orderTotal = orderDetails.fold<double>(
          0,
          (total, orderDetail) => total + orderDetail.total!,
        );
        final orderResult = await connection.query(
          _insertOrderQuery,
          substitutionValues: {
            'customer_id': customer.id,
            'store_id': storeId,
            'store_account_id': null,
            'table_id': null,
            'coupon_id': null,
            'buyer': customer.fullName,
            'store_name': store.name,
            'store_image': store.image,
            'table_name': null,
            'table_price': null,
            'table_person': null,
            'coupon_name': null,
            'coupon_code': null,
            'discount': null,
            'discount_type': null,
            'discount_nominal': null,
            // minus by coupon
            'brutto': orderTotal,
            'netto': orderTotal,
            'status': OrderStatus.pending.name,
            'order_type': orderType,
            'scheduled_at': scheduleAt,
            'pickup_type': pickupType,
          },
        );

        if (orderResult.isEmpty) {
          return connection.cancelTransaction(reason: 'Order not created');
        } else {
          order = Order.fromJson(orderResult.first.toColumnMap());
        }

        for (final orderDetail in orderDetails) {
          final orderDetailResult = await connection.query(
            _insertOrderDetailQuery,
            substitutionValues: orderDetail
                .copyWith(
                  orderId: orderResult.first.toColumnMap()['id'] as String,
                )
                .toJson(),
          );
          if (orderDetailResult.isEmpty) {
            return connection.cancelTransaction(
              reason: 'Failed to insert order detail',
            );
          } else {
            order = order?.copyWith(
              orderDetails: (order?.orderDetails ?? [])
                ..add(
                  OrderDetail.fromJson(orderDetailResult.first.toColumnMap()),
                ),
            );
          }
          if (orderDetailAddonMaps[orderDetail.itemId] != null) {
            for (final orderDetailAddon
                in orderDetailAddonMaps[orderDetail.itemId]!) {
              final orderDetailAddonResult = await connection.query(
                _insertOrderDetailAddonQuery,
                substitutionValues: orderDetailAddon
                    .copyWith(
                      orderDetailId:
                          orderDetailResult.first.toColumnMap()['id'] as String,
                    )
                    .toJson(),
              );
              if (orderDetailAddonResult.isEmpty) {
                return connection.cancelTransaction(
                  reason: 'Failed to insert order detail addon',
                );
              } else {
                order = order?.copyWith(
                  orderDetails: order?.orderDetails
                      ?.map(
                        (e) => e.copyWith(
                          addons: (e.addons ?? [])
                            ..add(
                              OrderDetailAddon.fromJson(
                                orderDetailAddonResult.first.toColumnMap(),
                              ),
                            ),
                        ),
                      )
                      .toList(),
                );
              }
            }
          }
        }
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
            ResponseWrapper(statusCode: HttpStatus.ok, data: order).toJson(),
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

  static const _getOrdersByCustomerIdQuery = '''
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
  static const _getOrderDetailAddonByOrderDetailIdQuery = '''
    SELECT *
    FROM order_detail_addons
    WHERE order_detail_id = @order_detail_id
    ''';

  static const _insertOrderQuery = '''
    INSERT INTO orders (
        customer_id,
        store_id,
        store_account_id,
        table_id,
        coupon_id,
        buyer,
        store_name,
        store_image,
        table_name,
        table_price,
        table_person,
        coupon_name,
        coupon_code,
        discount,
        discount_type,
        discount_nominal,
        brutto,
        netto,
        status,
        order_type,
        scheduled_at,
        pickup_type
    ) VALUES (
        @customer_id,
        @store_id,
        @store_account_id,
        @table_id,
        @coupon_id,
        @buyer,
        @store_name,
        @store_image,
        @table_name,
        @table_price,
        @table_person,
        @coupon_name,
        @coupon_code,
        @discount,
        @discount_type,
        @discount_nominal,
        @brutto,
        @netto,
        @status,
        @order_type,
        NOW() + INTERVAL '1 MINUTES' * @scheduled_at,
        @pickup_type
    )
    RETURNING *
    ''';

  static const _insertOrderDetailQuery = '''
    INSERT INTO order_details (
        order_id,
        item_id,
        item_name,
        quantity,
        price,
        total,
        picture,
        item_detail,
        rating,
        comment
    ) VALUES (
        @order_id,
        @item_id,
        @item_name,
        @quantity,
        @price,
        @total,
        @picture,
        @item_detail,
        @rating,
        @comment
    ) RETURNING *
    ''';

  static const _insertOrderDetailAddonQuery = '''
    INSERT INTO order_detail_addons (
        order_detail_id,
        addon_id,
        addon_name,
        addon_price
    ) VALUES (
        @order_detail_id,
        @addon_id,
        @addon_name,
        @addon_price
    ) RETURNING *
    ''';
}
