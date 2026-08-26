import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../errors/app_exception.dart';

typedef TokenReader = Future<String?> Function();

const _jsonDecodeIsolateThreshold = 50 * 1024;

dynamic _decodeResponseBody(String body) {
  return body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
}

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    TokenReader? tokenReader,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _tokenReader = tokenReader,
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _httpClient;
  final TokenReader? _tokenReader;
  final String _baseUrl;

  Map<String, dynamic> _redactBody(Map<String, dynamic> body) {
    const sensitiveKeys = {'password', 'currentPassword', 'newPassword', 'refreshToken', 'accessToken', 'fcmToken'};
    return body.map((key, value) {
      if (sensitiveKeys.contains(key)) return MapEntry(key, '***');
      return MapEntry(key, value);
    });
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth && _tokenReader != null) {
      final token = await _tokenReader();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$cleanPath');
    final queryParams = query == null
        ? null
        : Map<String, String>.fromEntries(
            query.entries
                .map((entry) => MapEntry(entry.key, '${entry.value}'))
                .where((entry) => entry.value.isNotEmpty && entry.value != 'null'),
          );
    return uri.replace(queryParameters: queryParams == null || queryParams.isEmpty ? null : queryParams);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) async {
    return _send(() async {
      final response = await _httpClient.get(_uri(path, query), headers: await _headers(auth: auth));
      return _decode(response);
    }, method: 'GET', path: path);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    return _send(() async {
      final response = await _httpClient.post(
        _uri(path),
        headers: await _headers(auth: auth),
        body: jsonEncode(body ?? {}),
      );
      return _decode(response);
    }, method: 'POST', path: path, body: body);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    return _send(() async {
      final response = await _httpClient.put(
        _uri(path),
        headers: await _headers(auth: auth),
        body: jsonEncode(body ?? {}),
      );
      return _decode(response);
    }, method: 'PUT', path: path, body: body);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    return _send(() async {
      final response = await _httpClient.delete(_uri(path), headers: await _headers(auth: auth));
      return _decode(response);
    }, method: 'DELETE', path: path);
  }

  Future<http.Response> download(String path, {Map<String, dynamic>? query}) async {
    final response = await _httpClient.get(_uri(path, query), headers: await _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppException('Download failed', statusCode: response.statusCode);
    }
    return response;
  }

  Future<dynamic> _decode(http.Response response) async {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : response.body.length >= _jsonDecodeIsolateThreshold
            ? await compute(_decodeResponseBody, response.body)
            : _decodeResponseBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map<String, dynamic> && body.containsKey('data')) return body['data'];
      return body;
    }

    if (body is Map<String, dynamic>) {
      throw AppException(
        body['message']?.toString() ?? 'Request failed',
        statusCode: response.statusCode,
        errors: body['errors'] is List ? body['errors'] as List<dynamic> : const [],
      );
    }
    throw AppException('Request failed', statusCode: response.statusCode);
  }

  Future<T> _send<T>(
    Future<T> Function() request, {
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('API $method $_baseUrl$path');
        if (body != null) debugPrint('API request body: ${jsonEncode(_redactBody(body))}');
      }
      return await request();
    } on AppException {
      rethrow;
    } on http.ClientException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('API client error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      throw const AppException('Cannot connect to the server. Please verify the backend is running.');
    } on FormatException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('API response parse error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      throw const AppException('Server returned an invalid response.');
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('API unexpected error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      throw const AppException('Cannot reach the server. Check the API URL and network connection.');
    }
  }
}
