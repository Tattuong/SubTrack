import 'package:flutter/material.dart';

import 'strings/app_strings_en.dart';

class AppStrings {
  static String t(BuildContext context, String key, [Map<String, String>? params]) {
    return tCode(key, params);
  }

  static String tCode(String key, [Map<String, String>? params]) {
    var text = appStringsEn[key] ?? key;
    if (params != null) {
      params.forEach((k, v) => text = text.replaceAll('{$k}', v));
    }
    return text;
  }
}
