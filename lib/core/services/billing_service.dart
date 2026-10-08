import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../constants/iap_constants.dart';

typedef PurchaseCallback = Future<void> Function(PurchaseDetails purchase);
typedef PurchaseSignal = void Function();

class BillingService {
  InAppPurchase get _iap => InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool isAvailable = false;
  bool isInitialized = false;
  List<ProductDetails> coinProducts = [];
  ProductDetails? removeAdsProduct;
  ProductDetails? proProduct;
  String? lastError;

  List<ProductDetails> get products => coinProducts;

  Future<void> init({
    required PurchaseCallback onPurchase,
    required PurchaseSignal onError,
    required PurchaseSignal onCanceled,
  }) async {
    if (isInitialized) return;

    try {
      isAvailable = await _iap.isAvailable();
      if (!isAvailable) {
        lastError = 'Billing not available on this device';
        isInitialized = true;
        return;
      }

      _subscription?.cancel();
      _subscription = _iap.purchaseStream.listen(
        (purchases) async {
          for (final purchase in purchases) {
            if (purchase.status == PurchaseStatus.pending) continue;

            if (purchase.status == PurchaseStatus.purchased ||
                purchase.status == PurchaseStatus.restored) {
              await onPurchase(purchase);
            } else if (purchase.status == PurchaseStatus.canceled) {
              onCanceled();
            } else if (purchase.status == PurchaseStatus.error) {
              lastError = purchase.error?.message ?? 'Purchase failed';
              onError();
            }

            final canceledWithoutId = purchase.status == PurchaseStatus.canceled &&
                (purchase.purchaseID == null || purchase.purchaseID!.isEmpty);
            if (purchase.pendingCompletePurchase && !canceledWithoutId) {
              await _iap.completePurchase(purchase);
            }
          }
        },
        onError: (Object e) {
          lastError = e.toString();
          onError();
        },
      );

      await loadProducts();
      isInitialized = true;
    } catch (e) {
      lastError = e.toString();
      debugPrint('Billing init error: $e');
      isInitialized = true;
    }
  }

  Future<void> loadProducts() async {
    if (!isAvailable) return;

    final response = await _iap.queryProductDetails(IapConstants.allProductIds.toSet());
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }
    if (response.error != null) {
      lastError = response.error!.message;
    }

    coinProducts = response.productDetails
        .where((p) => IapConstants.coinPackIds.contains(p.id))
        .toList()
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

    removeAdsProduct = response.productDetails
        .where((p) => p.id == IapConstants.removeAdsProductId)
        .firstOrNull;

    proProduct = response.productDetails
        .where((p) => p.id == IapConstants.proProductId)
        .firstOrNull;
  }

  Future<bool> buyCoinPack(ProductDetails product) async {
    if (!isAvailable) return false;
    try {
      return await _iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (e) {
      lastError = e.toString();
      debugPrint('buyCoinPack error: $e');
      return false;
    }
  }

  Future<bool> buyRemoveAds() async {
    if (!isAvailable || removeAdsProduct == null) return false;
    try {
      return await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: removeAdsProduct!));
    } catch (e) {
      lastError = e.toString();
      debugPrint('buyRemoveAds error: $e');
      return false;
    }
  }

  Future<bool> buyPro() async {
    if (!isAvailable || proProduct == null) return false;
    try {
      return await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: proProduct!));
    } catch (e) {
      lastError = e.toString();
      debugPrint('buyPro error: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!isAvailable) return;
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
