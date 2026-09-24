import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_store/core/errors/app_exception.dart';
import 'package:my_store/core/network/api_client.dart';

void main() {
  test('refreshes rotated tokens and retries an authenticated 401 once', () async {
    var currentAccessToken = 'expired-access-token';
    var currentRefreshToken = 'valid-refresh-token';
    var refreshCalls = 0;
    var protectedCalls = 0;

    final client = ApiClient(
      baseUrl: 'https://my-store-3602.onrender.com/api',
      tokenReader: () async => currentAccessToken,
      refreshTokenReader: () async => currentRefreshToken,
      tokenWriter: ({required accessToken, required refreshToken}) async {
        currentAccessToken = accessToken;
        currentRefreshToken = refreshToken;
      },
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/auth/refresh') {
          refreshCalls++;
          expect(jsonDecode(request.body), {'refreshToken': 'valid-refresh-token'});
          return http.Response(
            jsonEncode({
              'data': {
                'accessToken': 'new-access-token',
                'refreshToken': 'rotated-refresh-token',
              },
            }),
            200,
          );
        }

        protectedCalls++;
        if (protectedCalls == 1) return http.Response('{"message":"Unauthorized"}', 401);
        expect(request.headers['authorization'], 'Bearer new-access-token');
        return http.Response('{"data":{"ok":true}}', 200);
      }),
    );

    final response = await client.get('/protected');

    expect(response, {'ok': true});
    expect(refreshCalls, 1);
    expect(currentAccessToken, 'new-access-token');
    expect(currentRefreshToken, 'rotated-refresh-token');
  });

  test('does not refresh an unauthenticated 401', () async {
    var refreshCalls = 0;
    final client = ApiClient(
      baseUrl: 'https://my-store-3602.onrender.com/api',
      refreshTokenReader: () async => 'refresh-token',
      tokenWriter: ({required accessToken, required refreshToken}) async {},
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/auth/refresh') refreshCalls++;
        return http.Response('{"message":"Unauthorized"}', 401);
      }),
    );

    await expectLater(client.post('/auth/login', auth: false), throwsA(isA<AppException>()));
    expect(refreshCalls, 0);
  });

  test('stops after a retried request returns 401', () async {
    var refreshCalls = 0;
    var currentAccessToken = 'expired-access-token';
    final client = ApiClient(
      baseUrl: 'https://example.test/api',
      tokenReader: () async => currentAccessToken,
      refreshTokenReader: () async => 'refresh-token',
      tokenWriter: ({required accessToken, required refreshToken}) async {
        currentAccessToken = accessToken;
      },
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/auth/refresh') {
          refreshCalls++;
          return http.Response(
            '{"data":{"accessToken":"new-access-token","refreshToken":"rotated-refresh-token"}}',
            200,
          );
        }
        return http.Response('{"message":"Unauthorized"}', 401);
      }),
    );

    await expectLater(client.get('/protected'), throwsA(isA<AppException>()));
    expect(refreshCalls, 1);
  });

  test('concurrent 401 requests share one token refresh', () async {
    var currentAccessToken = 'expired-access-token';
    var currentRefreshToken = 'valid-refresh-token';
    var refreshCalls = 0;
    var protectedCalls = 0;
    var initialProtectedCalls = 0;
    final bothInitialRequestsReceived = Completer<void>();
    final allowRefreshResponse = Completer<void>();

    final client = ApiClient(
      baseUrl: 'https://example.test/api',
      tokenReader: () async => currentAccessToken,
      refreshTokenReader: () async => currentRefreshToken,
      tokenWriter: ({required accessToken, required refreshToken}) async {
        currentAccessToken = accessToken;
        currentRefreshToken = refreshToken;
      },
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/auth/refresh') {
          refreshCalls++;
          await bothInitialRequestsReceived.future;
          await allowRefreshResponse.future;
          return http.Response(
            '{"data":{"accessToken":"new-access-token","refreshToken":"rotated-refresh-token"}}',
            200,
          );
        }

        protectedCalls++;
        if (request.headers['authorization'] == 'Bearer expired-access-token') {
          initialProtectedCalls++;
          if (initialProtectedCalls == 2) bothInitialRequestsReceived.complete();
          return http.Response('{"message":"Unauthorized"}', 401);
        }

        expect(request.headers['authorization'], 'Bearer new-access-token');
        return http.Response('{"data":{"ok":true}}', 200);
      }),
    );

    final firstRequest = client.get('/protected/one');
    final secondRequest = client.get('/protected/two');

    await bothInitialRequestsReceived.future;
    allowRefreshResponse.complete();

    expect(await firstRequest, {'ok': true});
    expect(await secondRequest, {'ok': true});
    expect(refreshCalls, 1);
    expect(protectedCalls, 4);
    expect(currentAccessToken, 'new-access-token');
    expect(currentRefreshToken, 'rotated-refresh-token');
  });

  test('refresh failure clears the session without retrying the protected request', () async {
    var refreshCalls = 0;
    var protectedCalls = 0;
    var sessionCleared = false;
    final client = ApiClient(
      baseUrl: 'https://example.test/api',
      tokenReader: () async => 'expired-access-token',
      refreshTokenReader: () async => 'invalid-refresh-token',
      tokenWriter: ({required accessToken, required refreshToken}) async {},
      sessionClearer: () async {
        sessionCleared = true;
      },
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/auth/refresh') {
          refreshCalls++;
          return http.Response('{"message":"Invalid refresh token"}', 401);
        }

        protectedCalls++;
        return http.Response('{"message":"Unauthorized"}', 401);
      }),
    );

    await expectLater(client.get('/protected'), throwsA(isA<AppException>()));

    expect(refreshCalls, 1);
    expect(sessionCleared, isTrue);
    expect(protectedCalls, 1);
  });
}
