import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  HiveService._();

  static const kvName = 'st_kv';
  static const dataName = 'st_data';

  static String _kv = kvName;
  static String _data = dataName;
  static var _ready = false;

  static Future<void> init({String? path, String suffix = ''}) async {
    _kv = '$kvName$suffix';
    _data = '$dataName$suffix';
    if (!_ready) {
      if (path != null) {
        Hive.init(path);
      } else {
        await Hive.initFlutter();
      }
      _ready = true;
    }
    if (!Hive.isBoxOpen(_kv)) await Hive.openBox(_kv);
    if (!Hive.isBoxOpen(_data)) await Hive.openBox(_data);
  }

  static Box get kv => Hive.box(_kv);
  static Box get data => Hive.box(_data);
}
