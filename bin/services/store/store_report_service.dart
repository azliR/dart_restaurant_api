import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../common/constants.dart';
import '../../common/response_wrapper.dart';
import '../../db/connection.dart';
import '../../models/report/item_trend.dart';

class StoreReportService {
  final DatabaseConnection _connection;

  StoreReportService(this._connection);

  Router get router => Router()..get('/item', _getTrendingItemsHandler);

  Future<Response> _getTrendingItemsHandler(Request request) async {
    try {
      final postgresResult = await _connection.db.query(
        _getTrendingItemsQuery,
      );

      if (postgresResult.isEmpty) {
        return Response.notFound(
          headers: headers,
          jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.notFound,
              message: 'No trending items found',
            ).toJson(),
          ),
        );
      }
      return Response.ok(
        headers: headers,
        jsonEncode(
          ResponseWrapper(
            statusCode: HttpStatus.ok,
            data: groupBy<Map, String>(
              postgresResult.map((row) {
                return ItemTrend.fromJson(row.toColumnMap()).toJson();
              }),
              (obj) => obj['name'] as String,
            ).map(
              (key, value) =>
                  MapEntry(key, value.map((e) => e..remove('name')).toList()),
            ),
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

  static const _getTrendingItemsQuery = '''
    SELECT DATE_TRUNC('month', orders.created_at) AS date,
        items.name,
        SUM(order_details.quantity) AS total_sales
    FROM items,
        order_details,
        orders
    WHERE items.id = order_details.item_id
        AND order_details.order_id = orders.id
        AND orders.status = 'complete'
        AND orders.store_id = '93ab578c-46fa-42f6-b61f-ef13fe13045d'
        AND orders.created_at >= DATE_TRUNC('year', NOW()) - INTERVAL '1 year'
    GROUP BY date,
        items.name
    ORDER BY date DESC
    ''';
}
