import 'package:flutter/material.dart';

enum ShopItemType { theme, background, skin, feature, removeAds }

enum ShopItemCategory { themes, backgrounds, skins, features, premium }

class ShopItem {
  final String id;
  final String nameKey;
  final String descKey;
  final int price;
  final ShopItemType type;
  final ShopItemCategory category;
  final IconData icon;
  final bool oneTime;

  const ShopItem({
    required this.id,
    required this.nameKey,
    required this.descKey,
    required this.price,
    required this.type,
    required this.category,
    required this.icon,
    this.oneTime = true,
  });
}

class ShopCatalog {
  ShopCatalog._();

  static const String defaultThemeId = 'theme_default';
  static const String defaultBackgroundId = 'bg_default';
  static const String defaultSkinId = 'skin_default';

  static const String featDoubleCoins = 'feat_double_coins';
  static const String featPro = 'feat_pro';
  static const String featSound = 'feat_sound';
  static const String featAwake = 'feat_awake';
  static const String featHint = 'feat_hint';

  static bool isDefaultId(String id) =>
      id == defaultThemeId || id == defaultBackgroundId || id == defaultSkinId;

  static const List<ShopItem> items = [
    ShopItem(
        id: defaultThemeId,
        nameKey: 'shopThemeDefault',
        descKey: 'shopThemeDefaultDesc',
        price: 0,
        type: ShopItemType.theme,
        category: ShopItemCategory.themes,
        icon: Icons.favorite_outline),
    ShopItem(
        id: 'theme_mint',
        nameKey: 'shopThemeMint',
        descKey: 'shopThemeMintDesc',
        price: 200,
        type: ShopItemType.theme,
        category: ShopItemCategory.themes,
        icon: Icons.grass_outlined),
    ShopItem(
        id: 'theme_dusk',
        nameKey: 'shopThemeDusk',
        descKey: 'shopThemeDuskDesc',
        price: 220,
        type: ShopItemType.theme,
        category: ShopItemCategory.themes,
        icon: Icons.nights_stay_outlined),
    ShopItem(
        id: 'theme_peach',
        nameKey: 'shopThemePeach',
        descKey: 'shopThemePeachDesc',
        price: 200,
        type: ShopItemType.theme,
        category: ShopItemCategory.themes,
        icon: Icons.wb_twilight_outlined),
    ShopItem(
        id: 'theme_ice',
        nameKey: 'shopThemeIce',
        descKey: 'shopThemeIceDesc',
        price: 220,
        type: ShopItemType.theme,
        category: ShopItemCategory.themes,
        icon: Icons.ac_unit_outlined),
    ShopItem(
        id: 'theme_night',
        nameKey: 'shopThemeNight',
        descKey: 'shopThemeNightDesc',
        price: 240,
        type: ShopItemType.theme,
        category: ShopItemCategory.themes,
        icon: Icons.dark_mode_outlined),
    ShopItem(
        id: defaultBackgroundId,
        nameKey: 'shopBgDefault',
        descKey: 'shopBgDefaultDesc',
        price: 0,
        type: ShopItemType.background,
        category: ShopItemCategory.backgrounds,
        icon: Icons.crop_landscape_outlined),
    ShopItem(
        id: 'bg_grid',
        nameKey: 'shopBgGrid',
        descKey: 'shopBgGridDesc',
        price: 140,
        type: ShopItemType.background,
        category: ShopItemCategory.backgrounds,
        icon: Icons.grid_on_outlined),
    ShopItem(
        id: 'bg_soft',
        nameKey: 'shopBgSoft',
        descKey: 'shopBgSoftDesc',
        price: 160,
        type: ShopItemType.background,
        category: ShopItemCategory.backgrounds,
        icon: Icons.wb_incandescent_outlined),
    ShopItem(
        id: 'bg_dusk',
        nameKey: 'shopBgDusk',
        descKey: 'shopBgDuskDesc',
        price: 160,
        type: ShopItemType.background,
        category: ShopItemCategory.backgrounds,
        icon: Icons.highlight_outlined),
    ShopItem(
        id: defaultSkinId,
        nameKey: 'shopSkinDefault',
        descKey: 'shopSkinDefaultDesc',
        price: 0,
        type: ShopItemType.skin,
        category: ShopItemCategory.skins,
        icon: Icons.text_fields),
    ShopItem(
        id: 'skin_soft',
        nameKey: 'shopSkinSoft',
        descKey: 'shopSkinSoftDesc',
        price: 150,
        type: ShopItemType.skin,
        category: ShopItemCategory.skins,
        icon: Icons.blur_circular),
    ShopItem(
        id: 'skin_sharp',
        nameKey: 'shopSkinSharp',
        descKey: 'shopSkinSharpDesc',
        price: 150,
        type: ShopItemType.skin,
        category: ShopItemCategory.skins,
        icon: Icons.crop_din),
    ShopItem(
        id: 'skin_glow',
        nameKey: 'shopSkinGlow',
        descKey: 'shopSkinGlowDesc',
        price: 180,
        type: ShopItemType.skin,
        category: ShopItemCategory.skins,
        icon: Icons.light_mode_outlined),
    ShopItem(
        id: 'remove_ads',
        nameKey: 'shopRemoveAds',
        descKey: 'shopRemoveAdsDesc',
        price: 400,
        type: ShopItemType.removeAds,
        category: ShopItemCategory.premium,
        icon: Icons.block_outlined),
    ShopItem(
        id: featPro,
        nameKey: 'shopFeatPro',
        descKey: 'shopFeatProDesc',
        price: 650,
        type: ShopItemType.feature,
        category: ShopItemCategory.features,
        icon: Icons.inventory_2_outlined),
    ShopItem(
        id: featDoubleCoins,
        nameKey: 'shopFeatDoubleCoins',
        descKey: 'shopFeatDoubleCoinsDesc',
        price: 450,
        type: ShopItemType.feature,
        category: ShopItemCategory.features,
        icon: Icons.stars_rounded),
    ShopItem(
        id: featSound,
        nameKey: 'shopFeatSound',
        descKey: 'shopFeatSoundDesc',
        price: 120,
        type: ShopItemType.feature,
        category: ShopItemCategory.features,
        icon: Icons.volume_up_outlined),
    ShopItem(
        id: featAwake,
        nameKey: 'shopFeatAwake',
        descKey: 'shopFeatAwakeDesc',
        price: 140,
        type: ShopItemType.feature,
        category: ShopItemCategory.features,
        icon: Icons.stay_current_portrait_outlined),
    ShopItem(
        id: featHint,
        nameKey: 'shopFeatHint',
        descKey: 'shopFeatHintDesc',
        price: 180,
        type: ShopItemType.feature,
        category: ShopItemCategory.features,
        icon: Icons.lightbulb_outline_rounded),
  ];

  static ShopItem? find(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
