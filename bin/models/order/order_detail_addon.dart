import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class OrderDetailAddon extends Equatable {
  const OrderDetailAddon({
    this.id,
    this.orderDetailId,
    this.addonId,
    this.addonName,
    this.addonPrice,
  });

  final String? id;
  final String? orderDetailId;
  final String? addonId;
  final String? addonName;
  final double? addonPrice;

  factory OrderDetailAddon.fromJson(Map<String, dynamic> json) =>
      OrderDetailAddon(
        id: json['id'] as String?,
        orderDetailId: json['order_detail_id'] as String?,
        addonId: json['addon_id'] as String?,
        addonName: json['addon_name'] as String?,
        addonPrice: double.tryParse(json['addon_price'] as String? ?? ''),
      );

  OrderDetailAddon copyWith({
    String? id,
    String? orderDetailId,
    String? addonId,
    String? addonName,
    double? addonPrice,
  }) {
    return OrderDetailAddon(
      id: id ?? this.id,
      orderDetailId: orderDetailId ?? this.orderDetailId,
      addonId: addonId ?? this.addonId,
      addonName: addonName ?? this.addonName,
      addonPrice: addonPrice ?? this.addonPrice,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_detail_id': orderDetailId,
        'addon_id': addonId,
        'addon_name': addonName,
        'addon_price': addonPrice,
      };

  @override
  List<Object?> get props =>
      [id, orderDetailId, addonId, addonName, addonPrice];
}
