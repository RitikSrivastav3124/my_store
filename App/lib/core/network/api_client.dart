import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../errors/app_exception.dart';

typedef TokenReader = Future<String?> Function();
typedef TokenWriter = Future<void> Function({
  required String accessToken,
  required String refreshToken,
});
typedef SessionClearer = Future<void> Function();

const _jsonDecodeIsolateThreshold = 50 * 1024;

dynamic _decodeResponseBody(String body) {
  return body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
}

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    TokenReader? tokenReader,
    TokenReader? refreshTokenReader,
    TokenWriter? tokenWriter,
    SessionClearer? sessionClearer,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _tokenReader = tokenReader,
        _refreshTokenReader = refreshTokenReader,
        _tokenWriter = tokenWriter,
        _sessionClearer = sessionClearer,
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _httpClient;
  final TokenReader? _tokenReader;
  final TokenReader? _refreshTokenReader;
  final TokenWriter? _tokenWriter;
  final SessionClearer? _sessionClearer;
  final String _baseUrl;
  Future<void>? _refreshing;

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
    }, method: 'GET', path: path, auth: auth);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    return _send(() async {
      final response = await _httpClient.post(
        _uri(path),
        headers: await _headers(auth: auth),
        body: jsonEncode(body ?? {}),
      );
      return _decode(response);
    }, method: 'POST', path: path, body: body, auth: auth);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    return _send(() async {
      final response = await _httpClient.put(
        _uri(path),
        headers: await _headers(auth: auth),
        body: jsonEncode(body ?? {}),
      );
      return _decode(response);
    }, method: 'PUT', path: path, body: body, auth: auth);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    return _send(() async {
      final response = await _httpClient.delete(_uri(path), headers: await _headers(auth: auth));
      return _decode(response);
    }, method: 'DELETE', path: path, auth: auth);
  }

  Future<http.Response> download(String path, {Map<String, dynamic>? query}) async {
    return _send(() async {
      final response = await _httpClient.get(_uri(path, query), headers: await _headers());
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException('Download failed', statusCode: response.statusCode);
      }
      return response;
    }, method: 'GET', path: path);
  }

  Future<void> _refreshTokens() {
    final activeRefresh = _refreshing;
    if (activeRefresh != null) return activeRefresh;

    late final Future<void> refresh;
    refresh = _performTokenRefresh().whenComplete(() {
      if (identical(_refreshing, refresh)) _refreshing = null;
    });
    _refreshing = refresh;
    return refresh;
  }

  Future<void> _performTokenRefresh() async {
    try {
      final refreshToken = _refreshTokenReader == null
          ? null
          : await _refreshTokenReader();
      if (refreshToken == null || refreshToken.isEmpty || _tokenWriter == null) {
        throw const AppException(
          'Your session has expired. Please sign in again.',
          statusCode: 401,
        );
      }

      final response = await _httpClient.post(
        _uri('/auth/refresh'),
        headers: await _headers(auth: false),
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      final data = await _decode(response);
      if (data is! Map<String, dynamic>) {
        throw const AppException('Server returned an invalid refresh response.');
      }

      final accessToken = data['accessToken']?.toString() ?? '';
      final nextRefreshToken = data['refreshToken']?.toString() ?? '';
      if (accessToken.isEmpty || nextRefreshToken.isEmpty) {
        throw const AppException('Server returned an invalid refresh response.');
      }
      await _tokenWriter(accessToken: accessToken, refreshToken: nextRefreshToken);
    } catch (_) {
      try {
        if (_sessionClearer != null) await _sessionClearer();
      } catch (_) {}
      rethrow;
    }
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
    bool auth = true,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('API $method $_baseUrl$path');
        if (body != null) debugPrint('API request body: ${jsonEncode(_redactBody(body))}');
      }
      return await request();
    } on AppException catch (error) {
      if (auth &&
          error.statusCode == 401 &&
          _refreshTokenReader != null &&
          _tokenWriter != null) {
        await _refreshTokens();
        return await request();
      }
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
