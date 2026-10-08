import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../providers/shop_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/app_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final shop = context.watch<ShopProvider>();
    return FtrScaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(AppStrings.t(context, 'appearance'), style: AppTypography.title(context: context)),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(value: ThemeMode.light, label: Text(AppStrings.t(context, 'themeLight'))),
              ButtonSegment(value: ThemeMode.dark, label: Text(AppStrings.t(context, 'themeDark'))),
              ButtonSegment(value: ThemeMode.system, label: Text(AppStrings.t(context, 'themeSystem'))),
            ],
            selected: {theme.themeMode},
            onSelectionChanged: (v) => theme.setThemeMode(v.first),
          ),
          const SizedBox(height: 20),
          _SettingsTile(
            icon: Icons.replay_rounded,
            title: AppStrings.t(context, 'resetLook'),
            onTap: () async {
              await shop.resetLookToDefault();
              if (context.mounted) {
                AppToast.show(context, title: AppStrings.t(context, 'defaultRestored'));
              }
            },
          ),
          _SettingsTile(
            icon: Icons.storefront_outlined,
            title: AppStrings.t(context, 'shop'),
            onTap: () => AppTabs.goShop(),
          ),
          if (!shop.isBillingDisabled)
            _SettingsTile(
              icon: Icons.restore_rounded,
              title: AppStrings.t(context, 'restorePurchases'),
              onTap: () {
                shop.restorePurchases();
                AppToast.show(context, title: AppStrings.t(context, 'restoreStarted'));
              },
            ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: AppStrings.t(context, 'privacyPolicy'),
            onTap: () => Navigator.pushNamed(context, '/privacy'),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.t(context, 'about'), style: AppTypography.title(context: context)),
          const SizedBox(height: 10),
          Text(AppStrings.t(context, 'aboutBody'), style: AppTypography.body(context: context)),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: AppTypography.title(size: 16, context: context)),
            ),
          ],
        ),
      ),
    );
  }
}
