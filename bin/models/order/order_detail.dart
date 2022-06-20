import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'order_detail_addon.dart';

@immutable
class OrderDetail extends Equatable {
  const OrderDetail({
    this.id,
    this.orderId,
    this.itemId,
    this.itemName,
    this.quantity,
    this.price,
    this.total,
    this.picture,
    this.itemDetail,
    this.rating,
    this.comment,
    this.addons,
  });

  final String? id;
  final String? orderId;
  final String? itemId;
  final String? itemName;
  final int? quantity;
  final double? price;
  final double? total;
  final String? picture;
  final String? itemDetail;
  final double? rating;
  final String? comment;
  final List<OrderDetailAddon>? addons;

  factory OrderDetail.fromJson(Map<String, dynamic> json) => OrderDetail(
        id: json['id'] as String?,
        orderId: json['order_id'] as String?,
        itemId: json['item_id'] as String?,
        itemName: json['item_name'] as String?,
        quantity: json['quantity'] as int?,
        price: double.tryParse(json['price'] as String? ?? ''),
        total: double.tryParse(json['total'] as String? ?? ''),
        picture: json['picture'] as String?,
        itemDetail: json['item_detail'] as String?,
        rating: double.tryParse(json['rating'] as String? ?? ''),
        comment: json['comment'] as String?,
        addons: (json['addons'] as List<dynamic>?)
            ?.map((e) => OrderDetailAddon.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  OrderDetail copyWith({
    String? id,
    String? orderId,
    String? itemId,
    String? itemName,
    int? quantity,
    double? price,
    double? total,
    String? picture,
    String? itemDetail,
    double? rating,
    String? comment,
    List<OrderDetailAddon>? addons,
  }) {
    return OrderDetail(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      total: total ?? this.total,
      picture: picture ?? this.picture,
      itemDetail: itemDetail ?? this.itemDetail,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      addons: addons ?? this.addons,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'item_id': itemId,
        'item_name': itemName,
        'quantity': quantity,
        'price': price,
        'total': total,
        'picture': picture,
        'item_detail': itemDetail,
        'rating': rating,
        'comment': comment,
        'addons': addons,
      };

  @override
  List<Object?> get props {
    return [
      id,
      orderId,
      itemId,
      itemName,
      quantity,
      price,
      total,
      picture,
      itemDetail,
      rating,
      comment,
      addons,
    ];
  }
}
