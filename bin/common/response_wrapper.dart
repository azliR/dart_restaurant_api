class ResponseWrapper {
  ResponseWrapper({
    required this.statusCode,
    this.message,
    this.data,
  });

  final int statusCode;
  final String? message;
  final Object? data;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> toJson() {
    return {
      'success': isSuccess,
      'statusCode': statusCode,
      'message': message,
      'data': data,
    }..removeWhere((key, value) => value == null);
  }
}
