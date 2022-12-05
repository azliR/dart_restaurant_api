// import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
// import 'package:shelf/shelf.dart';
// import 'package:shelf_router/shelf_router.dart';

// import './utils.dart';

// class UserApi {
//   UserApi();

//   Handler get router {
//     final router = Router();

//     router.get('/', (Request req) async {
//       final authDetails = req.context['authDetails'] as JWT?;
//       print(authDetails);
//       // final user = await store.findOne(
//       //     where.eq('_id', ObjectId.fromHexString(authDetails.subject!)));

//       // if (user == null) {
//       //   return Response.notFound('User details not found');
//       // }

//       return Response.ok('{ "email":  }', headers: {
//         'content-type': 'application/json',
//       });
//     });

//     final handler =
//         const Pipeline().addMiddleware(checkAuthorisation()).addHandler(router);

//     return handler;
//   }
// }
