import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'item_addon.dart';

@immutable
class ItemCategory extends Equatable {
  const ItemCategory({
    required this.id,
    this.languageCode,
    required this.name,
    this.translatedName,
    this.addons,
  });

  final String id;
  final String? languageCode;
  final String name;
  final String? translatedName;
  final List<ItemAddon>? addons;

  factory ItemCategory.fromJson(Map<String, dynamic> json) => ItemCategory(
        id: json['id'] as String,
        languageCode: json['language_code'] as String?,
        name: json['name'] as String,
        translatedName: json['translated_name'] as String?,
        addons: (json['addons'] as List<dynamic>?)
            ?.map((e) => ItemAddon.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  ItemCategory copyWith({
    String? id,
    String? languageCode,
    String? name,
    String? translatedName,
    List<ItemAddon>? addons,
  }) {
    return ItemCategory(
      id: id ?? this.id,
      languageCode: languageCode ?? this.languageCode,
      name: name ?? this.name,
      translatedName: translatedName ?? this.translatedName,
      addons: addons ?? this.addons,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'language_code': languageCode,
        'name': name,
        'translated_name': translatedName,
        'addons': addons,
      };

  @override
  List<Object?> get props {
    return [
      id,
      languageCode,
      name,
      translatedName,
      addons,
    ];
  }
}
