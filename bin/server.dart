import 'dart:developer';
import 'dart:io';

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
  final connection = DatabaseConnection();
  await connection.db.open();

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
      .addHandler(customerService.router.call);

  final orderRoute = const Pipeline()
      .addMiddleware(handleAuth())
      .addHandler(orderService.router.call);

  final storeAccountRoute = const Pipeline()
      .addMiddleware(handleAuth())
      .addHandler(storeAccountService.router.call);

  // final storeOrderRoute = const Pipeline()
  //     .addMiddleware(handleAuth())
  //     .addHandler(storeOrderService.router.call);

  // final storeReportRoute = const Pipeline()
  //     .addMiddleware(handleAuth())
  //     .addHandler(storeReportService.router.call);

  final router = Router()
    ..mount('/api/v1/user/home', homeService.router.call)
    ..mount('/api/v1/user/item', itemService.router.call)
    ..mount('/api/v1/user/item/category', itemCategory.router.call)
    ..mount('/api/v1/user/item/sub_category', itemSubCategory.router.call)
    ..mount('/api/v1/user/store', storeService.router.call)
    ..mount('/api/v1/user/template', templateService.router.call)
    ..mount('/api/v1/store/trend', storeReportService.router.call)
    ..mount('/api/v1/store/order', storeOrderService.router.call)
    ..mount('/api/v1/user', customerRoute)
    ..mount('/api/v1/user/order', orderRoute)
    ..mount('/api/v1/store', storeAccountRoute);

  // Use any available host or container IP (usually `0.0.0.0`).
  // final ip = InternetAddress.anyIPv4;

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  final server = await serve(router.call, '0.0.0.0', port);
  log('Server listening on port ${server.port}');
}
