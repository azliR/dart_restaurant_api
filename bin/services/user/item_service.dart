import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:validators/validators.dart';

import '../../common/constants.dart';
import '../../common/response_wrapper.dart';
import '../../db/connection.dart';
import '../../models/item/item.dart';
import '../../models/item/item_addon.dart';
import '../../models/item/item_addon_category.dart';

class ItemService {
  final DatabaseConnection _connection;

  ItemService(this._connection);

  Router get router => Router()
    ..get('/id/<itemId>', _getItemByIdHandler)
    ..get('/store/<storeId>', _getItemByStoreIdHandler);

  Future<Response> _getItemByIdHandler(Request request) async {
    try {
      final itemId = request.params['itemId'];

      if (itemId == null || !isUUID(itemId)) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.badRequest,
              message: '{itemId} parameter is required or invalid',
            ).toJson(),
          ),
        );
      }

      final itemsResult = await _connection.db.query(
        _getItemByIdQuery,
        substitutionValues: {'id': itemId},
      );

      if (itemsResult.isEmpty) {
        return Response.notFound(
          headers: headers,
          jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.notFound,
              message: 'Item not found',
            ).toJson(),
          ),
        );
      }

      var itemMap = Item.fromJson(itemsResult.first.toColumnMap());

      final addonCategoriesResult = await _connection.db.query(
        _getItemAddonCategoriesByItemIdQuery,
        substitutionValues: {'item_id': itemId},
      );
      itemMap = itemMap.copyWith(
        addonCategories: addonCategoriesResult
            .toList()
            .map((e) => ItemAddonCategory.fromJson(e.toColumnMap()))
            .toList(),
      );

      if (addonCategoriesResult.isNotEmpty) {
        final addonsResult = await _connection.db.query(
          _getItemAddonsByAddonCategoryIdQuery,
          substitutionValues: {
            'addon_category_ids':
                itemMap.addonCategories?.map((e) => e.id).toList(),
          },
        );

        final addons = addonsResult.map((row) => row.toColumnMap()).toList();
        itemMap = itemMap.copyWith(
          addonCategories: itemMap.addonCategories?.map((e) {
            return e.copyWith(
              addons: addons
                  .where((addon) => addon['addon_category_id'] == e.id)
                  .map((addon) => ItemAddon.fromJson(addon))
                  .toList(),
            );
          }).toList(),
        );
      }

      return Response.ok(
        headers: headers,
        jsonEncode(
          ResponseWrapper(statusCode: HttpStatus.ok, data: itemMap).toJson(),
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

  Future<Response> _getItemByStoreIdHandler(Request request) async {
    try {
      final storeId = request.params['storeId'];
      final page =
          int.tryParse(request.requestedUri.queryParameters['page'] ?? '');
      final pageLimit = int.tryParse(
        request.requestedUri.queryParameters['page_limit'] ?? '',
      );
      final subCategoryId =
          request.requestedUri.queryParameters['sub_category_id'];

      if (storeId == null || !isUUID(storeId)) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.badRequest,
              message: '{storeId} parameter is required or invalid',
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
      } else if (subCategoryId != null && !isUUID(subCategoryId)) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.badRequest,
              message: '{sub_category_id} query parameter is invalid',
            ).toJson(),
          ),
        );
      }

      final postgresResult = await _connection.db.query(
        _getItemByStoreIdQuery,
        substitutionValues: {
          'store_id': storeId,
          'page_offset': (page - 1) * pageLimit,
          'page_limit': pageLimit,
          'sub_category_id': subCategoryId,
        },
      );

      final listResult = postgresResult
          .map((e) => Item.fromJson(e.toColumnMap()).toJson())
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

  static const _getItemByIdQuery = '''
    SELECT *
    FROM items
    WHERE id = @id
    ''';

  static const _getItemAddonCategoriesByItemIdQuery = '''
    SELECT *
    FROM item_addon_categories
    WHERE item_id = @item_id
    ORDER BY is_multiple_choice,
        name
    ''';

  static const _getItemAddonsByAddonCategoryIdQuery = '''
    SELECT *
    FROM item_addons
    WHERE addon_category_id = ANY (@addon_category_ids::uuid[])
    ORDER BY price
    ''';

  static const _getItemByStoreIdQuery = '''
    SELECT *
    FROM items
    WHERE store_id = @store_id
        AND (
            CASE
                WHEN @sub_category_id::uuid IS NOT NULL THEN sub_category_id = @sub_category_id
                ELSE TRUE
            END
        )
    ORDER BY (
            CASE
                WHEN special_offer IS NOT NULL THEN special_offer
                ELSE price
            END
        )
    LIMIT @page_limit OFFSET @page_offset
    ''';
}
