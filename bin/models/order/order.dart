import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../enums/enums.dart';
import 'order_detail.dart';

@immutable
class Order extends Equatable {
  const Order({
    this.id,
    this.customerId,
    this.storeId,
    this.storeAccountId,
    this.tableId,
    this.couponId,
    this.buyer,
    this.storeName,
    this.storeImage,
    this.tableName,
    this.tablePrice,
    this.couponCode,
    this.couponName,
    this.discount,
    this.discountType,
    this.discountNominal,
    this.brutto,
    this.netto,
    this.status,
    this.orderType,
    this.scheduledAt,
    this.pickupType,
    this.createdAt,
    this.orderDetails,
  });

  final String? id;
  final String? customerId;
  final String? storeId;
  final String? storeAccountId;
  final String? tableId;
  final String? couponId;
  final String? buyer;
  final String? storeName;
  final String? storeImage;
  final String? tableName;
  final double? tablePrice;
  final String? couponCode;
  final String? couponName;
  final double? discount;
  final DiscountType? discountType;
  final double? discountNominal;
  final double? brutto;
  final double? netto;
  final OrderStatus? status;
  final OrderType? orderType;
  final DateTime? scheduledAt;
  final PickupType? pickupType;
  final DateTime? createdAt;
  final List<OrderDetail>? orderDetails;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String?,
        customerId: json['customer_id'] as String?,
        storeId: json['store_id'] as String?,
        storeAccountId: json['store_account_id'] as String?,
        tableId: json['table_id'] as String?,
        couponId: json['coupon_id'] as String?,
        buyer: json['buyer'] as String?,
        storeName: json['store_name'] as String?,
        storeImage: json['store_image'] as String?,
        tableName: json['table_name'] as String?,
        tablePrice: double.tryParse(json['table_price'] as String? ?? ''),
        couponCode: json['coupon_code'] as String?,
        couponName: json['coupon_name'] as String?,
        discount: double.tryParse(json['discount'] as String? ?? ''),
        discountType: json['discount_type'] == null
            ? null
            : DiscountType.fromString(json['discount_type'] as String),
        discountNominal:
            double.tryParse(json['discount_nominal'] as String? ?? ''),
        brutto: double.tryParse(json['brutto'] as String? ?? ''),
        netto: double.tryParse(json['netto'] as String? ?? ''),
        status: json['status'] == null
            ? null
            : OrderStatus.fromString(json['status'] as String),
        orderType: json['order_type'] == null
            ? null
            : OrderType.fromString(json['order_type'] as String),
        scheduledAt: json['scheduled_at'] == null
            ? null
            : json['scheduled_at'] as DateTime,
        pickupType: json['pickup_type'] == null
            ? null
            : PickupType.fromString(json['pickup_type'] as String),
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
        orderDetails: (json['order_details'] as List<dynamic>?)
            ?.map((e) => OrderDetail.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Order copyWith({
    String? id,
    String? customerId,
    String? storeId,
    String? storeAccountId,
    String? tableId,
    String? couponId,
    String? buyer,
    String? storeName,
    String? storeImage,
    String? tableName,
    double? tablePrice,
    String? couponCode,
    String? couponName,
    double? discount,
    DiscountType? discountType,
    double? discountNominal,
    double? brutto,
    double? netto,
    OrderStatus? status,
    OrderType? orderType,
    DateTime? scheduledAt,
    PickupType? pickupType,
    DateTime? createdAt,
    List<OrderDetail>? orderDetails,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      storeId: storeId ?? this.storeId,
      storeAccountId: storeAccountId ?? this.storeAccountId,
      tableId: tableId ?? this.tableId,
      couponId: couponId ?? this.couponId,
      buyer: buyer ?? this.buyer,
      storeName: storeName ?? this.storeName,
      storeImage: storeImage ?? this.storeImage,
      tableName: tableName ?? this.tableName,
      tablePrice: tablePrice ?? this.tablePrice,
      couponCode: couponCode ?? this.couponCode,
      couponName: couponName ?? this.couponName,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      discountNominal: discountNominal ?? this.discountNominal,
      brutto: brutto ?? this.brutto,
      netto: netto ?? this.netto,
      status: status ?? this.status,
      orderType: orderType ?? this.orderType,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      pickupType: pickupType ?? this.pickupType,
      createdAt: createdAt ?? this.createdAt,
      orderDetails: orderDetails ?? this.orderDetails,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'store_id': storeId,
        'store_account_id': storeAccountId,
        'table_id': tableId,
        'coupon_id': couponId,
        'buyer': buyer,
        'store_name': storeName,
        'store_image': storeImage,
        'table_name': tableName,
        'table_price': tablePrice,
        'coupon_code': couponCode,
        'coupon_name': couponName,
        'discount': discount,
        'discount_type': discountType?.toString(),
        'discount_nominal': discountNominal,
        'brutto': brutto,
        'netto': netto,
        'status': status?.name,
        'order_type': orderType?.name,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'pickup_type': pickupType?.name,
        'created_at': createdAt?.toIso8601String(),
        'order_details': orderDetails,
      }..removeWhere((key, value) => key == 'order_details' && value == null);

  @override
  List<Object?> get props {
    return [
      id,
      customerId,
      storeId,
      storeAccountId,
      tableId,
      couponId,
      buyer,
      storeName,
      storeImage,
      tableName,
      tablePrice,
      couponCode,
      couponName,
      discount,
      discountType,
      discountNominal,
      brutto,
      netto,
      status,
      orderType,
      scheduledAt,
      pickupType,
      createdAt,
      orderDetails,
    ];
  }
}
