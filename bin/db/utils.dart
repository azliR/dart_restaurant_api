import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';
import 'package:shelf/shelf.dart';

import '../common/constants.dart';
import '../common/response_wrapper.dart';

// Middleware handleCors() {
//   return createMiddleware(
//     requestHandler: (Request request) {
//       if (request.method == 'OPTIONS') {
//         return Response.ok('', headers: headers);
//       }
//       return null;
//     },
//     responseHandler: (Response response) {
//       return response.change(headers: headers);
//     },
//   );
// }

// String generateSalt([int length = 32]) {
//   final rand = Random.secure();
//   final saltBytes = List<int>.generate(length, (_) => rand.nextInt(256));
//   return base64.encode(saltBytes);
// }

// String hashPassword(String password, String salt) {
//   const codec = Utf8Codec();
//   final key = codec.encode(password);
//   final saltBytes = codec.encode(salt);
//   final hmac = Hmac(sha256, key);
//   final digest = hmac.convert(saltBytes);
//   return digest.toString();
// }

// String generateJwt({
//   required String subject,
//   required String issuer,
//   required String secret,
//   required String jwtId,
//   required Duration expiry,
// }) {
//   final jwt = JWT(
//     {
//       'iat': DateTime.now().millisecondsSinceEpoch,
//     },
//     subject: subject,
//     issuer: issuer,
//     jwtId: jwtId,
//   );
//   return jwt.sign(SecretKey(secret), expiresIn: expiry);
// }

String base64Padded(String value) {
  final lenght = value.length;

  switch (lenght % 4) {
    case 2:
      return value.padRight(lenght + 2, '=');
    case 3:
      return value.padRight(lenght + 1, '=');
    default:
      return value;
  }
}

Future<JWT> verifyFirebaseToken(String token) async {
  final response = await http.get(
    Uri.parse(
      'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com',
    ),
  );
  final keys = jsonDecode(response.body) as Map<String, dynamic>;
  const audience = 'restaurant-70076';
  const issuer = 'https://securetoken.google.com/restaurant-70076';

  final jsonBase64 = json.fuse(utf8.fuse(base64Url));
  final parts = token.split('.');
  final header = jsonBase64.decode(base64Padded(parts[0]));

  if (header == null || header is! Map<String, dynamic>) {
    throw JWTException('Invalid header');
  }

  if (header['typ'] != 'JWT') {
    throw JWTException('The given token is not a JWT');
  }

  final body = utf8.encode('${parts[0]}.${parts[1]}');
  final signature = base64Url.decode(base64Padded(parts[2]));

  final jsonWebKey = JsonWebKey.fromPem(keys[header['kid']] as String);

  final payloadBase64 = parts[1];
  final normalizedPayload = base64.normalize(payloadBase64);
  final payloadString = utf8.decode(base64.decode(normalizedPayload));
  final payload = jsonDecode(payloadString) as Map<String, dynamic>;

  if (!jsonWebKey.verify(body, signature, algorithm: header['alg'] as String)) {
    throw JWTException('Invalid signature');
  }

  if (payload.containsKey('exp')) {
    final exp =
        DateTime.fromMillisecondsSinceEpoch((payload['exp'] as int) * 1000);
    if (!exp.isAfter(DateTime.now())) {
      throw JWTException('Token expired');
    }
  }

  if (!payload.containsKey('iat')) {
    throw JWTException('Invalid token');
  }
  final iat =
      DateTime.fromMillisecondsSinceEpoch((payload['iat'] as int) * 1000);
  if (!iat.isBefore(DateTime.now())) {
    throw JWTException('Invalid issued at time');
  }

  if (!payload.containsKey('auth_time')) {
    throw JWTException('Invalid token');
  }
  final authTime =
      DateTime.fromMillisecondsSinceEpoch((payload['auth_time'] as int) * 1000);
  if (!authTime.isBefore(DateTime.now())) {
    throw JWTException('Invalid auth time');
  }

  if (!payload.containsKey('aud') || payload['aud'] != audience) {
    throw JWTException('Invalid audience');
  }

  if (!payload.containsKey('sub') ||
      payload['sub'] == null ||
      (payload['sub'] as String).isEmpty) {
    throw JWTException('Invalid subject');
  }

  if (!payload.containsKey('iss') || payload['iss'] != issuer) {
    throw JWTException('Invalid issuer');
  }
  return JWT(
    payload,
    audience: Audience.one(audience),
    issuer: issuer,
    subject: payload['sub'] as String,
    header: header,
  );
}

Middleware handleAuth() {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers[HttpHeaders.authorizationHeader];

      try {
        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          final token = authHeader.substring(7);
          final jwt = await verifyFirebaseToken(token);

          final updatedRequest = request.change(
            context: {'authDetails': jwt},
          );
          return await innerHandler(updatedRequest);
        } else {
          throw JWTException('Invalid token');
        }
      } on JWTException catch (e, stackTrace) {
        log(e.toString(), stackTrace: stackTrace);
        return Response(
          HttpStatus.unauthorized,
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.unauthorized,
              message: e.message,
            ).toJson(),
          ),
        );
      } catch (e, stackTrace) {
        log(e.toString(), stackTrace: stackTrace);
        return Response.internalServerError(
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.internalServerError,
              message: e.toString(),
            ).toJson(),
          ),
        );
      }
    };
  };
}
