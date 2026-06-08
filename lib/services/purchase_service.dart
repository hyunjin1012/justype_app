import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService extends ChangeNotifier {
  static const String plusProductId = 'com.hyunjin.justype.plus.lifetime';
  static const String _plusUnlockedKey = 'plus_unlocked';

  final InAppPurchase _inAppPurchase;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _isPlusUnlocked = false;
  String _statusMessage = '';
  ProductDetails? _plusProduct;

  PurchaseService({InAppPurchase? inAppPurchase})
      : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  bool get isPlusUnlocked => _isPlusUnlocked;
  String get statusMessage => _statusMessage;
  ProductDetails? get plusProduct => _plusProduct;
  String get plusPrice => _plusProduct?.price ?? '';
  bool get canBuyPlus =>
      _isAvailable && _plusProduct != null && !_purchasePending;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    await _loadSavedEntitlement();

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _purchasePending = false;
        _statusMessage = 'Unable to complete purchase. Please try again.';
        notifyListeners();
      },
    );

    _isAvailable = await _inAppPurchase.isAvailable();
    if (_isAvailable) {
      await _loadProducts();
    } else {
      _statusMessage = 'In-app purchases are unavailable on this device.';
    }

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> buyPlus() async {
    await initialize();

    final product = _plusProduct;
    if (product == null) {
      _statusMessage =
          'JusType Plus is not available yet. Please check App Store setup.';
      notifyListeners();
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    _purchasePending = true;
    _statusMessage = '';
    notifyListeners();

    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await initialize();

    _purchasePending = true;
    _statusMessage = 'Checking previous purchases...';
    notifyListeners();

    await _inAppPurchase.restorePurchases();
  }

  Future<void> _loadProducts() async {
    final response = await _inAppPurchase.queryProductDetails({
      plusProductId,
    });

    if (response.error != null) {
      _statusMessage = 'Unable to load JusType Plus from the App Store.';
      return;
    }

    if (response.notFoundIDs.isNotEmpty) {
      _statusMessage =
          'JusType Plus is not configured in App Store Connect yet.';
    }

    if (response.productDetails.isNotEmpty) {
      _plusProduct = response.productDetails.first;
      _statusMessage = '';
    }
  }

  Future<void> _loadSavedEntitlement() async {
    final prefs = await SharedPreferences.getInstance();
    _isPlusUnlocked = prefs.getBool(_plusUnlockedKey) ?? false;
  }

  Future<void> _unlockPlus() async {
    _isPlusUnlocked = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_plusUnlockedKey, true);
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.productID != plusProductId) {
        continue;
      }

      if (purchaseDetails.status == PurchaseStatus.pending) {
        _purchasePending = true;
      } else {
        _purchasePending = false;
      }

      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        await _unlockPlus();
        _statusMessage = 'JusType Plus is unlocked.';
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _statusMessage = 'Purchase failed. Please try again.';
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        _statusMessage = 'Purchase canceled.';
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }

    notifyListeners();
  }

  @visibleForTesting
  Future<void> resetForTesting() async {
    _isPlusUnlocked = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_plusUnlockedKey);
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
