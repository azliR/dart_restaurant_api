import 'dart:developer';
import 'dart:io';

import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'db/connection.dart';
import 'services/customer_service.dart';
import 'services/home_service.dart';
import 'services/item_category_service.dart';
import 'services/item_service.dart';
import 'services/item_sub_category_service.dart';
import 'services/order_service.dart';
import 'services/store_service.dart';
import 'services/template_service.dart';

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

  final router = Router()
    ..mount('/api/v1/home', homeService.router)
    ..mount('/api/v1/item', itemService.router)
    ..mount('/api/v1/item/category', itemCategory.router)
    ..mount('/api/v1/item/sub_category', itemSubCategory.router)
    ..mount('/api/v1/store', storeService.router)
    ..mount('/api/v1/user/customer', customerService.router)
    ..mount('/api/v1/user/order', orderService.router)
    ..mount('/api/v1/user/template', templateService.router);

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(router, ip, port);
  log('Server listening on port ${server.port}');
}
