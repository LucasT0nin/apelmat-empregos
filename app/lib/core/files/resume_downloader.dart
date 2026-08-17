import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

import '../api/api_client.dart';

Future<String> downloadResume({
  required ApiClient apiClient,
  required String url,
  required String professionalName,
}) async {
  final Uint8List bytes = await apiClient.download(url);
  final safeName = professionalName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return FileSaver.instance.saveFile(
    name: 'curriculo_${safeName.isEmpty ? 'profissional' : safeName}',
    bytes: bytes,
    fileExtension: 'pdf',
    mimeType: MimeType.pdf,
  );
}
