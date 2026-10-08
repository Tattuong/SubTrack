import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/app_theme_preset.dart';
import '../core/navigation/app_navigator.dart';
import '../providers/shop_provider.dart';

enum CoinChipVariant { standard, header }

class CoinBalanceChip extends StatefulWidget {
  final VoidCallback? onTap;
  final CoinChipVariant variant;
  final bool vipStyle;

  const CoinBalanceChip({
    super.key,
    this.onTap,
    this.variant = CoinChipVariant.standard,
    this.vipStyle = false,
  });

  @override
  State<CoinBalanceChip> createState() => _CoinBalanceChipState();
}

class _CoinBalanceChipState extends State<CoinBalanceChip> with SingleTickerProviderStateMixin {
  ShopProvider? _shop;
  int _lastCoins = 0;
  int? _delta;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shop = context.read<ShopProvider>();
    if (_shop != shop) {
      _shop?.removeListener(_onShopChanged);
      _shop = shop;
      _lastCoins = shop.coins;
      _shop!.addListener(_onShopChanged);
    }
  }

  @override
  void dispose() {
    _shop?.removeListener(_onShopChanged);
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onShopChanged() {
    final shop = _shop;
    if (shop == null || !mounted) return;

    final gained = shop.coins - _lastCoins;
    if (gained != 0 && mounted) {
      setState(() {
        if (gained > 0) _delta = gained;
      });
      if (gained > 0) {
        _pulseCtrl.forward(from: 0);
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (mounted) setState(() => _delta = null);
        });
      }
    }
    _lastCoins = shop.coins;
  }

  @override
  Widget build(BuildContext context) {
    final coins = context.select<ShopProvider, int>((s) => s.coins);
    final ftr = context.ftrTheme;
    final header = widget.variant == CoinChipVariant.header;
    final vip = widget.vipStyle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap ?? () => AppTabs.goShop(),
        borderRadius: BorderRadius.circular(vip && header ? 4 : (header ? 12 : 20)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                height: header ? 34 : 36,
                padding: EdgeInsets.symmetric(horizontal: header ? 10 : 12),
                alignment: Alignment.center,
                decoration: vip && header
                    ? BoxDecoration(
                        color: ftr.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ftr.primary.withValues(alpha: 0.45)),
                      )
                    : ftr.coinChip(header: header),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      color: vip && header ? AppColors.primaryLightOf(context) : AppColors.coin,
                      size: header ? 16 : 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$coins',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkOf(context),
                        fontSize: header ? 13 : 14,
                        height: 1,
                      ),
                    ),
                    if (_delta != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '+$_delta',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                          fontSize: header ? 12 : 13,
                          height: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EarnCoinsRow extends StatelessWidget {
  const EarnCoinsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    return Row(
      children: [
        Expanded(
          child: _EarnCard(
            icon: shop.claimedDailyToday ? Icons.check_rounded : Icons.today_outlined,
            title: 'Daily',
            detail: shop.claimedDailyToday ? 'Claimed' : '+${shop.upcomingDailyCoins} coins',
            enabled: !shop.claimedDailyToday,
            onTap: () => shop.claimDailyReward(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _EarnCard(
            icon: shop.claimedLuckyToday ? Icons.check_rounded : Icons.casino_outlined,
            title: 'Lucky',
            detail: shop.claimedLuckyToday ? 'Spun today' : 'Spin once',
            enabled: !shop.claimedLuckyToday,
            onTap: () => shop.claimLuckyDrop(),
          ),
        ),
      ],
    );
  }
}

class _EarnCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final bool enabled;
  final VoidCallback onTap;

  const _EarnCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF0F766E);
    final ink = enabled ? const Color(0xFF12343A) : const Color(0xFF8AA0A4);
    return Material(
      color: enabled ? Colors.white : const Color(0xFFEEF4F3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: enabled ? const Color(0xFFE7F6F3) : const Color(0xFFE4EEEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: enabled ? teal : ink),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: ink, height: 1.1)),
                    const SizedBox(height: 2),
                    Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: enabled ? teal : ink)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
