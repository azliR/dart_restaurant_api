import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'firebase.dart';

@immutable
class TokenPayload extends Equatable {
  const TokenPayload({
    this.iss,
    this.aud,
    this.authTime,
    this.userId,
    this.sub,
    this.iat,
    this.exp,
    this.phoneNumber,
    this.email,
    this.emailVerified,
    this.firebase,
  });

  final String? iss;
  final String? aud;
  final int? authTime;
  final String? userId;
  final String? sub;
  final int? iat;
  final int? exp;
  final String? phoneNumber;
  final String? email;
  final bool? emailVerified;
  final Firebase? firebase;

  factory TokenPayload.fromJson(Map<String, dynamic> json) => TokenPayload(
        iss: json['iss'] as String?,
        aud: json['aud'] as String?,
        authTime: json['auth_time'] as int?,
        userId: json['user_id'] as String?,
        sub: json['sub'] as String?,
        iat: json['iat'] as int?,
        exp: json['exp'] as int?,
        phoneNumber: json['phone_number'] as String?,
        email: json['email'] as String?,
        emailVerified: json['email_verified'] as bool?,
        firebase: json['firebase'] == null
            ? null
            : Firebase.fromJson(json['firebase'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'iss': iss,
        'aud': aud,
        'auth_time': authTime,
        'user_id': userId,
        'sub': sub,
        'iat': iat,
        'exp': exp,
        'phone_number': phoneNumber,
        'email': email,
        'email_verified': emailVerified,
        'firebase': firebase?.toJson(),
      };

  @override
  List<Object?> get props {
    return [
      iss,
      aud,
      authTime,
      userId,
      sub,
      iat,
      exp,
      phoneNumber,
      email,
      emailVerified,
      firebase,
    ];
  }
}
