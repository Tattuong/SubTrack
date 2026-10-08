import 'dart:convert';

import 'hive_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;
  StorageService._internal();

  Future<void> init() async {}

  BoxLike get _box => BoxLike(HiveService.kv);

  Future<void> saveData(String key, Map<String, dynamic> data) async {
    await _box.put(key, data);
  }

  Future<void> saveDataList(String key, List<Map<String, dynamic>> data) async {
    await _box.put(key, data);
  }

  Future<List<Map<String, dynamic>>?> getDataList(String key) async {
    final raw = _box.get(key);
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (raw is String) {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    }
    return null;
  }

  Future<Map<String, dynamic>?> getData(String key) async {
    final raw = _box.get(key);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
    return null;
  }

  Future<void> saveString(String key, String value) async {
    await _box.put(key, value);
  }

  Future<String?> getString(String key) async {
    final raw = _box.get(key);
    return raw?.toString();
  }

  Future<void> saveBool(String key, bool value) async {
    await _box.put(key, value);
  }

  Future<bool?> getBool(String key) async {
    final raw = _box.get(key);
    if (raw is bool) return raw;
    return null;
  }

  Future<void> saveInt(String key, int value) async {
    await _box.put(key, value);
  }

  Future<int?> getInt(String key) async {
    final raw = _box.get(key);
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return null;
  }

  Future<void> saveStringList(String key, List<String> value) async {
    await _box.put(key, value);
  }

  Future<List<String>?> getStringList(String key) async {
    final raw = _box.get(key);
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return null;
  }

  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  Future<void> clear() async {
    await HiveService.kv.clear();
  }

  bool containsKey(String key) => HiveService.kv.containsKey(key);

  Future<void> saveDouble(String key, double value) async {
    await _box.put(key, value);
  }

  Future<double?> getDouble(String key) async {
    final raw = _box.get(key);
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    return null;
  }

  static String encodeList(List<Map<String, dynamic>> list) => jsonEncode(list);

  static List<Map<String, dynamic>> decodeList(String raw) =>
      (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
}

class BoxLike {
  final dynamic box;
  BoxLike(this.box);

  dynamic get(String key) => box.get(key);
  Future<void> put(String key, dynamic value) => box.put(key, value);
  Future<void> delete(String key) => box.delete(key);
}
