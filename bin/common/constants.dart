import 'dart:io';

const headers = {
  HttpHeaders.accessControlAllowOriginHeader: 'http://localhost:4000',
  HttpHeaders.accessControlRequestHeadersHeader: 'http://localhost:4000',
  HttpHeaders.accessControlRequestMethodHeader: 'http://localhost:4000',
  HttpHeaders.contentTypeHeader: 'application/json',
};
const kSupportedLanguages = {
  'en',
  'id',
};
