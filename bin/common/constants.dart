import 'dart:io';

const headers = {
  HttpHeaders.accessControlAllowMethodsHeader: 'GET, POST, PUT, DELETE',
  HttpHeaders.accessControlAllowHeadersHeader: 'Origin, Content-Type',
  HttpHeaders.accessControlAllowOriginHeader: '*',
  HttpHeaders.accessControlRequestHeadersHeader: '*',
  HttpHeaders.accessControlRequestMethodHeader: '*',
  HttpHeaders.contentTypeHeader: 'application/json',
};

const kSupportedLanguages = {
  'en',
  'id',
};
