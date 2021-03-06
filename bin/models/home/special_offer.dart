import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../item/item_addon_category.dart';

@immutable
class SpecialOffer extends Equatable {
  const SpecialOffer({
    required this.id,
    required this.storeId,
    required this.categoryId,
    this.subCategoryId,
    required this.name,
    this.picture,
    required this.price,
    required this.specialOffer,
    this.description,
    this.rating,
    required this.isActive,
    required this.distance,
  });

  final String id;
  final String storeId;
  final String categoryId;
  final String? subCategoryId;
  final String name;
  final String? picture;
  final double price;
  final double specialOffer;
  final String? description;
  final double? rating;
  final bool isActive;
  final double distance;

  factory SpecialOffer.fromJson(Map<String, dynamic> json) => SpecialOffer(
        id: json['id'] as String,
        storeId: json['store_id'] as String,
        categoryId: json['category_id'] as String,
        subCategoryId: json['sub_category_id'] as String?,
        name: json['name'] as String,
        picture: json['picture'] as String?,
        price: double.parse(json['price'] as String),
        specialOffer: double.parse(json['special_offer'] as String),
        description: json['description'] as String?,
        rating: double.tryParse(json['rating'] as String? ?? ''),
        isActive: json['is_active'] as bool,
        distance: json['distance'] as double,
      );

  SpecialOffer copyWith({
    String? id,
    String? storeId,
    String? categoryId,
    String? subCategoryId,
    String? name,
    String? picture,
    double? price,
    double? specialOffer,
    String? description,
    double? rating,
    bool? isActive,
    double? distance,
    List<ItemAddonCategory>? addonCategories,
  }) {
    return SpecialOffer(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      name: name ?? this.name,
      picture: picture ?? this.picture,
      price: price ?? this.price,
      specialOffer: specialOffer ?? this.specialOffer,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      isActive: isActive ?? this.isActive,
      distance: distance ?? this.distance,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'store_id': storeId,
        'category_id': categoryId,
        'sub_category_id': subCategoryId,
        'name': name,
        'picture': picture,
        'price': price,
        'special_offer': specialOffer,
        'description': description,
        'rating': rating,
        'is_active': isActive,
        'distance': distance,
      }..removeWhere(
          (key, value) {
            return key == 'addon_categories' && value == null;
          },
        );

  @override
  List<Object?> get props {
    return [
      id,
      storeId,
      categoryId,
      subCategoryId,
      name,
      picture,
      price,
      specialOffer,
      description,
      rating,
      isActive,
      distance,
    ];
  }
}
