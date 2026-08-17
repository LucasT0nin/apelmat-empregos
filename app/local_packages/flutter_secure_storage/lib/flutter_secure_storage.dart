class FlutterSecureStorage {
  const FlutterSecureStorage();

  static final Map<String, String> _values = <String, String>{};

  Future<String?> read({required String key}) async => _values[key];

  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }

  Future<void> delete({required String key}) async {
    _values.remove(key);
  }

  Future<void> deleteAll() async {
    _values.clear();
  }
}

