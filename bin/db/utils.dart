import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';
import 'package:shelf/shelf.dart';

import '../common/constants.dart';
import '../common/response_wrapper.dart';

Middleware handleCors() {
  return createMiddleware(
    requestHandler: (Request request) {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }
      return null;
    },
    responseHandler: (Response response) {
      return response.change(headers: headers);
    },
  );
}

String generateSalt([int length = 32]) {
  final rand = Random.secure();
  final saltBytes = List<int>.generate(length, (_) => rand.nextInt(256));
  return base64.encode(saltBytes);
}

String hashPassword(String password, String salt) {
  const codec = Utf8Codec();
  final key = codec.encode(password);
  final saltBytes = codec.encode(salt);
  final hmac = Hmac(sha256, key);
  final digest = hmac.convert(saltBytes);
  return digest.toString();
}

String generateJwt({
  required String subject,
  required String issuer,
  required String secret,
  required String jwtId,
  required Duration expiry,
}) {
  final jwt = JWT(
    {
      'iat': DateTime.now().millisecondsSinceEpoch,
    },
    subject: subject,
    issuer: issuer,
    jwtId: jwtId,
  );
  return jwt.sign(SecretKey(secret), expiresIn: expiry);
}

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
    throw JWTInvalidError('invalid header');
  }

  if (header['typ'] != 'JWT') {
    throw JWTInvalidError('not a jwt');
  }

  final body = utf8.encode('${parts[0]}.${parts[1]}');
  final signature = base64Url.decode(base64Padded(parts[2]));

  final jsonWebKey = JsonWebKey.fromPem(keys[header['kid']] as String);

  final payloadBase64 = parts[1];
  final normalizedPayload = base64.normalize(payloadBase64);
  final payloadString = utf8.decode(base64.decode(normalizedPayload));
  final payload = jsonDecode(payloadString) as Map<String, dynamic>;

  if (!jsonWebKey.verify(body, signature, algorithm: header['alg'] as String)) {
    throw JWTInvalidError('invalid header');
  }

  if (payload.containsKey('exp')) {
    final exp =
        DateTime.fromMillisecondsSinceEpoch((payload['exp'] as int) * 1000);
    if (!exp.isAfter(DateTime.now())) {
      throw JWTExpiredError();
    }
  }

  if (!payload.containsKey('iat')) {
    throw JWTInvalidError('invalid issue at');
  }
  final iat =
      DateTime.fromMillisecondsSinceEpoch((payload['iat'] as int) * 1000);
  if (!iat.isBefore(DateTime.now())) {
    throw JWTInvalidError('invalid issue at');
  }

  if (!payload.containsKey('auth_time')) {
    throw JWTInvalidError('invalid auth_time');
  }
  final authTime =
      DateTime.fromMillisecondsSinceEpoch((payload['auth_time'] as int) * 1000);
  if (!authTime.isBefore(DateTime.now())) {
    throw JWTInvalidError('invalid auth_time');
  }

  if (!payload.containsKey('aud') || payload['aud'] != audience) {
    throw JWTInvalidError('invalid audience');
  }

  if (!payload.containsKey('sub') ||
      payload['sub'] == null ||
      (payload['sub'] as String).isEmpty) {
    throw JWTInvalidError('invalid subject');
  }

  if (!payload.containsKey('iss') || payload['iss'] != issuer) {
    throw JWTInvalidError('invalid issuer');
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
      final authHeader = request.headers['authorization'];
      JWT? jwt;

      try {
        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          final token = authHeader.substring(7);
          // jwt = JWT.verify(token, SecretKey(secret));
          jwt = await verifyFirebaseToken(token);
        }
      } catch (e, stackTrace) {
        log(e.toString(), error: e, stackTrace: stackTrace);
        return Response(
          HttpStatus.unauthorized,
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.unauthorized,
              message: 'Invalid token',
            ).toJson(),
          ),
        );
      }

      final updatedRequest = request.change(
        context: {
          'authDetails': jwt,
        },
      );
      return await innerHandler(updatedRequest);
    };
  };
}

Middleware checkAuthorisation() {
  return createMiddleware(
    requestHandler: (Request request) {
      if (request.context['authDetails'] == null) {
        return Response(
          HttpStatus.unauthorized,
          headers: headers,
          body: jsonEncode(
            ResponseWrapper(
              statusCode: HttpStatus.unauthorized,
              message: 'Not authorised to perform this action',
            ).toJson(),
          ),
        );
      }
      return null;
    },
  );
}

Handler fallback(String indexPath) => (Request request) {
      final indexFile = File(indexPath).readAsStringSync();
      return Response.ok(indexFile, headers: {'content-type': 'text/html'});
    };
