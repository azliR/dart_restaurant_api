import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:validators/validators.dart';

import '../common/response_wrapper.dart';
import '../db/connection.dart';
import '../models/store.dart';

class StoreService {
  final DatabaseConnection connection;

  StoreService(this.connection);

  Router get router => Router()..get('/<storeId>', _getStoreByIdHandler);

  Future<Response> _getStoreByIdHandler(Request request) async {
    final storeId = request.params['storeId'];

    if (!isUUID(storeId)) {
      return Response.badRequest(
        headers: {'content-type': 'application/json'},
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 400,
            message: '{store_id} query parameter is invalid',
          ).toJson(),
        ),
      );
    }

    final postgresResult = await connection.db.query(
      _getStoreByIdQuery,
      substitutionValues: {'id': storeId},
    );

    if (postgresResult.isEmpty) {
      return Response.notFound(
        headers: {'content-type': 'application/json'},
        jsonEncode(
          ResponseWrapper(
            statusCode: 404,
            message: 'Store not found',
          ).toJson(),
        ),
      );
    } else if (postgresResult.length > 1) {
      return Response.internalServerError(
        headers: {'content-type': 'application/json'},
        body: jsonEncode(
          ResponseWrapper(
            statusCode: 500,
            message: 'Multiple stores found',
          ).toJson(),
        ),
      );
    }

    return Response.ok(
      headers: {'content-type': 'application/json'},
      jsonEncode(
        ResponseWrapper(
          statusCode: 200,
          data: Store.fromJson(postgresResult.first.toColumnMap()).toJson(),
        ).toJson(),
      ),
    );
  }

  static const _getStoreByIdQuery = '''
    SELECT stores.*,
        postcodes.city,
        postcodes.state,
        postcodes.country
    FROM stores
        JOIN postcodes ON stores.postcode = postcodes.postcode
    WHERE stores.id = @id;
    ''';
}
