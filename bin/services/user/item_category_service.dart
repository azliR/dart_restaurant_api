import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../common/constants.dart';
import '../../common/response_wrapper.dart';
import '../../db/connection.dart';
import '../../models/item/item_category.dart';

class ItemCategoryService {
  final DatabaseConnection _connection;

  ItemCategoryService(this._connection);

  Router get router => Router()
    ..get('/all', _getItemCategoriesHandler)
    ..post('/', _insertItemCategoryHandler);

  Future<Response> _getItemCategoriesHandler(Request request) async {
    try {
      final languageCode =
          request.requestedUri.queryParameters['language_code'];
      final page =
          int.tryParse(request.requestedUri.queryParameters['page'] ?? '');
      final pageLimit = int.tryParse(
        request.requestedUri.queryParameters['page_limit'] ?? '',
      );

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
      }

      final postgresResult = await _connection.db.query(
        _getItemCategoriesQuery,
        substitutionValues: {
          'language_code': languageCode,
          'page_offset': (page - 1) * pageLimit,
          'page_limit': pageLimit,
        },
      );
      final listResult = postgresResult
          .toList()
          .map((e) => ItemCategory.fromJson(e.toColumnMap()).toJson())
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

  Future<Response> _insertItemCategoryHandler(Request request) async {
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final name = body['name'] as String?;

      if (name == null || name.isEmpty) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.badRequest,
              message: '{name} is required',
            ).toJson(),
          ),
        );
      }

      final postgresResult = await _connection.db.query(
        _insertItemCategoryQuery,
        substitutionValues: {
          'name': name,
        },
      );
      final result = postgresResult.first.toColumnMap();
      return Response.ok(
        headers: headers,
        jsonEncode(
          ResponseWrapper(statusCode: HttpStatus.ok, data: result).toJson(),
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

  static const _getItemCategoriesQuery = '''
    SELECT item_categories.id,
        item_category_l10ns.language_code,
        item_categories.name,
        item_category_l10ns.name AS translated_name
    FROM item_categories
        LEFT JOIN item_category_l10ns ON item_categories.id = item_category_l10ns.category_id
        AND item_category_l10ns.language_code = @language_code
    WHERE (
            SELECT COUNT(*)
            FROM items
            WHERE items.category_id = item_categories.id
        ) > 0
    ORDER BY (
            CASE
                WHEN item_category_l10ns.name IS NOT NULL THEN item_category_l10ns.name
                ELSE item_categories.name
            END
        )
    LIMIT @page_limit OFFSET @page_offset;
    ''';

  static const _insertItemCategoryQuery = '''
    INSERT INTO item_categories (name)
    VALUES (@name)
    RETURNING *;
    ''';
}
