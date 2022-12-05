import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class NearbyStore extends Equatable {
  const NearbyStore({
    this.id,
    this.storeAdminId,
    this.name,
    this.description,
    this.image,
    this.banner,
    this.phone,
    this.streetAddress,
    this.postcode,
    this.latitude,
    this.longitude,
    this.rating,
    this.isActive,
    this.distance,
    this.city,
    this.state,
    this.country,
    this.totalPerson,
  });

  final String? id;
  final String? storeAdminId;
  final String? name;
  final String? description;
  final String? image;
  final String? banner;
  final String? phone;
  final String? streetAddress;
  final String? postcode;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final bool? isActive;
  final double? distance;
  final String? city;
  final String? state;
  final String? country;
  final int? totalPerson;

  factory NearbyStore.fromJson(Map<String, dynamic> json) => NearbyStore(
        id: json['id'] as String?,
        storeAdminId: json['store_admin_id'] as String?,
        name: json['name'] as String?,
        description: json['description'] as String?,
        image: json['image'] as String?,
        banner: json['banner'] as String?,
        phone: json['phone'] as String?,
        streetAddress: json['street_address'] as String?,
        postcode: json['postcode'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        rating: double.tryParse(json['rating'] as String? ?? ''),
        isActive: json['is_active'] as bool?,
        distance: (json['distance'] as num?)?.toDouble(),
        city: json['city'] as String?,
        state: json['state'] as String?,
        country: json['country'] as String?,
        totalPerson: json['total_person'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'store_admin_id': storeAdminId,
        'name': name,
        'description': description,
        'image': image,
        'banner': banner,
        'phone': phone,
        'street_address': streetAddress,
        'postcode': postcode,
        'latitude': latitude,
        'longitude': longitude,
        'rating': rating,
        'is_active': isActive,
        'distance': distance,
        'city': city,
        'state': state,
        'country': country,
        'total_person': totalPerson,
      };

  @override
  List<Object?> get props {
    return [
      id,
      storeAdminId,
      name,
      description,
      image,
      banner,
      phone,
      streetAddress,
      postcode,
      latitude,
      longitude,
      rating,
      isActive,
      distance,
      city,
      state,
      country,
      totalPerson,
    ];
  }
}
