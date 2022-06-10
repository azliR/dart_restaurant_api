import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../common/constants.dart';
import '../common/response_wrapper.dart';
import '../db/connection.dart';
import '../models/home/nearby_store.dart';
import '../models/home/special_offer.dart';

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
    final pageLimit =
        int.tryParse(request.requestedUri.queryParameters['page_limit'] ?? '');

    if (pageLimit == null || pageLimit <= 0) {
      return Response.badRequest(
        headers: headers,
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 400,
            message: '{page_limit} query parameter is required or invalid',
          ).toJson(),
        ),
      );
    } else if (latitude == null || longitude == null) {
      return Response.badRequest(
        headers: headers,
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
        'page_limit': pageLimit.toString(),
      },
    );
    final listResult = postgresResult
        .toList()
        .map((e) => NearbyStore.fromJson(e.toColumnMap()).toJson())
        .toList();

    return Response.ok(
      headers: headers,
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
    final pageLimit =
        int.tryParse(request.requestedUri.queryParameters['page_limit'] ?? '');

    if (pageLimit == null || pageLimit <= 0) {
      return Response.badRequest(
        headers: headers,
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 400,
            message: '{page_limit} query parameter is required or invalid',
          ).toJson(),
        ),
      );
    } else if (latitude == null || longitude == null) {
      return Response.badRequest(
        headers: headers,
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
        'page_limit': pageLimit.toString(),
      },
    );
    final listResult = postgresResult
        .toList()
        .map((e) => SpecialOffer.fromJson(e.toColumnMap()).toJson())
        .toList();

    return Response.ok(
      jsonEncode(
        ResponseWrapper(
          statusCode: 200,
          data: listResult,
        ).toJson(),
      ),
      headers: headers,
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
    LIMIT @page_limit
    ''';

  static const _specialOffersQuery = '''
    SELECT items.*,
        nearby_stores.distance
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
    LIMIT @page_limit
  ''';
}
