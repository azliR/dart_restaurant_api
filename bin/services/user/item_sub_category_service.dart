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
import '../../models/item/item_sub_category.dart';

// Ririn cantik
class ItemSubCategoryService {
  final DatabaseConnection _connection;

  ItemSubCategoryService(this._connection);

  Router get router => Router()
    ..get('/all', _getItemSubCategoryServiceHandler)
    ..post('/', _insertItemSubCategoryServiceHandler);

  Future<Response> _getItemSubCategoryServiceHandler(Request request) async {
    try {
      final page =
          int.tryParse(request.requestedUri.queryParameters['page'] ?? '');
      final pageLimit = int.tryParse(
        request.requestedUri.queryParameters['page_limit'] ?? '',
      );
      final storeId = request.requestedUri.queryParameters['store_id'];
      final languageCode =
          request.requestedUri.queryParameters['language_code'];

      if (page == null || page <= 0) {
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
      } else if (storeId == null || !isUUID(storeId)) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.badRequest,
              message: '{store_id} query parameter is required or invalid',
            ).toJson(),
          ),
        );
      }

      final postgresResult = await _connection.db.query(
        _getItemSubCategoriesByStoreIdQuery,
        substitutionValues: {
          'store_id': storeId,
          'language_code': languageCode,
          'page_offset': (page - 1) * pageLimit,
          'page_limit': pageLimit,
        },
      );

      final listResult = postgresResult
          .toList()
          .map((e) => ItemSubCategory.fromJson(e.toColumnMap()).toJson())
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

  Future<Response> _insertItemSubCategoryServiceHandler(Request request) async {
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final storeId = body['store_id'] as String?;
      final name = body['name'] as String?;

      final postgresResult = await _connection.db.query(
        _insertItemSubCategoryQuery,
        substitutionValues: {
          'store_id': storeId,
          'name': name,
        },
      );

      final listResult = postgresResult
          .toList()
          .map((e) => ItemSubCategory.fromJson(e.toColumnMap()).toJson())
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

  static const _getItemSubCategoriesByStoreIdQuery = '''
    SELECT item_sub_categories.id,
        item_sub_category_l10ns.language_code,
        item_sub_categories.name,
        item_sub_category_l10ns.name AS translated_name
    FROM item_sub_categories
        LEFT JOIN item_sub_category_l10ns ON item_sub_categories.id = item_sub_category_l10ns.sub_category_id
        AND item_sub_category_l10ns.language_code = @language_code
    WHERE item_sub_categories.store_id = @store_id
        AND (
            SELECT COUNT(*)
            FROM items
            WHERE items.sub_category_id = item_sub_categories.id
        ) > 0
    ORDER BY (
            CASE
                WHEN item_sub_category_l10ns.name IS NOT NULL THEN item_sub_category_l10ns.name
                ELSE item_sub_categories.name
            END
        )
    LIMIT @page_limit OFFSET @page_offset
    ''';

  static const _insertItemSubCategoryQuery = '''
    INSERT INTO item_sub_categories (store_id, name)
    VALUES (@store_id, @name)
    RETURNING *
    ''';
}
