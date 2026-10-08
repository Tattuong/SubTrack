import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/iap_config_service.dart';
import '../../models/app_theme_preset.dart';
import '../../models/shop_item.dart';
import '../../providers/shop_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/coin_balance_chip.dart';
import '../../widgets/coin_purchase_sheet.dart';

enum ShopRewardsTab { themes, backgrounds, skins, features }

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late ShopRewardsTab _tab;

  static const _tabs = [
    (ShopRewardsTab.themes, 'shopMenuThemes', Icons.palette_outlined),
    (ShopRewardsTab.backgrounds, 'shopMenuBackgrounds', Icons.wallpaper_outlined),
    (ShopRewardsTab.skins, 'shopMenuSkins', Icons.circle_outlined),
    (ShopRewardsTab.features, 'shopMenuFeatures', Icons.extension_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tab = AppTabs.shopFeatures.value ? ShopRewardsTab.features : ShopRewardsTab.themes;
    AppTabs.shopFeatures.addListener(_onShopTab);
  }

  void _onShopTab() {
    if (!mounted || !AppTabs.shopFeatures.value) return;
    setState(() => _tab = ShopRewardsTab.features);
  }

  @override
  void dispose() {
    AppTabs.shopFeatures.removeListener(_onShopTab);
    super.dispose();
  }

  List<ShopItem> _itemsFor(ShopRewardsTab tab) {
    return ShopCatalog.items.where((item) {
      return switch (tab) {
        ShopRewardsTab.themes => item.category == ShopItemCategory.themes,
        ShopRewardsTab.backgrounds => item.category == ShopItemCategory.backgrounds,
        ShopRewardsTab.skins => item.category == ShopItemCategory.skins,
        ShopRewardsTab.features =>
          item.category == ShopItemCategory.features || item.category == ShopItemCategory.premium,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final items = _itemsFor(_tab);
    return FtrScaffold(
      body: SafeArea(
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
            child: Row(
              children: [
                if (Navigator.canPop(context))
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
                Expanded(
                  child: Text(
                    AppStrings.t(context, 'shop'),
                    style: AppTypography.title(size: 22, context: context),
                  ),
                ),
                CoinBalanceChip(
                  variant: CoinChipVariant.header,
                  onTap: shop.isBillingDisabled ? () {} : () => CoinPurchaseSheet.show(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: EarnCoinsRow(),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppStrings.t(context, 'shopLooksNote'),
              style: AppTypography.body(size: 12, context: context),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final tab in _tabs)
                  _Moon(
                    label: AppStrings.t(context, tab.$2),
                    icon: tab.$3,
                    selected: _tab == tab.$1,
                    onTap: () => setState(() => _tab = tab.$1),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: items.length,
              itemBuilder: (context, i) => _ShopCard(item: items[i], shop: shop),
            ),
          ),
          if (!shop.isBillingDisabled)
            TextButton(
              onPressed: () {
                shop.restorePurchases();
                AppToast.show(context, title: AppStrings.t(context, 'restoreStarted'));
              },
              child: Text(AppStrings.t(context, 'restorePurchases')),
            ),
          if (shop.configStatus == IapConfigStatus.timeout || shop.configStatus == IapConfigStatus.networkError)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                AppStrings.t(context, shop.configStatus == IapConfigStatus.timeout ? 'configTimeout' : 'configNetworkError'),
                style: AppTypography.body(size: 11, context: context),
                textAlign: TextAlign.center,
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class _Moon extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Moon({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selected ? 50 : 42,
            height: selected ? 50 : 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? primary : Theme.of(context).colorScheme.surface,
            ),
            child: Icon(icon, color: selected ? onPrimary : muted, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.body(size: 11, color: selected ? Theme.of(context).colorScheme.onSurface : muted)),
        ],
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  final ShopItem item;
  final ShopProvider shop;

  const _ShopCard({required this.item, required this.shop});

  @override
  Widget build(BuildContext context) {
    final owned = shop.ownsItem(item.id);
    final active = ShopActions.isActive(shop, item);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        highlighted: active,
        child: Row(
          children: [
            _Preview(item: item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.t(context, item.nameKey), style: AppTypography.title(size: 16, context: context)),
                  Text(AppStrings.t(context, item.descKey), style: AppTypography.body(size: 12, context: context)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Action(shop: shop, item: item, owned: owned, active: active),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final ShopItem item;
  const _Preview({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.type == ShopItemType.theme) {
      final p = AppThemePresets.get(item.id);
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(gradient: p.shopPreviewGradient, borderRadius: BorderRadius.circular(14)),
      );
    }
    if (item.type == ShopItemType.background) {
      final bg = AppBackground.get(item.id);
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(gradient: bg.gradient, borderRadius: BorderRadius.circular(14)),
      );
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
      child: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _Action extends StatelessWidget {
  final ShopProvider shop;
  final ShopItem item;
  final bool owned;
  final bool active;

  const _Action({required this.shop, required this.item, required this.owned, required this.active});

  @override
  Widget build(BuildContext context) {
    if (!owned) {
      return FilledButton(
        onPressed: () => ShopActions.buy(context, shop, item),
        style: FilledButton.styleFrom(backgroundColor: AppColors.coin, foregroundColor: AppColors.onGold),
        child: Text('${item.price}'),
      );
    }
    if (ShopActions.canApply(item)) {
      if (active) {
        return OutlinedButton(
          onPressed: ShopCatalog.isDefaultId(item.id)
              ? null
              : () {
                  shop.setFeatureEnabled(item.id, false);
                  AppToast.show(context, title: AppStrings.t(context, 'defaultRestored'));
                },
          child: Text(AppStrings.t(context, active && ShopCatalog.isDefaultId(item.id) ? 'inUse' : 'useDefault')),
        );
      }
      return FilledButton(
        onPressed: () => ShopActions.apply(context, shop, item),
        child: Text(AppStrings.t(context, 'apply')),
      );
    }
    final on = shop.featureOn(item.id);
    return OutlinedButton(
      onPressed: () => shop.setFeatureEnabled(item.id, !on),
      child: Text(AppStrings.t(context, on ? 'featureOn' : 'featureOff')),
    );
  }
}

class ShopActions {
  static bool isActive(ShopProvider shop, ShopItem item) {
    return switch (item.type) {
      ShopItemType.theme => shop.activeThemeId == item.id,
      ShopItemType.background => shop.activeBackgroundId == item.id,
      ShopItemType.skin => shop.activeSkinId == item.id,
      ShopItemType.feature || ShopItemType.removeAds => shop.featureOn(item.id),
    };
  }

  static bool canApply(ShopItem item) =>
      item.type == ShopItemType.theme || item.type == ShopItemType.background || item.type == ShopItemType.skin;

  static Future<void> apply(BuildContext context, ShopProvider shop, ShopItem item) async {
    switch (item.type) {
      case ShopItemType.theme:
        await shop.selectTheme(item.id);
      case ShopItemType.background:
        await shop.selectBackground(item.id);
      case ShopItemType.skin:
        await shop.selectSkin(item.id);
      default:
        break;
    }
    if (context.mounted) AppToast.show(context, title: AppStrings.t(context, 'applied'));
  }

  static void buy(BuildContext context, ShopProvider shop, ShopItem item) {
    if (item.type == ShopItemType.removeAds &&
        !shop.isBillingDisabled &&
        shop.billing.removeAdsProduct != null &&
        !shop.ownsItem('remove_ads')) {
      shop.buyRemoveAdsViaBilling().then((ok) {
        if (!context.mounted) return;
        if (ok) {
          AppToast.show(context, title: AppStrings.t(context, 'openingBilling'));
        } else if (shop.lastMessage != null) {
          AppToast.show(context, title: AppStrings.t(context, shop.lastMessage!));
        }
      });
      return;
    }
    final result = shop.buyWithCoins(item.id);
    switch (result) {
      case ShopPurchaseResult.success:
        AppToast.show(context, title: AppStrings.t(context, 'purchaseSuccess'));
      case ShopPurchaseResult.insufficientCoins:
        AppToast.show(context, title: AppStrings.t(context, 'insufficientCoins'));
        if (!shop.isBillingDisabled) CoinPurchaseSheet.show(context);
      case ShopPurchaseResult.alreadyOwned:
        AppToast.show(context, title: AppStrings.t(context, 'alreadyOwned'));
      default:
        AppToast.show(context, title: AppStrings.t(context, 'purchaseFailed'));
    }
  }
}
