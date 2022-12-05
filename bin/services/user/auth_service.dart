// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';

// import 'package:postgres/postgres.dart';
// import 'package:shelf/shelf.dart';
// import 'package:shelf_router/shelf_router.dart';

// import '../../common/constants.dart';
// import '../../common/response_wrapper.dart';
// import '../../db/connection.dart';
// import '../../models/auth/customer.dart';

// class AuthService {
//   AuthService(this._connection);

//   final DatabaseConnection _connection;

//   Router get router => Router()..post('/auth', _loginCustomerHandler);

//   Future<Response> _loginCustomerHandler(Request request) async {
//     try {
//       final body =
//           jsonDecode(await request.readAsString()) as Map<String, dynamic>;
//       final token = body['token'] as String?;

//       if (token == null) {
//         return Response(
//           HttpStatus.unauthorized,
//           headers: headers,
//           body: jsonEncode(
//             ResponseWrapper(
//               message: 'Unauthorized',
//               statusCode: HttpStatus.unauthorized,
//             ).toJson(),
//           ),
//         );
//       }

//       final jwt = await verifyFirebaseToken(token);
//       final tokenPayload =
//           TokenPayload.fromJson(jwt.payload as Map<String, dynamic>);

//       final loginResult = await _connection.db.query(
//         _loginCustomerQuery,
//         substitutionValues: {
//           'phone': tokenPayload.phoneNumber,
//         },
//       );

//       if (loginResult.isEmpty) {
//         final postgresResult = await _connection.db.query(
//           _createCustomerQuery,
//           substitutionValues: {
//             'full_name': '',
//             'phone': tokenPayload.phoneNumber,
//             'language_code': 'en',
//           },
//         );
//         if (postgresResult.isEmpty) {
//           return Response.internalServerError(
//             headers: headers,
//             body: jsonEncode(
//               ResponseWrapper(
//                 statusCode: HttpStatus.internalServerError,
//                 message: 'Customer not created',
//               ).toJson(),
//             ),
//           );
//         }

//         final customer = postgresResult.first;
//         return Response.ok(
//           headers: headers,
//           jsonEncode(
//             ResponseWrapper(
//               statusCode: HttpStatus.ok,
//               data: Customer.fromJson(customer.toColumnMap()),
//             ).toJson(),
//           ),
//         );
//       } else {
//         return Response.ok(
//           headers: headers,
//           jsonEncode(
//             ResponseWrapper(
//               statusCode: HttpStatus.ok,
//               data: Customer.fromJson(loginResult.first.toColumnMap()),
//             ).toJson(),
//           ),
//         );
//       }
//     } on PostgreSQLException catch (e, stackTrace) {
//       log(e.toString(), stackTrace: stackTrace);
//       return Response.internalServerError(
//         headers: headers,
//         body: jsonEncode(
//           ResponseWrapper(
//             statusCode: HttpStatus.internalServerError,
//             message: e.message,
//           ).toJson(),
//         ),
//       );
//     } catch (e, stackTrace) {
//       log(e.toString(), stackTrace: stackTrace);
//       return Response.internalServerError(
//         headers: headers,
//         body: jsonEncode(
//           ResponseWrapper(
//             statusCode: HttpStatus.internalServerError,
//             message: e.toString(),
//           ).toJson(),
//         ),
//       );
//     }
//   }

//   static const _loginCustomerQuery = '''
//     SELECT *
//     FROM customers
//     WHERE phone = @phone
//     ''';
// }
