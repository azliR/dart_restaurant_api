import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

import '../common/response_wrapper.dart';

Middleware handleCors() {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE',
    'Access-Control-Allow-Headers': 'Origin, Content-Type',
  };

  return createMiddleware(
    requestHandler: (Request request) {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }
      return null;
    },
    responseHandler: (Response response) {
      return response.change(headers: corsHeaders);
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

Middleware handleAuth(String secret) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'];
      JWT? jwt;

      try {
        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          final token = authHeader.substring(7);
          jwt = JWT.verify(token, SecretKey(secret));
        }
      } catch (e, stackTrace) {
        log(e.toString(), error: e, stackTrace: stackTrace);
        return Response(
          HttpStatus.unauthorized,
          body: ResponseWrapper(
            statusCode: HttpStatus.unauthorized,
            message: 'Invalid token',
          ).toJson(),
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
          body: ResponseWrapper(
            statusCode: HttpStatus.unauthorized,
            message: 'Not authorised to perform this action.',
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
