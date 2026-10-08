import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/ad_constants.dart';
import 'core/navigation/app_navigator.dart';
import 'core/services/ad_service.dart';
import 'core/services/hive_service.dart';
import 'core/services/storage_service.dart';
import 'models/app_theme_preset.dart';
import 'providers/plan_provider.dart';
import 'providers/shop_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home/settings_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/shop/shop_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/coin_reward_listener.dart';

late final ThemeProvider appThemeProvider;
late final ShopProvider appShopProvider;
late final PlanProvider appPlanProvider;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await StorageService.instance.init();

  appThemeProvider = ThemeProvider();
  await appThemeProvider.init();

  appShopProvider = ShopProvider();
  await appShopProvider.init(remote: false);

  appPlanProvider = PlanProvider(appShopProvider);
  await appPlanProvider.init();
  const demoWipeKey = 'st_demo_wiped';
  if (await StorageService.instance.getBool(demoWipeKey) != true) {
    await StorageService.instance.saveDataList('st_plans', []);
    await appPlanProvider.init();
    await StorageService.instance.saveBool(demoWipeKey, true);
  }

  runApp(const SubTrackApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(appShopProvider.connectRemote());
    if (AdConstants.isConfigured) unawaited(AdService.init());
  });
}

class SubTrackApp extends StatelessWidget {
  const SubTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appThemeProvider),
        ChangeNotifierProvider.value(value: appShopProvider),
        ChangeNotifierProvider.value(value: appPlanProvider),
      ],
      child: const _ThemedApp(),
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<ThemeProvider, ThemeMode>((theme) => theme.themeMode);
    final themeId = context.select<ShopProvider, String>((shop) => shop.activeThemeId);
    final preset = AppThemePresets.get(themeId);
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'SubTrack',
      debugShowCheckedModeBanner: false,
      theme: preset.lightTheme(),
      darkTheme: preset.darkTheme(),
      themeMode: themeMode,
      locale: const Locale('en'),
      builder: (context, child) => CoinRewardListener(child: child ?? const SizedBox.shrink()),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: const SplashScreen(),
      routes: {
        '/shop': (_) => const ShopScreen(),
        '/privacy': (_) => const PrivacyPolicyScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
