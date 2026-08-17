import 'dart:io';
import 'dart:typed_data';

enum MimeType { pdf }

class FileSaver {
  const FileSaver._();

  static const FileSaver instance = FileSaver._();

  Future<String> saveFile({
    required String name,
    required Uint8List bytes,
    String? fileExtension,
    MimeType? mimeType,
  }) async {
    final extension =
        fileExtension == null || fileExtension.isEmpty ? '' : '.$fileExtension';
    final file = File('${Directory.systemTemp.path}/$name$extension');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

