import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../enums/enums.dart';

@immutable
class StoreAdmin extends Equatable {
  const StoreAdmin({
    this.id,
    this.fullName,
    this.email,
    this.role,
    this.languageCode,
    this.createdAt,
  });

  final String? id;
  final String? fullName;
  final String? email;
  final StoreRole? role;
  final String? languageCode;
  final DateTime? createdAt;

  factory StoreAdmin.fromJson(Map<String, dynamic> json) => StoreAdmin(
        id: json['id'] as String?,
        fullName: json['full_name'] as String?,
        email: json['email'] as String?,
        role: StoreRole.fromString(json['role'] as String?),
        languageCode: json['language_code'] as String?,
        createdAt: json['created_at'] as DateTime?,
      );

  StoreAdmin copyWith({
    String? id,
    String? fullName,
    String? email,
    StoreRole? role,
    String? languageCode,
    DateTime? createdAt,
  }) {
    return StoreAdmin(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      languageCode: languageCode ?? this.languageCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'role': role?.name,
        'language_code': languageCode,
        'created_at': createdAt?.toIso8601String(),
      };

  @override
  List<Object?> get props {
    return [
      id,
      fullName,
      email,
      role,
      languageCode,
      createdAt,
    ];
  }
}
