enum FileType { any, custom }

class PlatformFile {
  const PlatformFile({required this.name, this.path, this.size = 0});

  final String name;
  final String? path;
  final int size;
}

class FilePickerResult {
  const FilePickerResult(this.files);

  final List<PlatformFile> files;
}

class FilePicker {
  const FilePicker._();

  static const FilePicker platform = FilePicker._();

  static Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool withData = false,
  }) {
    return platform._pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
      withData: withData,
    );
  }

  Future<FilePickerResult?> _pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool withData = false,
  }) async {
    return null;
  }
}

