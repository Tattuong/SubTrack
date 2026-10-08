import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/shop_provider.dart';
import 'coin_notification.dart';

/// Shows a toast whenever the user earns stars from any source.
class CoinRewardListener extends StatefulWidget {
  final Widget child;

  const CoinRewardListener({super.key, required this.child});

  @override
  State<CoinRewardListener> createState() => _CoinRewardListenerState();
}

class _CoinRewardListenerState extends State<CoinRewardListener> {
  ShopProvider? _shop;

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
    _shop?.removeListener(_onShopChanged);
    super.dispose();
  }

  void _onShopChanged() {
    final shop = _shop;
    final event = shop?.lastCoinEvent;
    if (event == null || shop == null || !mounted) return;

    final balance = shop.coins;
    shop.clearCoinEvent();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CoinNotification.show(event: event, balance: balance);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
