import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  static const _requestTimeout = Duration(seconds: 8);

  ApiClient({
    http.Client? client,
    FlutterSecureStorage? storage,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage(),
       baseUrl =
           baseUrl ??
           const String.fromEnvironment(
             'API_BASE_URL',
             defaultValue: 'http://10.0.2.2:8000/api',
           );

  final http.Client _client;
  final FlutterSecureStorage _storage;
  final String baseUrl;

  Future<String?> get accessToken => _storage.read(key: 'access_token');

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await Future.wait([
      _storage.write(key: 'access_token', value: access),
      _storage.write(key: 'refresh_token', value: refresh),
    ]);
  }

  Future<void> clearTokens() => _storage.deleteAll();

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = true,
  }) {
    return _send(
      'GET',
      path,
      queryParameters: queryParameters,
      authenticated: authenticated,
    );
  }

  Future<dynamic> post(String path, {Object? body, bool authenticated = true}) {
    return _send('POST', path, body: body, authenticated: authenticated);
  }

  Future<dynamic> patch(String path, {Object? body}) {
    return _send('PATCH', path, body: body);
  }

  Future<dynamic> multipartPatch(
    String path, {
    required Map<String, String> fields,
    String? fileField,
    String? filePath,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('PATCH', uri);
    request.headers['Accept'] = 'application/json';

    final token = await accessToken;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields.addAll(fields);

    if (fileField != null && filePath != null) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }

    late http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await request.send().timeout(_requestTimeout);
    } on TimeoutException {
      throw const ApiException(
        'O servidor demorou para responder. Confira se o backend esta ligado e se o celular esta na mesma rede Wi-Fi.',
      );
    }
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    throw ApiException(
      _extractMessage(response),
      statusCode: response.statusCode,
    );
  }

  Future<void> delete(String path) async {
    await _send('DELETE', path);
  }

  Future<Uint8List> download(
    String path, {
    bool allowTokenRefresh = true,
  }) async {
    final uri =
        path.startsWith('http') ? Uri.parse(path) : Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Accept': 'application/pdf'};
    final token = await accessToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _withTimeout(_client.get(uri, headers: headers));
    if (response.statusCode == 401 &&
        allowTokenRefresh &&
        await _refreshAccessToken()) {
      return download(path, allowTokenRefresh: false);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw ApiException(
      _extractMessage(response),
      statusCode: response.statusCode,
    );
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    bool authenticated = true,
    bool allowTokenRefresh = true,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParameters);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (authenticated) {
      final token = await accessToken;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final encodedBody = body == null ? null : jsonEncode(body);
    late http.Response response;
    switch (method) {
      case 'GET':
        response = await _withTimeout(_client.get(uri, headers: headers));
        break;
      case 'POST':
        response = await _withTimeout(
          _client.post(uri, headers: headers, body: encodedBody),
        );
        break;
      case 'PATCH':
        response = await _withTimeout(
          _client.patch(uri, headers: headers, body: encodedBody),
        );
        break;
      case 'DELETE':
        response = await _withTimeout(_client.delete(uri, headers: headers));
        break;
      default:
        throw UnsupportedError('Metodo HTTP nao suportado: $method');
    }

    if (response.statusCode == 401 &&
        authenticated &&
        allowTokenRefresh &&
        await _refreshAccessToken()) {
      return _send(
        method,
        path,
        body: body,
        queryParameters: queryParameters,
        authenticated: authenticated,
        allowTokenRefresh: false,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    throw ApiException(
      _extractMessage(response),
      statusCode: response.statusCode,
    );
  }

  Future<http.Response> _withTimeout(Future<http.Response> request) async {
    try {
      return await request.timeout(_requestTimeout);
    } on TimeoutException {
      throw const ApiException(
        'O servidor demorou para responder. Confira se o backend esta ligado e se o celular esta na mesma rede Wi-Fi.',
      );
    }
  }

  Future<bool> _refreshAccessToken() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh == null) {
      return false;
    }

    try {
      final response = await _withTimeout(
        _client.post(
          Uri.parse('$baseUrl/auth/token/refresh/'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'refresh': refresh}),
        ),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await clearTokens();
        return false;
      }

      final payload =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      await saveTokens(
        access: payload['access'] as String,
        refresh: payload['refresh'] as String? ?? refresh,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  String _extractMessage(http.Response response) {
    try {
      final payload = jsonDecode(utf8.decode(response.bodyBytes));
      if (payload is Map<String, dynamic>) {
        final detail = payload['detail'];
        if (detail is String) {
          return detail;
        }
        for (final value in payload.values) {
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
          if (value is String) {
            return value;
          }
        }
      }
    } catch (_) {
      // A mensagem generica abaixo cobre respostas que nao sao JSON.
    }
    return 'Nao foi possivel concluir a solicitacao.';
  }
}
