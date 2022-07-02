import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:faker/faker.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../common/constants.dart';
import '../../common/response_wrapper.dart';
import '../../db/connection.dart';
import '../../models/auth/customer.dart';
import '../../models/enums/enums.dart';
import '../../models/item/item.dart';
import '../../models/item/item_addon.dart';
import '../../models/order/order_detail.dart';
import '../../models/order/order_detail_addon.dart';
import '../../models/store/store.dart';

class TemplateService {
  final DatabaseConnection _connection;

  TemplateService(this._connection);

  Router get router => Router()..post('/order', _createOrderTemplateHandler);

  Future<Response> _placeOrderHandler(Request request) async {
    try {
      final authToken = '1c7b3156-986b-487b-8d6c-2db03806ca30';
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final storeId = body['store_id'] as String?;
      final tableId = body['table_id'] as String?;
      final couponCode = body['coupon_code'] as String?;
      final orderType = body['order_type'] as String?;
      final pickupType = body['pickup_type'] as String?;
      final scheduleAt = body['schedule_at'] as int?;
      final createdAt = body['created_at'] as String?;
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
            'status': OrderStatus.complete.name,
            'order_type': orderType,
            'scheduled_at': scheduleAt,
            'pickup_type': pickupType,
            'created_at': createdAt,
          },
        );

        if (orderResult.isEmpty) {
          return connection.cancelTransaction(reason: 'Order not created');
        }

        for (final orderDetail in orderDetails) {
          final orderDetailResult = await connection.query(
            _insertOrderDetailQuery,
            substitutionValues: orderDetail
                .copyWith(
                  orderId: orderResult.first.toColumnMap()['id'] as String,
                  comment: faker.randomGenerator.boolean()
                      ? faker.lorem.sentence()
                      : null,
                  rating: faker.randomGenerator.boolean()
                      ? Random().nextInt(4) + 1
                      : null,
                )
                .toJson(),
          );
          if (orderDetailResult.isEmpty) {
            return connection.cancelTransaction(
              reason: 'Failed to insert order detail',
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
            ResponseWrapper(
              statusCode: HttpStatus.ok,
              message: 'Order successfully created',
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

  Future<Response> _createOrderTemplateHandler(Request request) async {
    try {
      for (var i = 0; i < 1000; i++) {
        final isSchedule = faker.randomGenerator.boolean();
        final a = await _placeOrderHandler(
          Request(
            request.method,
            request.requestedUri,
            headers: request.headers,
            context: request.context,
            encoding: request.encoding,
            handlerPath: request.handlerPath,
            onHijack: request.hijack,
            protocolVersion: request.protocolVersion,
            url: request.url,
            body: jsonEncode({
              'store_id': '93ab578c-46fa-42f6-b61f-ef13fe13045d',
              'order_type':
                  isSchedule ? OrderType.scheduled.name : OrderType.now.name,
              'coupon': '',
              'schedule_at': isSchedule ? Random().nextInt(120) : null,
              'pickup_type': PickupType
                  .values[Random().nextInt(PickupType.values.length)].name,
              'created_at': Faker()
                  .date
                  .dateTime(minYear: 2021, maxYear: 2022)
                  .toIso8601String(),
              'items': Set.from(
                Iterable.generate(
                  Random().nextInt(10) + 1,
                  (index) => {
                    'item_id': [
                      '7b1c8c31-4a0f-4457-8c71-8f06631aa9ae',
                      'c171b7c0-9457-49af-8872-b0ff5081bbc1',
                      'e42dd265-873e-44d9-abaa-5f937c9d4d6e',
                      '0098d69a-1d47-4f1b-a423-58e157388744',
                      '2cf7dd2d-59c0-4b5d-a61c-7177b1120247',
                      '427643c1-9b79-4016-a806-cdef76a79ab7',
                      'c9113655-b1dc-4415-8ad1-34540db0df92',
                      '3ceeecb7-5061-480a-8dcc-036b54a860cb',
                      'c61f2371-f967-4eda-bf39-c7e2875ef3aa',
                      '1e6bc1ae-8772-43ae-823e-7c0c9c199658',
                      '1dc4e414-1c77-4dfe-834c-ab6794169a5d',
                      '82c8dbdb-9e10-4724-ac7f-55574ceceb74',
                      'c7f2bc71-3bfa-4315-83ef-ddc1f75a3225',
                    ][Random().nextInt(13)],
                    'quantity': Random().nextInt(10) + 1,
                  },
                ),
              ).toList()
            }),
          ),
        );
        print(await a.readAsString());
      }
      return Response.ok(
        jsonEncode(
          ResponseWrapper(
            statusCode: HttpStatus.ok,
            message: 'Order template successfully created',
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
        pickup_type,
        created_at
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
        @pickup_type,
        @created_at
    )
    RETURNING id
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
    ) RETURNING id
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
    ) RETURNING id
    ''';
}
