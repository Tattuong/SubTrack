import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack/core/constants/iap_constants.dart';
import 'package:subtrack/core/services/iap_config_service.dart';
import 'package:subtrack/models/shop_item.dart';

void main() {
  test('SubTrack IAP ids and N311 endpoint', () {
    expect(IapConstants.productPrefix, 'st');
    expect(IapConstants.remoteConfigUrl, 'https://api2.blwsmartware.net/N311.json');
    expect(IapConstants.coinPackIds.first, 'st_pack_1');
    expect(IapConstants.coinPackIds.last, 'st_pack_10');
    expect(IapConstants.coinPackIds, hasLength(10));
    expect(IapConstants.removeAdsProductId, 'st_remove_ads');
    expect(IapConstants.proProductId, 'st_pro');
    expect(IapConstants.allProductIds, containsAll([...IapConstants.coinPackIds, 'st_remove_ads', 'st_pro']));
    expect(IapConstants.coinsForProduct('st_pack_5'), 500);
    expect(IapConstants.freeArchiveLimit, 8);
    expect(IapConstants.proArchiveLimit, 99);
  });

  test('disable=1 hides billing only', () {
    final off = IapRemoteConfig.fromJson({'disable': 1, 'name': 'SubTrack'});
    expect(off.billingDisabled, isTrue);
    final on = IapRemoteConfig.fromJson({'disable': 0, 'name': 'SubTrack', 'code': 'FULL_IAP'});
    expect(on.billingDisabled, isFalse);
    expect(on.name, 'SubTrack');
  });

  test('shop catalog extras can be applied and reverted', () {
    expect(ShopCatalog.items.where((e) => e.id.startsWith('theme_')), isNotEmpty);
    expect(ShopCatalog.find(ShopCatalog.featPro), isNotNull);
    expect(ShopCatalog.find('remove_ads'), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featHint), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featSound), isNotNull);
    expect(ShopCatalog.isDefaultId(ShopCatalog.defaultThemeId), isTrue);
  });
}
