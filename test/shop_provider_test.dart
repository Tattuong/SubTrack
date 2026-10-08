import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack/core/services/hive_service.dart';
import 'package:subtrack/core/services/storage_service.dart';
import 'package:subtrack/models/shop_item.dart';
import 'package:subtrack/providers/shop_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('sn_shop');
    await HiveService.init(path: dir.path, suffix: '_shop');
    await StorageService.instance.init();
  });

  setUp(() async {
    await HiveService.kv.clear();
  });

  test('shop items stay locked without coins', () async {
    final shop = ShopProvider();
    await shop.init(remote: false);
    expect(shop.buyWithCoins('theme_mint'), ShopPurchaseResult.insufficientCoins);
    expect(shop.activeThemeId, ShopCatalog.defaultThemeId);
  });

  test('theme apply and revert to default', () async {
    final shop = ShopProvider();
    await shop.init(remote: false);
    await shop.addCoinsQuiet(500);
    expect(shop.buyWithCoins('theme_mint'), ShopPurchaseResult.success);
    expect(shop.activeThemeId, 'theme_mint');
    await shop.setFeatureEnabled('theme_mint', false);
    expect(shop.activeThemeId, ShopCatalog.defaultThemeId);
    expect(shop.buyWithCoins(ShopCatalog.featHint), ShopPurchaseResult.success);
    expect(shop.featureOn(ShopCatalog.featHint), isTrue);
    await shop.setFeatureEnabled(ShopCatalog.featHint, false);
    expect(shop.featureOn(ShopCatalog.featHint), isFalse);
    await shop.resetLookToDefault();
    expect(shop.isDefaultLook, isTrue);
  });
}
