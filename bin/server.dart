import 'dart:developer';
import 'dart:io';

import 'package:firebase_dart/firebase_dart.dart' hide AuthProvider;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'db/connection.dart';
import 'db/utils.dart';
import 'services/store/store_account_service.dart';
import 'services/store/store_order_service.dart';
import 'services/store/store_report_service.dart';
import 'services/user/customer_service.dart';
import 'services/user/home_service.dart';
import 'services/user/item_category_service.dart';
import 'services/user/item_service.dart';
import 'services/user/item_sub_category_service.dart';
import 'services/user/order_service.dart';
import 'services/user/store_service.dart';
import 'services/user/template_service.dart';

void main(List<String> args) async {
  // const secret = Env.secretKey;
  // const redisHost = Env.redisHost;
  // const redisPassword = Env.redisPassword;
  // const redisPort = Env.redisPort;

  // final redisConnection = RedisConnection();

  // final tokenService = TokenService(redisConnection, secret);
  // tokenService.start(host: redisHost, password: redisPassword, port: redisPort);

  final connection = DatabaseConnection();
  await connection.db.open();

  FirebaseDart.setup();

  final app = await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDAPN8WUX40-3ZWhf0QVvcneivvyLiDuS4",
      authDomain: "restaurant-70076.firebaseapp.com",
      projectId: "restaurant-70076",
      storageBucket: "restaurant-70076.appspot.com",
      messagingSenderId: "604627191517",
      appId: "1:604627191517:web:b3c4fcbbde7efb64307d34",
      measurementId: "G-YGCRL9Y53X",
    ),
  );

  final firebaseAuth = FirebaseAuth.instanceFor(app: app);

  final homeService = HomeService(connection);
  final itemService = ItemService(connection);
  final itemCategory = ItemCategoryService(connection);
  final itemSubCategory = ItemSubCategoryService(connection);
  final storeService = StoreService(connection);
  final customerService = CustomerService(connection);
  final orderService = OrderService(connection);
  final templateService = TemplateService(connection);

  final storeAccountService = StoreAccountService(connection);
  final storeOrderService = StoreOrderService(connection);
  final storeReportService = StoreReportService(connection);

  final customerRoute = const Pipeline()
      .addMiddleware(handleAuth())
      .addHandler(customerService.router);

  final orderRoute = const Pipeline()
      .addMiddleware(handleAuth())
      .addHandler(orderService.router);

  final storeAccountRoute = const Pipeline()
      .addMiddleware(handleAuth())
      .addHandler(storeAccountService.router);

  final storeOrderRoute = const Pipeline()
      .addMiddleware(handleAuth())
      .addHandler(storeOrderService.router);

  final storeReportRoute = const Pipeline()
      .addMiddleware(handleAuth())
      .addHandler(storeReportService.router);

  final router = Router()
    ..mount('/api/v1/user/home', homeService.router)
    ..mount('/api/v1/user/item', itemService.router)
    ..mount('/api/v1/user/item/category', itemCategory.router)
    ..mount('/api/v1/user/item/sub_category', itemSubCategory.router)
    ..mount('/api/v1/user/store', storeService.router)
    ..mount('/api/v1/user/template', templateService.router)
    ..mount('/api/v1/store/trend', storeReportService.router)
    ..mount('/api/v1/store/order', storeOrderService.router)
    ..mount('/api/v1/user', customerRoute)
    ..mount('/api/v1/user/order', orderRoute)
    ..mount('/api/v1/store', storeAccountRoute);

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  final server = await serve(router, '0.0.0.0', port);
  log('Server listening on port ${server.port}');
}
