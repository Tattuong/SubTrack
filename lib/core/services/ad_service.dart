import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/ad_constants.dart';

class AdService {
  AdService._();

  static Future<void>? _init;

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> init() {
    if (!AdConstants.isConfigured) return Future.value();
    _init ??= _doInit();
    return _init!;
  }

  static Future<void> _doInit() async {
    if (!isSupported || !AdConstants.isConfigured) return;
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('AdMob init failed: $e');
    }
  }
}
