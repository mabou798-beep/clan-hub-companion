/// Thin JSON-over-HTTP client with errors the UI can explain.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

enum ApiErrorKind { offline, notFound, badRequest, maintenance, rateLimited, server }

class ApiException implements Exception {
  const ApiException(this.kind, [this.detail]);
  final ApiErrorKind kind;
  final String? detail;

  @override
  String toString() => 'ApiException($kind, $detail)';
}

class Api {
  Api({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<dynamic> getJson(Uri uri, {Duration timeout = const Duration(seconds: 15)}) async {
    final http.Response res;
    try {
      res = await _client.get(uri, headers: const {'Accept': 'application/json'}).timeout(timeout);
    } on TimeoutException {
      throw const ApiException(ApiErrorKind.offline, 'timeout');
    } catch (e) {
      throw ApiException(ApiErrorKind.offline, '$e');
    }
    switch (res.statusCode) {
      case 200:
        try {
          return jsonDecode(utf8.decode(res.bodyBytes));
        } on FormatException {
          throw const ApiException(ApiErrorKind.server, 'bad json');
        }
      case 400:
        throw ApiException(ApiErrorKind.badRequest, res.body);
      case 404:
        throw const ApiException(ApiErrorKind.notFound);
      case 429:
        throw const ApiException(ApiErrorKind.rateLimited);
      case 503:
        throw const ApiException(ApiErrorKind.maintenance);
      default:
        throw ApiException(ApiErrorKind.server, '${res.statusCode}');
    }
  }
}

String friendlyError(Object e) {
  if (e is ApiException) {
    return switch (e.kind) {
      ApiErrorKind.offline => 'No connection. Check your internet and try again.',
      ApiErrorKind.notFound => 'Nothing found for that request.',
      ApiErrorKind.badRequest => 'That request was not accepted.',
      ApiErrorKind.maintenance =>
        'The game servers are in maintenance. Try again in a little while.',
      ApiErrorKind.rateLimited => 'Too many requests right now. Try again in a minute.',
      ApiErrorKind.server => 'The server had a problem. Try again shortly.',
    };
  }
  return 'Something went wrong. Try again.';
}
