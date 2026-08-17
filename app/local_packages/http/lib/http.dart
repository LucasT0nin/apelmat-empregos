import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class Response {
  Response(
    this.body,
    this.statusCode, {
    Map<String, String>? headers,
  }) : bodyBytes = Uint8List.fromList(utf8.encode(body)),
       headers = headers ?? const <String, String>{};

  Response.bytes(
    List<int> bytes,
    this.statusCode, {
    Map<String, String>? headers,
  }) : bodyBytes = Uint8List.fromList(bytes),
       body = utf8.decode(bytes, allowMalformed: true),
       headers = headers ?? const <String, String>{};

  final String body;
  final Uint8List bodyBytes;
  final int statusCode;
  final Map<String, String> headers;

  static Future<Response> fromStream(StreamedResponse response) async {
    final bytes = await response.stream.fold<List<int>>(
      <int>[],
      (previous, chunk) => previous..addAll(chunk),
    );
    return Response.bytes(
      bytes,
      response.statusCode,
      headers: response.headers,
    );
  }
}

class StreamedResponse {
  StreamedResponse(this.stream, this.statusCode, {Map<String, String>? headers})
    : headers = headers ?? const <String, String>{};

  final Stream<List<int>> stream;
  final int statusCode;
  final Map<String, String> headers;
}

class Client {
  final HttpClient _client = HttpClient();

  Future<Response> get(Uri url, {Map<String, String>? headers}) {
    return _send('GET', url, headers: headers);
  }

  Future<Response> post(Uri url, {Map<String, String>? headers, Object? body}) {
    return _send('POST', url, headers: headers, body: body);
  }

  Future<Response> patch(Uri url, {Map<String, String>? headers, Object? body}) {
    return _send('PATCH', url, headers: headers, body: body);
  }

  Future<Response> delete(Uri url, {Map<String, String>? headers}) {
    return _send('DELETE', url, headers: headers);
  }

  void close() {
    _client.close(force: true);
  }

  Future<Response> _send(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final request = await _client.openUrl(method, url);
    headers?.forEach(request.headers.set);
    if (body != null) {
      final bytes =
          body is List<int>
              ? body
              : body is String
              ? utf8.encode(body)
              : utf8.encode(body.toString());
      request.contentLength = bytes.length;
      request.add(bytes);
    }
    final response = await request.close();
    final responseBytes = await response.fold<List<int>>(
      <int>[],
      (previous, chunk) => previous..addAll(chunk),
    );
    return Response.bytes(
      responseBytes,
      response.statusCode,
      headers: _headersToMap(response.headers),
    );
  }
}

Future<Response> get(Uri url, {Map<String, String>? headers}) =>
    Client().get(url, headers: headers);

Future<Response> post(Uri url, {Map<String, String>? headers, Object? body}) =>
    Client().post(url, headers: headers, body: body);

Future<Response> patch(Uri url, {Map<String, String>? headers, Object? body}) =>
    Client().patch(url, headers: headers, body: body);

Future<Response> delete(Uri url, {Map<String, String>? headers}) =>
    Client().delete(url, headers: headers);

class MultipartFile {
  MultipartFile(this.field, this.bytes, {required this.filename});

  final String field;
  final List<int> bytes;
  final String filename;

  static Future<MultipartFile> fromPath(String field, String filePath) async {
    final file = File(filePath);
    return MultipartFile(
      field,
      await file.readAsBytes(),
      filename: file.uri.pathSegments.isEmpty ? 'arquivo.pdf' : file.uri.pathSegments.last,
    );
  }
}

class MultipartRequest {
  MultipartRequest(this.method, this.url);

  final String method;
  final Uri url;
  final Map<String, String> headers = <String, String>{};
  final Map<String, String> fields = <String, String>{};
  final List<MultipartFile> files = <MultipartFile>[];

  Future<StreamedResponse> send() async {
    final boundary = '----apelmat-${DateTime.now().microsecondsSinceEpoch}';
    final body = BytesBuilder();

    for (final entry in fields.entries) {
      body.add(utf8.encode('--$boundary\r\n'));
      body.add(
        utf8.encode(
          'Content-Disposition: form-data; name="${entry.key}"\r\n\r\n',
        ),
      );
      body.add(utf8.encode('${entry.value}\r\n'));
    }

    for (final file in files) {
      body.add(utf8.encode('--$boundary\r\n'));
      body.add(
        utf8.encode(
          'Content-Disposition: form-data; name="${file.field}"; filename="${file.filename}"\r\n',
        ),
      );
      body.add(utf8.encode('Content-Type: application/pdf\r\n\r\n'));
      body.add(file.bytes);
      body.add(utf8.encode('\r\n'));
    }

    body.add(utf8.encode('--$boundary--\r\n'));
    final bytes = body.takeBytes();

    final client = HttpClient();
    final request = await client.openUrl(method, url);
    headers.forEach(request.headers.set);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'multipart/form-data; boundary=$boundary',
    );
    request.contentLength = bytes.length;
    request.add(bytes);

    final response = await request.close();
    return StreamedResponse(
      response,
      response.statusCode,
      headers: _headersToMap(response.headers),
    );
  }
}

Map<String, String> _headersToMap(HttpHeaders headers) {
  final map = <String, String>{};
  headers.forEach((name, values) {
    map[name] = values.join(',');
  });
  return map;
}

