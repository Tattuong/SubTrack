import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../models/shop_coin_event.dart';
import '../core/navigation/app_navigator.dart';
import 'app_toast.dart';

class CoinNotification {
  static void show({
    BuildContext? context,
    required ShopCoinEvent event,
    required int balance,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = rootNavigatorKey.currentContext ?? context;
      if (ctx == null || !ctx.mounted) return;

      final amount = event.amount.toString();
      var title = AppStrings.t(ctx, event.messageKey, {'amount': amount});
      if (!title.contains(amount)) {
        title = AppStrings.t(ctx, 'coinEarned', {'amount': amount});
      }
      final message = AppStrings.t(ctx, 'coinRewardSub', {'balance': balance.toString()});

      AppToast.show(
        ctx,
        title: title,
        message: message,
        icon: Icons.stars_rounded,
        color: AppColors.coin,
      );
    });
  }
}
