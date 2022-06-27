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
import '../../models/store/store.dart';

class StoreService {
  final DatabaseConnection _connection;

  StoreService(this._connection);

  Router get router => Router()..get('/<storeId>', _getStoreByIdHandler);

  Future<Response> _getStoreByIdHandler(Request request) async {
    try {
      final storeId = request.params['storeId'];

      if (!isUUID(storeId)) {
        return Response.badRequest(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.badRequest,
              message: '{store_id} query parameter is invalid',
            ).toJson(),
          ),
        );
      }

      final postgresResult = await _connection.db.query(
        _getStoreByIdQuery,
        substitutionValues: {'id': storeId},
      );

      if (postgresResult.isEmpty) {
        return Response.notFound(
          headers: headers,
          jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.notFound,
              message: 'Store not found',
            ).toJson(),
          ),
        );
      }

      return Response.ok(
        headers: headers,
        jsonEncode(
          ResponseWrapper(
            statusCode: HttpStatus.ok,
            data: Store.fromJson(postgresResult.first.toColumnMap()).toJson(),
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
