import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class Customer extends Equatable {
  const Customer({
    this.id,
    this.fullName,
    this.phone,
    this.languageCode,
    this.createdAt,
  });

  final String? id;
  final String? fullName;
  final String? phone;
  final String? languageCode;
  final DateTime? createdAt;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String?,
        fullName: json['full_name'] as String?,
        phone: json['phone'] as String?,
        languageCode: json['language_code'] as String?,
        createdAt: json['created_at'] as DateTime?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'language_code': languageCode,
        'created_at': createdAt?.toIso8601String(),
      };

  @override
  List<Object?> get props {
    return [
      id,
      fullName,
      phone,
      languageCode,
      createdAt,
    ];
  }
}
