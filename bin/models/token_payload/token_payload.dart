import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'firebase.dart';

@immutable
class TokenPayload extends Equatable {
  const TokenPayload({
    this.issuer,
    this.audience,
    this.authTime,
    this.userId,
    this.subject,
    this.issuedAt,
    this.expire,
    this.phoneNumber,
    this.email,
    this.emailVerified,
    this.firebase,
  });

  final String? issuer;
  final String? audience;
  final int? authTime;
  final String? userId;
  final String? subject;
  final int? issuedAt;
  final int? expire;
  final String? phoneNumber;
  final String? email;
  final bool? emailVerified;
  final Firebase? firebase;

  factory TokenPayload.fromJson(Map<String, dynamic> json) => TokenPayload(
        issuer: json['iss'] as String?,
        audience: json['aud'] as String?,
        authTime: json['auth_time'] as int?,
        userId: json['user_id'] as String?,
        subject: json['sub'] as String?,
        issuedAt: json['iat'] as int?,
        expire: json['exp'] as int?,
        phoneNumber: json['phone_number'] as String?,
        email: json['email'] as String?,
        emailVerified: json['email_verified'] as bool?,
        firebase: json['firebase'] == null
            ? null
            : Firebase.fromJson(json['firebase'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'iss': issuer,
        'aud': audience,
        'auth_time': authTime,
        'user_id': userId,
        'sub': subject,
        'iat': issuedAt,
        'exp': expire,
        'phone_number': phoneNumber,
        'email': email,
        'email_verified': emailVerified,
        'firebase': firebase?.toJson(),
      };

  @override
  List<Object?> get props {
    return [
      issuer,
      audience,
      authTime,
      userId,
      subject,
      issuedAt,
      expire,
      phoneNumber,
      email,
      emailVerified,
      firebase,
    ];
  }
}
