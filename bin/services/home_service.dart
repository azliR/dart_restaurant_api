import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../common/response_wrapper.dart';
import '../db/connection.dart';
import '../models/item.dart';
import '../models/nearby_store.dart';

class HomeService {
  final DatabaseConnection connection;

  HomeService(this.connection);

  Router get router => Router()
    ..get('/nearby', _getNearbyStoreHandler)
    ..get('/special', _getSpecialOffersHandler);

  Future<Response> _getNearbyStoreHandler(Request request) async {
    final latitude =
        double.tryParse(request.requestedUri.queryParameters['lat'] ?? '');
    final longitude =
        double.tryParse(request.requestedUri.queryParameters['lng'] ?? '');
    final page =
        int.tryParse(request.requestedUri.queryParameters['page'] ?? '');
    final pageLimit =
        int.tryParse(request.requestedUri.queryParameters['page_limit'] ?? '');

    if (page == null || page <= 0) {
      return Response.badRequest(
        headers: {'content-type': 'application/json'},
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 400,
            message: '{page} query parameter is required or invalid',
          ).toJson(),
        ),
      );
    } else if (pageLimit == null || pageLimit <= 0) {
      return Response.badRequest(
        headers: {'content-type': 'application/json'},
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 400,
            message: '{page_limit} query parameter is required or invalid',
          ).toJson(),
        ),
      );
    } else if (latitude == null || longitude == null) {
      return Response.badRequest(
        headers: {'content-type': 'application/json'},
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 400,
            message: '{lat} and {lng} query parameters are required',
          ).toJson(),
        ),
      );
    }

    final postgresResult = await connection.db.query(
      _nearbyStoreQuery,
      substitutionValues: {
        'lat': latitude,
        'lng': longitude,
        'page_offset': ((page - 1) * pageLimit).toString(),
        'page_limit': pageLimit.toString(),
      },
    );
    final listResult = postgresResult
        .toList()
        .map((e) => NearbyStore.fromJson(e.toColumnMap()).toJson())
        .toList();

    return Response.ok(
      headers: {'content-type': 'application/json'},
      jsonEncode(
        ResponseWrapper(
          statusCode: 200,
          data: listResult,
        ).toJson(),
      ),
    );
  }

  Future<Response> _getSpecialOffersHandler(Request request) async {
    final latitude =
        double.tryParse(request.requestedUri.queryParameters['lat'] ?? '');
    final longitude =
        double.tryParse(request.requestedUri.queryParameters['lng'] ?? '');
    final page =
        int.tryParse(request.requestedUri.queryParameters['page'] ?? '');
    final pageLimit =
        int.tryParse(request.requestedUri.queryParameters['page_limit'] ?? '');

    if (page == null || page <= 0) {
      return Response.badRequest(
        headers: {'content-type': 'application/json'},
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 400,
            message: '{page} query parameter is required or invalid',
          ).toJson(),
        ),
      );
    } else if (pageLimit == null || pageLimit <= 0) {
      return Response.badRequest(
        headers: {'content-type': 'application/json'},
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 400,
            message: '{page_limit} query parameter is required or invalid',
          ).toJson(),
        ),
      );
    } else if (latitude == null || longitude == null) {
      return Response.badRequest(
        headers: {'content-type': 'application/json'},
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 400,
            message: '{lat} and {lng} query parameters are required',
          ).toJson(),
        ),
      );
    }

    final postgresResult = await connection.db.query(
      _specialOffersQuery,
      substitutionValues: {
        'lat': latitude,
        'lng': longitude,
        'page_offset': ((page - 1) * pageLimit).toString(),
        'page_limit': pageLimit.toString(),
      },
    );
    final listResult = postgresResult
        .toList()
        .map((e) => Item.fromJson(e.toColumnMap()).toJson())
        .toList();

    return Response.ok(
      jsonEncode(
        ResponseWrapper(
          statusCode: 200,
          data: listResult,
        ).toJson(),
      ),
      headers: {
        'content-type': 'application/json',
      },
    );
  }

  static const _nearbyStoreQuery = '''
    SELECT nearby_stores.*,
        postcodes.city,
        postcodes.state,
        postcodes.country
    FROM (
            SELECT *,
                (
                    6371 * acos(
                        cos(radians(@lat)) * cos(radians(latitude)) * cos(
                            radians(longitude) - radians(@lng)
                        ) + sin(radians(@lat)) * sin(radians(latitude))
                    )
                ) AS distance
            FROM stores
        ) nearby_stores
        LEFT JOIN postcodes ON nearby_stores.postcode = postcodes.postcode
    WHERE distance <= 5
    ORDER BY distance
    LIMIT @page_limit OFFSET @page_offset
    ''';

  static const _specialOffersQuery = '''
    SELECT items.*
    FROM (
            SELECT *,
                (
                    6371 * acos(
                        cos(radians(@lat)) * cos(radians(latitude)) * cos(
                            radians(longitude) - radians(@lng)
                        ) + sin(radians(@lat)) * sin(radians(latitude))
                    )
                ) AS distance
            FROM stores
        ) nearby_stores,
        items
    WHERE nearby_stores.distance <= 5
        AND items.store_id = nearby_stores.id
        AND items.special_offer IS NOT NULL
    ORDER BY distance
    LIMIT @page_limit OFFSET @page_offset;
  ''';
}
