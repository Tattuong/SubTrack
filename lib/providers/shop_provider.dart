import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/constants/iap_constants.dart';
import '../core/services/billing_service.dart';
import '../core/services/iap_config_service.dart';
import '../core/services/storage_service.dart';
import '../models/app_theme_preset.dart';
import '../models/shop_coin_event.dart';
import '../models/shop_item.dart';

enum ShopPurchaseResult {
  success,
  insufficientCoins,
  alreadyOwned,
  notFound,
  error,
}

class ShopProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const _coinsKey = 'st_coins';
  static const _ownedKey = 'st_owned_items';
  static const _enabledKey = 'st_enabled_items';
  static const _activeThemeKey = 'st_active_theme';
  static const _activeBgKey = 'st_active_background';
  static const _activeSkinKey = 'st_active_skin';
  static const _lastDailyKey = 'st_last_daily_reward';
  static const _dayRewardDateKey = 'st_day_reward_date';
  static const _dayRewardCountKey = 'st_day_reward_count';
  static const _processedPurchasesKey = 'st_processed_purchases';
  static const _lastSpinKey = 'st_last_lucky_date';
  static const _loginStreakKey = 'st_login_streak';
  static const _lastStreakDateKey = 'st_last_streak_date';
  static const _firstPurchaseBonusKey = 'st_first_purchase_bonus_used';

  final IapConfigService _configService = IapConfigService();
  final BillingService _billing = BillingService();
  final _random = Random();

  int _coins = 0;
  int _loginStreak = 0;
  bool _firstPurchaseBonusAvailable = true;
  String? _lastDailyDate;
  String? _lastSpinDate;
  String? _lastStreakDate;
  Set<String> _ownedItems = {};
  Set<String> _enabledItems = {};
  String _activeThemeId = ShopCatalog.defaultThemeId;
  String _activeBackgroundId = ShopCatalog.defaultBackgroundId;
  String _activeSkinId = ShopCatalog.defaultSkinId;
  bool _isPurchasing = false;
  bool _purchaseAttemptActive = false;
  int _purchaseAttempt = 0;
  Timer? _purchaseWatch;
  bool _isLoading = true;
  String? _lastMessage;
  Set<String> _processedPurchaseIds = {};
  ShopCoinEvent? _lastCoinEvent;

  int get coins => _coins;
  int get loginStreak => _loginStreak;
  int get displayStreak {
    final today = _dateKey(DateTime.now());
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    if (_lastStreakDate != today && _lastStreakDate != yesterday) return 0;
    return _loginStreak;
  }

  bool get claimedDailyToday => _lastDailyDate == _dateKey(DateTime.now());
  bool get claimedLuckyToday => _lastSpinDate == _dateKey(DateTime.now());

  int get upcomingDailyCoins {
    final nextStreak = claimedDailyToday
        ? _loginStreak.clamp(1, 7)
        : (displayStreak == 0 ? 1 : (_loginStreak + 1).clamp(1, 7));
    final bonus = (nextStreak - 1) * 3;
    return effectiveCoinReward(IapConstants.dailyLoginReward + bonus);
  }
  bool get firstPurchaseBonusAvailable => _firstPurchaseBonusAvailable;
  int get weeklyHotDealPackIndex => IapConstants.weeklyHotDealPackIndex();
  int get weeklyHotDealPackNumber => weeklyHotDealPackIndex + 1;

  ShopItem? get nextUnlockItem {
    ShopItem? cheapest;
    for (final item in ShopCatalog.items) {
      if (ownsItem(item.id) || item.price <= 0) continue;
      if (cheapest == null || item.price < cheapest.price) cheapest = item;
    }
    return cheapest;
  }

  Set<String> get ownedItems => _ownedItems;
  String get activeThemeId => _activeThemeId;
  String get activeBackgroundId => _activeBackgroundId;
  String get activeSkinId => _activeSkinId;
  bool get isPurchasing => _isPurchasing;
  bool get isLoading => _isLoading;
  String? get lastMessage => _lastMessage;
  ShopCoinEvent? get lastCoinEvent => _lastCoinEvent;
  IapConfigService get configService => _configService;
  BillingService get billing => _billing;

  bool get isBillingDisabled => _configService.isBillingDisabled;
  bool get isBillingAvailable =>
      !isBillingDisabled && _billing.isAvailable && _billing.products.isNotEmpty;
  IapConfigStatus get configStatus => _configService.status;

  bool featureOn(String id) => ownsItem(id) && _enabledItems.contains(id);

  bool get hasRemoveAds => featureOn('remove_ads');
  bool get hasDoubleCoins => featureOn(ShopCatalog.featDoubleCoins);
  bool get hasPro => ownsItem(ShopCatalog.featPro);

  int get maxArchive => hasPro ? IapConstants.proArchiveLimit : IapConstants.freeArchiveLimit;

  bool _remoteConnected = false;

  AppThemePreset get activeTheme => AppThemePresets.get(_activeThemeId);
  AppBackground get activeBackground => AppBackground.get(_activeBackgroundId);
  CardStyle get activeCardStyle => CardStyle.get(_activeSkinId);

  bool get isDefaultLook =>
      _activeThemeId == ShopCatalog.defaultThemeId &&
      _activeBackgroundId == ShopCatalog.defaultBackgroundId &&
      _activeSkinId == ShopCatalog.defaultSkinId;

  ShopProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  bool _initialized = false;

  Future<void> init({bool remote = true}) async {
    if (_initialized) return;
    _initialized = true;

    await _loadLocal();
    _isLoading = false;
    notifyListeners();

    if (!remote) return;
    await connectRemote();
  }

  Future<void> connectRemote() async {
    if (_remoteConnected) return;
    _remoteConnected = true;

    await _configService.fetch();
    notifyListeners();

    if (!kIsWeb && !isBillingDisabled && (Platform.isAndroid || Platform.isIOS)) {
      await _billing.init(
        onPurchase: _handlePurchase,
        onError: _onBillingError,
        onCanceled: _onBillingCanceled,
      );
      notifyListeners();
    }
  }

  Future<void> refreshConfig() async {
    await _configService.fetch(forceRefresh: true);
    notifyListeners();
  }

  Future<void> _loadLocal() async {
    _coins = await StorageService.instance.getInt(_coinsKey) ?? 0;
    final owned = await StorageService.instance.getStringList(_ownedKey);
    _ownedItems = owned?.toSet() ?? {};
    final enabled = await StorageService.instance.getStringList(_enabledKey);
    _enabledItems = enabled?.toSet() ?? Set<String>.from(_ownedItems);
    _activeThemeId =
        await StorageService.instance.getString(_activeThemeKey) ?? ShopCatalog.defaultThemeId;
    _activeBackgroundId =
        await StorageService.instance.getString(_activeBgKey) ?? ShopCatalog.defaultBackgroundId;
    _activeSkinId =
        await StorageService.instance.getString(_activeSkinKey) ?? ShopCatalog.defaultSkinId;
    final processed = await StorageService.instance.getStringList(_processedPurchasesKey);
    _processedPurchaseIds = processed?.toSet() ?? {};
    _loginStreak = await StorageService.instance.getInt(_loginStreakKey) ?? 0;
    _lastDailyDate = await StorageService.instance.getString(_lastDailyKey);
    _lastSpinDate = await StorageService.instance.getString(_lastSpinKey);
    _lastStreakDate = await StorageService.instance.getString(_lastStreakDateKey);
    _firstPurchaseBonusAvailable =
        !(await StorageService.instance.getBool(_firstPurchaseBonusKey) ?? false);
  }

  Future<void> _saveLocal() async {
    await StorageService.instance.saveInt(_coinsKey, _coins);
    await StorageService.instance.saveStringList(_ownedKey, _ownedItems.toList());
    await StorageService.instance.saveStringList(_enabledKey, _enabledItems.toList());
    await StorageService.instance.saveString(_activeThemeKey, _activeThemeId);
    await StorageService.instance.saveString(_activeBgKey, _activeBackgroundId);
    await StorageService.instance.saveString(_activeSkinKey, _activeSkinId);
    await StorageService.instance.saveStringList(_processedPurchasesKey, _processedPurchaseIds.toList());
  }

  bool ownsItem(String id) => ShopCatalog.isDefaultId(id) || _ownedItems.contains(id);

  Future<void> resetLookToDefault() async {
    _activeThemeId = ShopCatalog.defaultThemeId;
    _activeBackgroundId = ShopCatalog.defaultBackgroundId;
    _activeSkinId = ShopCatalog.defaultSkinId;
    await _saveLocal();
    notifyListeners();
  }

  ShopPurchaseResult buyWithCoins(String itemId) {
    final item = ShopCatalog.find(itemId);
    if (item == null) return ShopPurchaseResult.notFound;
    if (item.oneTime && _ownedItems.contains(itemId)) {
      return ShopPurchaseResult.alreadyOwned;
    }
    if (_coins < item.price) return ShopPurchaseResult.insufficientCoins;

    _coins -= item.price;
    _ownedItems.add(itemId);
    _enabledItems.add(itemId);
    _applyItem(item);
    _lastMessage = 'purchaseSuccess';
    _saveLocal();
    notifyListeners();
    return ShopPurchaseResult.success;
  }

  void _applyItem(ShopItem item) {
    switch (item.type) {
      case ShopItemType.theme:
        _activeThemeId = item.id;
      case ShopItemType.background:
        _activeBackgroundId = item.id;
      case ShopItemType.skin:
        _activeSkinId = item.id;
      case ShopItemType.removeAds:
      case ShopItemType.feature:
        _enabledItems.add(item.id);
    }
  }

  Future<void> setFeatureEnabled(String itemId, bool enabled) async {
    if (!ownsItem(itemId) || ShopCatalog.isDefaultId(itemId)) return;
    if (enabled) {
      _enabledItems.add(itemId);
      final item = ShopCatalog.find(itemId);
      if (item != null) _applyItem(item);
    } else {
      _enabledItems.remove(itemId);
      final item = ShopCatalog.find(itemId);
      if (item?.type == ShopItemType.theme) _activeThemeId = ShopCatalog.defaultThemeId;
      if (item?.type == ShopItemType.background) _activeBackgroundId = ShopCatalog.defaultBackgroundId;
      if (item?.type == ShopItemType.skin) _activeSkinId = ShopCatalog.defaultSkinId;
    }
    await _saveLocal();
    notifyListeners();
  }

  Future<void> resetCoins() async {
    _coins = 0;
    _lastCoinEvent = null;
    await _saveLocal();
    notifyListeners();
  }

  Future<void> addCoinsQuiet(int amount) async {
    if (amount <= 0) return;
    _coins += amount;
    await _saveLocal();
    notifyListeners();
  }

  void addCoins(int amount, {String messageKey = 'coinsAdded'}) {
    if (amount <= 0) return;
    _coins += amount;
    _lastMessage = messageKey;
    _emitCoinEarned(amount, messageKey);
    _saveLocal();
    notifyListeners();
  }

  int effectiveCoinReward(int base) => hasDoubleCoins ? base * 2 : base;

  Future<bool> buyCoinPack(ProductDetails product) {
    if (isBillingDisabled || !_billing.isAvailable) return Future.value(false);
    return _startBilling(() => _billing.buyCoinPack(product));
  }

  Future<bool> buyRemoveAdsViaBilling() {
    if (isBillingDisabled || !_billing.isAvailable || _billing.removeAdsProduct == null) {
      return Future.value(false);
    }
    if (_ownedItems.contains('remove_ads')) return Future.value(false);
    return _startBilling(() => _billing.buyRemoveAds());
  }

  Future<bool> buyProViaBilling() {
    if (isBillingDisabled || !_billing.isAvailable || _billing.proProduct == null) {
      return Future.value(false);
    }
    if (hasPro) return Future.value(false);
    return _startBilling(() => _billing.buyPro());
  }

  Future<bool> _startBilling(Future<bool> Function() buy) async {
    _beginPurchase();
    try {
      final ok = await buy();
      if (!ok) _failPurchase();
      return ok;
    } catch (e) {
      debugPrint('Billing buy error: $e');
      _failPurchase();
      return false;
    }
  }

  void _beginPurchase() {
    _purchaseAttempt += 1;
    _purchaseAttemptActive = true;
    _isPurchasing = true;
    _lastMessage = null;
    _armPurchaseWatch(const Duration(seconds: 12), _purchaseAttempt);
    notifyListeners();
  }

  void _armPurchaseWatch(Duration delay, int attempt) {
    _purchaseWatch?.cancel();
    _purchaseWatch = Timer(delay, () {
      if (attempt != _purchaseAttempt || !_isPurchasing) return;
      final state = WidgetsBinding.instance.lifecycleState;
      if (state != AppLifecycleState.resumed) {
        _armPurchaseWatch(const Duration(seconds: 5), attempt);
        return;
      }
      _clearPurchaseUi();
    });
  }

  void _clearPurchaseUi() {
    _purchaseWatch?.cancel();
    _purchaseWatch = null;
    _purchaseAttemptActive = false;
    _isPurchasing = false;
    notifyListeners();
  }

  void _failPurchase() {
    if (!_purchaseAttemptActive && !_isPurchasing) return;
    _purchaseWatch?.cancel();
    _purchaseWatch = null;
    _purchaseAttemptActive = false;
    _isPurchasing = false;
    _lastMessage = 'purchaseFailed';
    notifyListeners();
  }

  /// Clears a stuck spinner when the sheet opens or closes, but not while Play is on screen.
  void releasePurchaseUi() {
    if (!_isPurchasing) return;
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) return;
    _clearPurchaseUi();
  }

  void _onBillingCanceled() {
    if (!_purchaseAttemptActive && !_isPurchasing) return;
    _clearPurchaseUi();
  }

  void _onBillingError() => _failPurchase();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isPurchasing) return;
    if (state == AppLifecycleState.resumed) {
      _armPurchaseWatch(const Duration(milliseconds: 600), _purchaseAttempt);
    }
  }

  Future<void> restorePurchases() async {
    if (isBillingDisabled || !_billing.isAvailable) return;
    await _billing.restorePurchases();
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    _purchaseWatch?.cancel();
    _purchaseWatch = null;
    _purchaseAttemptActive = false;
    final purchaseId = purchase.purchaseID ?? '${purchase.productID}_${purchase.transactionDate}';
    if (_processedPurchaseIds.contains(purchaseId)) {
      _isPurchasing = false;
      notifyListeners();
      return;
    }

    if (IapConstants.isRemoveAdsProduct(purchase.productID)) {
      _ownedItems.add('remove_ads');
      _enabledItems.add('remove_ads');
      _processedPurchaseIds.add(purchaseId);
      _lastMessage = 'removeAdsUnlocked';
    } else if (IapConstants.isProProduct(purchase.productID)) {
      _ownedItems.add(ShopCatalog.featPro);
      _enabledItems.add(ShopCatalog.featPro);
      _processedPurchaseIds.add(purchaseId);
      _lastMessage = 'proUnlocked';
    } else {
      final base = IapConstants.coinsForProduct(purchase.productID);
      if (base > 0) {
        final packIndex = IapConstants.coinPackIds.indexOf(purchase.productID);
        final isHotDeal = packIndex == weeklyHotDealPackIndex;
        var bonus = 0;
        if (_firstPurchaseBonusAvailable) {
          bonus += IapConstants.bonusCoinsForPack(packIndex, isFirstPurchase: true, isHotDeal: false);
          _firstPurchaseBonusAvailable = false;
          await StorageService.instance.saveBool(_firstPurchaseBonusKey, true);
        }
        if (isHotDeal) {
          bonus += IapConstants.bonusCoinsForPack(packIndex, isFirstPurchase: false, isHotDeal: true);
        }
        final total = base + bonus;
        _coins += total;
        _processedPurchaseIds.add(purchaseId);
        _lastMessage = bonus > 0 ? 'coinsAddedWithBonus' : 'coinsAdded';
        _emitCoinEarned(total, bonus > 0 ? 'coinsAddedWithBonus' : 'coinsAdded');
      }
    }

    _isPurchasing = false;
    await _saveLocal();
    notifyListeners();
  }

  Future<bool> claimDailyReward() async {
    final today = _dateKey(DateTime.now());
    final last = await StorageService.instance.getString(_lastDailyKey);
    if (last == today) return false;

    await _updateLoginStreak(today);

    final streakBonus = (_loginStreak.clamp(1, 7) - 1) * 3;
    final amount = effectiveCoinReward(IapConstants.dailyLoginReward + streakBonus);
    _coins += amount;
    _lastDailyDate = today;
    await StorageService.instance.saveString(_lastDailyKey, today);
    _lastMessage = 'dailyRewardClaimed';
    _emitCoinEarned(amount, 'dailyRewardClaimed');
    await _saveLocal();
    notifyListeners();
    return true;
  }

  Future<void> _updateLoginStreak(String today) async {
    final lastStreak = await StorageService.instance.getString(_lastStreakDateKey);
    if (lastStreak == today) return;

    if (lastStreak != null) {
      final parts = lastStreak.split('-');
      if (parts.length == 3) {
        final lastDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final diff = DateTime.now().difference(lastDate).inDays;
        _loginStreak = diff == 1 ? _loginStreak + 1 : 1;
      } else {
        _loginStreak = 1;
      }
    } else {
      _loginStreak = 1;
    }

    await StorageService.instance.saveString(_lastStreakDateKey, today);
    await StorageService.instance.saveInt(_loginStreakKey, _loginStreak);
    _lastStreakDate = today;
  }

  Future<bool> hasLuckyDroppedToday() async => claimedLuckyToday;

  Future<int> claimLuckyDrop() async {
    if (await hasLuckyDroppedToday()) return 0;

    final prize = effectiveCoinReward(_pickLuckyPrize());
    _coins += prize;
    _lastSpinDate = _dateKey(DateTime.now());
    await StorageService.instance.saveString(_lastSpinKey, _lastSpinDate!);
    _lastMessage = 'spinRewardEarned';
    _emitCoinEarned(prize, 'spinRewardEarned');
    await _saveLocal();
    notifyListeners();
    return prize;
  }

  int _pickLuckyPrize() {
    final totalWeight = IapConstants.luckyPrizes.fold<int>(0, (s, e) => s + e.$2);
    var roll = _random.nextInt(totalWeight);
    for (final (coins, weight) in IapConstants.luckyPrizes) {
      roll -= weight;
      if (roll < 0) return coins;
    }
    return IapConstants.luckyPrizes.first.$1;
  }

  int effectiveCoinsForPackIndex(int packIndex) {
    final base = packIndex >= 0 && packIndex < IapConstants.coinPackAmounts.length
        ? IapConstants.coinPackAmounts[packIndex]
        : 0;
    return base +
        IapConstants.bonusCoinsForPack(
          packIndex,
          isFirstPurchase: _firstPurchaseBonusAvailable,
          isHotDeal: packIndex == weeklyHotDealPackIndex,
        );
  }

  Future<bool> hasClaimedDailyToday() async => claimedDailyToday;

  Future<bool> rewardForTestStart() {
    return _dailyReward(
      dateKey: _dayRewardDateKey,
      countKey: _dayRewardCountKey,
      max: IapConstants.maxDayRewards,
      amount: effectiveCoinReward(IapConstants.testStartReward),
      messageKey: 'activityCreateReward',
    );
  }

  Future<bool> rewardForPlan() {
    return _dailyReward(
      dateKey: _dayRewardDateKey,
      countKey: _dayRewardCountKey,
      max: IapConstants.maxDayRewards,
      amount: effectiveCoinReward(IapConstants.testCompleteReward),
      messageKey: 'planReward',
    );
  }

  Future<bool> rewardForTrip() {
    return _dailyReward(
      dateKey: _dayRewardDateKey,
      countKey: _dayRewardCountKey,
      max: IapConstants.maxDayRewards,
      amount: effectiveCoinReward(IapConstants.testCompleteReward),
      messageKey: 'tripReward',
    );
  }

  Future<bool> rewardForWorkflow() {
    return _dailyReward(
      dateKey: _dayRewardDateKey,
      countKey: _dayRewardCountKey,
      max: IapConstants.maxDayRewards,
      amount: effectiveCoinReward(IapConstants.testCompleteReward),
      messageKey: 'workflowReward',
    );
  }

  Future<bool> rewardForTestComplete() {
    return _dailyReward(
      dateKey: _dayRewardDateKey,
      countKey: _dayRewardCountKey,
      max: IapConstants.maxDayRewards,
      amount: effectiveCoinReward(IapConstants.testCompleteReward),
      messageKey: 'activityCardReward',
    );
  }

  Future<bool> rewardForAccuracy() {
    return _dailyReward(
      dateKey: _dayRewardDateKey,
      countKey: _dayRewardCountKey,
      max: IapConstants.maxDayRewards,
      amount: effectiveCoinReward(IapConstants.accuracyReward),
      messageKey: 'activityMilestoneReward',
    );
  }

  Future<bool> _dailyReward({
    required String dateKey,
    required String countKey,
    required int max,
    required int amount,
    required String messageKey,
  }) async {
    final today = _dateKey(DateTime.now());
    final savedDate = await StorageService.instance.getString(dateKey);
    var count = await StorageService.instance.getInt(countKey) ?? 0;

    if (savedDate != today) {
      count = 0;
      await StorageService.instance.saveString(dateKey, today);
    }
    if (count >= max) return false;

    _coins += amount;
    count++;
    await StorageService.instance.saveInt(countKey, count);
    _emitCoinEarned(amount, messageKey);
    await _saveLocal();
    notifyListeners();
    return true;
  }

  Future<void> selectTheme(String themeId) async {
    if (themeId != ShopCatalog.defaultThemeId && !_ownedItems.contains(themeId)) return;
    _activeThemeId = themeId;
    if (themeId != ShopCatalog.defaultThemeId) _enabledItems.add(themeId);
    await _saveLocal();
    notifyListeners();
  }

  Future<void> selectBackground(String bgId) async {
    if (bgId != ShopCatalog.defaultBackgroundId && !_ownedItems.contains(bgId)) return;
    _activeBackgroundId = bgId;
    if (bgId != ShopCatalog.defaultBackgroundId) _enabledItems.add(bgId);
    await _saveLocal();
    notifyListeners();
  }

  Future<void> selectSkin(String skinId) async {
    if (skinId != ShopCatalog.defaultSkinId && !_ownedItems.contains(skinId)) return;
    _activeSkinId = skinId;
    if (skinId != ShopCatalog.defaultSkinId) _enabledItems.add(skinId);
    await _saveLocal();
    notifyListeners();
  }

  void clearLastMessage() => _lastMessage = null;
  void clearCoinEvent() => _lastCoinEvent = null;

  void _emitCoinEarned(int amount, String messageKey) {
    if (amount <= 0) return;
    _lastCoinEvent = ShopCoinEvent(amount: amount, messageKey: messageKey);
  }

  String _dateKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

  @override
  void dispose() {
    _purchaseWatch?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _billing.dispose();
    super.dispose();
  }
}
