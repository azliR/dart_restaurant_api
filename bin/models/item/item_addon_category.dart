import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'item_addon.dart';

@immutable
class ItemAddonCategory extends Equatable {
  const ItemAddonCategory({
    this.id,
    this.itemId,
    this.name,
    this.description,
    this.isMultipleChoice,
    this.addons,
  });

  final String? id;
  final String? itemId;
  final String? name;
  final String? description;
  final bool? isMultipleChoice;
  final List<ItemAddon>? addons;

  factory ItemAddonCategory.fromJson(Map<String, dynamic> json) =>
      ItemAddonCategory(
        id: json['id'] as String,
        itemId: json['item_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        isMultipleChoice: json['is_multiple_choice'] as bool,
        addons: (json['addons'] as List<dynamic>?)
            ?.map((e) => ItemAddon.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  ItemAddonCategory copyWith({
    String? id,
    String? itemId,
    String? name,
    String? description,
    bool? isMultipleChoice,
    List<ItemAddon>? addons,
  }) {
    return ItemAddonCategory(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      description: description ?? this.description,
      isMultipleChoice: isMultipleChoice ?? this.isMultipleChoice,
      addons: addons ?? this.addons,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_id': itemId,
        'name': name,
        'description': description,
        'is_multiple_choice': isMultipleChoice,
        'addons': addons,
      };

  @override
  List<Object?> get props {
    return [
      id,
      itemId,
      name,
      description,
      isMultipleChoice,
      addons,
    ];
  }
}
