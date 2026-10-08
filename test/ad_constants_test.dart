import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack/core/constants/ad_constants.dart';

void main() {
  test('banner stays off until real AdMob app and banner units are pasted', () {
    expect(AdConstants.androidAppId, isEmpty);
    expect(AdConstants.androidBannerId, isEmpty);
    expect(AdConstants.isConfigured, isFalse);
    expect(AdConstants.bannerHeight, 50);
  });
}
