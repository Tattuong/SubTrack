import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/iap_constants.dart';
import '../core/services/iap_config_service.dart';
import '../models/app_theme_preset.dart';
import '../providers/shop_provider.dart';
import 'app_toast.dart';
import 'app_ui.dart';

class CoinPurchaseSheet {
  static Future<void> show(BuildContext context) async {
    final shop = context.read<ShopProvider>();
    if (shop.isBillingDisabled) return;

    shop.releasePurchaseUi();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.72;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: const _CoinPurchaseSheet(),
        );
      },
    );
    shop.releasePurchaseUi();
  }
}

class _CoinPurchaseSheet extends StatefulWidget {
  const _CoinPurchaseSheet();

  @override
  State<_CoinPurchaseSheet> createState() => _CoinPurchaseSheetState();
}

class _CoinPurchaseSheetState extends State<_CoinPurchaseSheet> {
  ShopProvider? _shop;
  bool _closedAfterPurchase = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shop = context.read<ShopProvider>();
    if (_shop != shop) {
      _shop?.removeListener(_onShopChanged);
      _shop = shop;
      _shop!.addListener(_onShopChanged);
    }
  }

  @override
  void dispose() {
    _shop?.releasePurchaseUi();
    _shop?.removeListener(_onShopChanged);
    super.dispose();
  }

  void _onShopChanged() {
    if (_closedAfterPurchase || !mounted) return;
    final shop = _shop;
    if (shop == null) return;

    if (!shop.isPurchasing &&
        (shop.lastMessage == 'coinsAdded' || shop.lastMessage == 'coinsAddedWithBonus')) {
      _closedAfterPurchase = true;
      shop.clearLastMessage();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final products = shop.billing.products;
    final status = _status(context, shop);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.t(context, 'buyCoins'),
                  style: AppTypography.titleLarge(color: AppColors.textPrimary, context: context).copyWith(fontSize: 20),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: AppColors.mutedInk(context)),
              ),
            ],
          ),
        ),
        if (shop.isPurchasing)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryOf(context)),
                ),
                const SizedBox(width: 8),
                Text(AppStrings.t(context, 'openingBilling'), style: TextStyle(color: AppColors.mutedInk(context), fontSize: 13)),
              ],
            ),
          ),
        if (products.isNotEmpty)
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              children: [
                _BalanceHero(shop: shop),
                if (status != null) ...[const SizedBox(height: 12), status],
                const SizedBox(height: 16),
                Text(AppStrings.t(context, 'buyCoinsDesc'), style: TextStyle(color: AppColors.mutedInk(context), fontSize: 13)),
                const SizedBox(height: 12),
                for (var i = 0; i < products.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _PackCard(product: products[i], index: i),
                ],
                if (!shop.hasRemoveAds && shop.billing.removeAdsProduct != null) ...[
                  const SizedBox(height: 12),
                  _RemoveAdsCard(product: shop.billing.removeAdsProduct!),
                ],
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BalanceHero(shop: shop),
                const SizedBox(height: 12),
                status ?? _EmptyBillingState(text: AppStrings.t(context, shop.billing.isAvailable ? 'productsNotFound' : 'billingUnavailable')),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _EarnHintRow(text: AppStrings.t(context, 'earnCoinsHint')),
        ),
      ],
    );
  }

  Widget? _status(BuildContext context, ShopProvider shop) {
    if (shop.configStatus != IapConfigStatus.networkError && shop.configStatus != IapConfigStatus.timeout) {
      return null;
    }
    return _StatusBanner(
      icon: Icons.wifi_off_outlined,
      text: shop.configStatus == IapConfigStatus.timeout
          ? AppStrings.t(context, 'configTimeout')
          : AppStrings.t(context, 'configNetworkError'),
      color: AppColors.warning,
    );
  }
}

class _BalanceHero extends StatelessWidget {
  final ShopProvider shop;

  const _BalanceHero({required this.shop});

  @override
  Widget build(BuildContext context) {
    final hotIndex = shop.weeklyHotDealPackIndex;
    final hotTotal = shop.effectiveCoinsForPackIndex(hotIndex);
    final hotBonus = hotTotal - IapConstants.coinPackAmounts[hotIndex];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: context.ftrTheme.balanceGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.primaryOf(context).withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppStrings.t(context, 'coinBalanceLabel'),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (shop.firstPurchaseBonusAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppStrings.t(context, 'firstPurchaseBadge'),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.coin, size: 32),
              const SizedBox(width: 8),
              Text(
                '${shop.coins}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  'coins',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (hotBonus > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: AppColors.coin, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.t(context, 'purchasePromoDesc', {
                        'pack': shop.weeklyHotDealPackNumber.toString(),
                        'coins': hotTotal.toString(),
                        'bonus': hotBonus.toString(),
                      }),
                      style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final ProductDetails product;
  final int index;

  const _PackCard({required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    final shop = context.read<ShopProvider>();
    final packIndex = IapConstants.coinPackIds.indexOf(product.id);
    final base = IapConstants.coinsForProduct(product.id);
    final total = shop.effectiveCoinsForPackIndex(packIndex);
    final bonus = total - base;
    final isHotDeal = packIndex == shop.weeklyHotDealPackIndex;
    final isBestValue = packIndex == IapConstants.bestValuePackIndex;

    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: shop.isPurchasing ? null : () => _buy(context, shop),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHotDeal
                  ? AppColors.coin
                  : isBestValue
                      ? AppColors.primaryOf(context)
                      : AppColors.borderOf(context),
              width: isHotDeal || isBestValue ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.coin.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.monetization_on_rounded, color: AppColors.coin, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$total',
                            style: AppTypography.titleLarge(context: context).copyWith(fontSize: 20),
                          ),
                          const SizedBox(width: 4),
                          Text('coins', style: TextStyle(color: AppColors.mutedInk(context), fontSize: 13)),
                          const Spacer(),
                          if (isHotDeal) _PackBadge(label: AppStrings.t(context, 'hotDealBadge'), color: AppColors.coin),
                          if (isBestValue) ...[
                            if (isHotDeal) const SizedBox(width: 4),
                            _PackBadge(label: AppStrings.t(context, 'bestValueBadge'), color: AppColors.primaryOf(context)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bonus > 0
                            ? AppStrings.t(context, 'coinBonusExtra', {'base': base.toString(), 'bonus': bonus.toString()})
                            : AppStrings.t(context, 'coinPack', {'num': (packIndex + 1).toString()}),
                        style: TextStyle(
                          color: bonus > 0 ? AppColors.success : AppColors.mutedInk(context),
                          fontSize: 12,
                          fontWeight: bonus > 0 ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: shop.isPurchasing ? null : () => _buy(context, shop),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOf(context),
                    foregroundColor: AppColors.onPrimaryOf(context),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(product.price, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _buy(BuildContext context, ShopProvider shop) async {
    final ok = await shop.buyCoinPack(product);
    if (!context.mounted) return;
    if (ok) {
      AppToast.show(context, title: AppStrings.t(context, 'openingBilling'));
    } else if (shop.lastMessage != null) {
      AppToast.show(context, title: AppStrings.t(context, shop.lastMessage!));
    }
  }
}

class _RemoveAdsCard extends StatelessWidget {
  final ProductDetails product;

  const _RemoveAdsCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: shop.isPurchasing ? null : () => _buy(context, shop),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryOf(context), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOf(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.block_outlined, color: AppColors.primaryOf(context), size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t(context, 'shopRemoveAds'),
                        style: AppTypography.titleLarge(context: context).copyWith(fontSize: 16),
                      ),
                      Text(
                        AppStrings.t(context, 'shopRemoveAdsDesc'),
                        style: TextStyle(color: AppColors.mutedInk(context), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: shop.isPurchasing ? null : () => _buy(context, shop),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOf(context),
                    foregroundColor: AppColors.onPrimaryOf(context),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(product.price, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _buy(BuildContext context, ShopProvider shop) async {
    final ok = await shop.buyRemoveAdsViaBilling();
    if (!context.mounted) return;
    if (ok) {
      AppToast.show(context, title: AppStrings.t(context, 'openingBilling'));
    } else if (shop.lastMessage != null) {
      AppToast.show(context, title: AppStrings.t(context, shop.lastMessage!));
    }
  }
}

class _PackBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PackBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 9)),
    );
  }
}

class _EmptyBillingState extends StatelessWidget {
  final String text;

  const _EmptyBillingState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primarySoftOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        children: [
          Icon(Icons.storefront_outlined, size: 36, color: AppColors.mutedInk(context).withValues(alpha: 0.7)),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.secondaryInk(context), fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _EarnHintRow extends StatelessWidget {
  final String text;

  const _EarnHintRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySoftOf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.mutedInk(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: AppColors.mutedInk(context), fontSize: 11, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusBanner({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 12))),
        ],
      ),
    );
  }
}
