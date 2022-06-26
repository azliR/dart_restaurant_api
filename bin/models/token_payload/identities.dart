import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class Identities extends Equatable {
  const Identities({
    this.phone,
    this.email,
  });

  final List<String>? phone;
  final List<String>? email;

  factory Identities.fromJson(Map<String, dynamic> json) => Identities(
        phone: (json['phone'] as List<dynamic>?)?.cast<String>(),
        email: (json['email'] as List<dynamic>?)?.cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'email': email,
      };

  @override
  List<Object?> get props => [phone, email];
}
