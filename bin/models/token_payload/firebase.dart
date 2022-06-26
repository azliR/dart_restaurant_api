import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'identities.dart';

@immutable
class Firebase extends Equatable {
  const Firebase({this.identities, this.signInProvider});

  final Identities? identities;
  final String? signInProvider;

  factory Firebase.fromJson(Map<String, dynamic> json) => Firebase(
        identities: json['identities'] == null
            ? null
            : Identities.fromJson(json['identities'] as Map<String, dynamic>),
        signInProvider: json['sign_in_provider'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'identities': identities?.toJson(),
        'sign_in_provider': signInProvider,
      };

  @override
  List<Object?> get props => [identities, signInProvider];
}
