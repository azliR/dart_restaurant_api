import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../common/constants.dart';
import '../common/response_wrapper.dart';
import '../db/connection.dart';
import '../models/item/item_category.dart';

class ItemCategoryService {
  final DatabaseConnection connection;

  ItemCategoryService(this.connection);

  Router get router => Router()..get('/all', _getItemCategoriesHandler);

  Future<Response> _getItemCategoriesHandler(Request request) async {
    final languageCode = request.requestedUri.queryParameters['language_code'];
    final page =
        int.tryParse(request.requestedUri.queryParameters['page'] ?? '');
    final pageLimit =
        int.tryParse(request.requestedUri.queryParameters['page_limit'] ?? '');

    if (page == null || page <= 0) {
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
        ResponseWrapper(statusCode: 200, data: listResult).toJson(),
      ),
    );
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
}
