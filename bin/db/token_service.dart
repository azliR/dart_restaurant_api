// import 'package:redis/redis.dart';
// import 'package:uuid/uuid.dart';

// import 'token_pair.dart';

// class TokenService {
//   TokenService(this.db, this.secret);

//   final RedisConnection db;
//   final String secret;

//   static late Command _cache;
//   final String _prefix = 'token';

//   Future<void> start({
//     required String host,
//     required String password,
//     required int port,
//   }) async {
//     _cache = await db.connect(host, port);
//     await _cache.send_object(['AUTH', password]);
//   }

//   Future<TokenPair> createTokenPair(String userId) async {
//     const tokenExpiry = Duration(days: 1);
//     final tokenId = const Uuid().v4();
//     final token = generateJwt(
//       subject: userId,
//       issuer: 'http://localhost',
//       expiry: tokenExpiry,
//       jwtId: tokenId,
//       secret: secret,
//     );

//     const refreshTokenExpiry = Duration(days: 7);
//     final refreshToken = generateJwt(
//       subject: userId,
//       issuer: 'http://localhost',
//       expiry: refreshTokenExpiry,
//       jwtId: tokenId,
//       secret: secret,
//     );

//     await addRefreshToken(tokenId, refreshToken, refreshTokenExpiry);

//     return TokenPair(
//       token: token,
//       tokenExpiresIn: DateTime.now().add(tokenExpiry),
//       refreshToken: refreshToken,
//       refreshTokenExpiresIn: DateTime.now().add(refreshTokenExpiry),
//     );
//   }

//   Future<void> addRefreshToken(String id, String token, Duration expiry) async {
//     await _cache.send_object(['SET', '$_prefix:$id', token]);
//     await _cache.send_object(['EXPIRE', '$_prefix:$id', expiry.inSeconds]);
//   }

//   Future<dynamic>? getRefreshToken(String id) async {
//     return _cache.get('$_prefix:$id');
//   }

//   Future<void> removeRefreshToken(String id) async {
//     await _cache.send_object(['EXPIRE', '$_prefix:$id', '-1']);
//   }
// }
