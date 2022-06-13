import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class ItemAddon extends Equatable {
  const ItemAddon({
    this.id,
    this.addonCategoryId,
    this.name,
    this.price,
  });

  final String? id;
  final String? addonCategoryId;
  final String? name;
  final double? price;

  factory ItemAddon.fromJson(Map<String, dynamic> json) => ItemAddon(
        id: json['id'] as String?,
        addonCategoryId: json['addon_category_id'] as String?,
        name: json['name'] as String?,
        price: double.tryParse(json['price'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'addon_category_id': addonCategoryId,
        'name': name,
        'price': price,
      };

  @override
  List<Object?> get props => [id, addonCategoryId, name, price];
}
