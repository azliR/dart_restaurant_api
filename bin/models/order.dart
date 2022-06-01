import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'enums/enums.dart';
import 'order_detail.dart';

@immutable
class Order extends Equatable {
  const Order({
    required this.id,
    required this.customerId,
    required this.storeId,
    this.storeAccountId,
    this.tableId,
    this.couponId,
    required this.buyer,
    this.storeImage,
    this.storeBanner,
    this.tablePrice,
    required this.brutto,
    required this.netto,
    this.couponCode,
    this.couponName,
    this.discount,
    this.discountNominal,
    required this.status,
    required this.orderType,
    this.scheduledAt,
    required this.pickupType,
    this.rating,
    this.comment,
    this.createdAt,
    this.orderDetails,
  });

  final String id;
  final String customerId;
  final String storeId;
  final String? storeAccountId;
  final String? tableId;
  final String? couponId;
  final String buyer;
  final String? storeImage;
  final String? storeBanner;
  final double? tablePrice;
  final double brutto;
  final double netto;
  final String? couponCode;
  final String? couponName;
  final double? discount;
  final double? discountNominal;
  final OrderStatus status;
  final OrderType orderType;
  final DateTime? scheduledAt;
  final PickupType pickupType;
  final double? rating;
  final String? comment;
  final DateTime? createdAt;
  final List<OrderDetail>? orderDetails;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        customerId: json['customer_id'] as String,
        storeId: json['store_id'] as String,
        storeAccountId: json['store_account_id'] as String?,
        tableId: json['table_id'] as String?,
        couponId: json['coupon_id'] as String?,
        buyer: json['buyer'] as String,
        storeImage: json['store_image'] as String?,
        storeBanner: json['store_banner'] as String?,
        tablePrice: double.parse(json['table_price'] as String),
        brutto: double.parse(json['brutto'] as String),
        netto: double.parse(json['netto'] as String),
        couponCode: json['coupon_code'] as String?,
        couponName: json['coupon_name'] as String?,
        discount: double.parse(json['discount'] as String),
        discountNominal: double.parse(json['discount_nominal'] as String),
        status: OrderStatus.fromString(json['status'] as String),
        orderType: OrderType.fromString(json['order_type'] as String),
        scheduledAt: json['scheduled_at'] == null
            ? null
            : json['scheduled_at'] as DateTime,
        pickupType: PickupType.fromString(json['pickup_type'] as String),
        rating: double.parse(json['rating'] as String),
        comment: json['comment'] as String?,
        createdAt:
            json['created_at'] == null ? null : json['created_at'] as DateTime,
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
    String? storeImage,
    String? storeBanner,
    double? tablePrice,
    double? brutto,
    double? netto,
    String? couponCode,
    String? couponName,
    double? discount,
    double? discountNominal,
    OrderStatus? status,
    OrderType? orderType,
    DateTime? scheduledAt,
    PickupType? pickupType,
    double? rating,
    String? comment,
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
      storeImage: storeImage ?? this.storeImage,
      storeBanner: storeBanner ?? this.storeBanner,
      tablePrice: tablePrice ?? this.tablePrice,
      brutto: brutto ?? this.brutto,
      netto: netto ?? this.netto,
      couponCode: couponCode ?? this.couponCode,
      couponName: couponName ?? this.couponName,
      discount: discount ?? this.discount,
      discountNominal: discountNominal ?? this.discountNominal,
      status: status ?? this.status,
      orderType: orderType ?? this.orderType,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      pickupType: pickupType ?? this.pickupType,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
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
        'store_image': storeImage,
        'store_banner': storeBanner,
        'table_price': tablePrice,
        'brutto': brutto,
        'netto': netto,
        'coupon_code': couponCode,
        'coupon_name': couponName,
        'discount': discount,
        'discount_nominal': discountNominal,
        'status': status.name,
        'order_type': orderType.name,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'pickup_type': pickupType.name,
        'rating': rating,
        'comment': comment,
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
      storeImage,
      storeBanner,
      tablePrice,
      brutto,
      netto,
      couponCode,
      couponName,
      discount,
      discountNominal,
      status,
      orderType,
      scheduledAt,
      pickupType,
      rating,
      comment,
      createdAt,
      orderDetails,
    ];
  }
}
