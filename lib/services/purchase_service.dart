import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService extends ChangeNotifier {
  static const String plusProductId = 'com.hyunjin.justype.plus.lifetime';
  static const String _verifiedPlusEntitlementKey = 'plus_store_entitlement_v1';

  final InAppPurchase _inAppPurchase;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Timer? _storeRequestTimeout;

  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _storeRequestInProgress = false;
  DateTime? _purchaseRequestStartedAt;
  _StoreRequestType? _storeRequestType;
  bool _isPlusUnlocked = false;
  String _statusMessage = '';
  ProductDetails? _plusProduct;

  PurchaseService({
    InAppPurchase? inAppPurchase,
  }) : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

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

    await _loadStoredEntitlement();

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _purchasePending = false;
        _storeRequestInProgress = false;
        _storeRequestType = null;
        _purchaseRequestStartedAt = null;
        _storeRequestTimeout?.cancel();
        _statusMessage =
            'The purchase could not be completed. Please try again.';
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
          'JusType Plus is temporarily unavailable. Please try again later.';
      notifyListeners();
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    _purchasePending = true;
    _storeRequestInProgress = true;
    _storeRequestType = _StoreRequestType.purchase;
    _purchaseRequestStartedAt = DateTime.now();
    _statusMessage = 'Connecting to App Store...';
    notifyListeners();

    try {
      final didStart =
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      if (!didStart) {
        _purchasePending = false;
        _storeRequestInProgress = false;
        _storeRequestType = null;
        _purchaseRequestStartedAt = null;
        _statusMessage =
            'Purchase could not be started. Please try again, or tap Restore Purchase if you already bought Plus.';
        notifyListeners();
      } else {
        _startStoreRequestTimeout(
          const Duration(seconds: 20),
          'Purchase could not be started. Please try again, or tap Restore Purchase if you already bought Plus.',
        );
      }
    } catch (error) {
      _purchasePending = false;
      _storeRequestInProgress = false;
      _storeRequestType = null;
      _purchaseRequestStartedAt = null;
      _statusMessage =
          'Purchase could not be started. Please try again, or tap Restore Purchase if you already bought Plus.';
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    await initialize();

    _purchasePending = true;
    _storeRequestInProgress = true;
    _storeRequestType = _StoreRequestType.restore;
    _purchaseRequestStartedAt = DateTime.now();
    _statusMessage = 'Checking previous purchases...';
    notifyListeners();

    try {
      await _inAppPurchase.restorePurchases();
      _startStoreRequestTimeout(
        const Duration(seconds: 12),
        'No previous JusType Plus purchase was found for this Apple ID.',
      );
    } catch (error) {
      _purchasePending = false;
      _storeRequestInProgress = false;
      _storeRequestType = null;
      _purchaseRequestStartedAt = null;
      _statusMessage = 'Unable to check previous purchases. Please try again.';
      notifyListeners();
    }
  }

  Future<void> _loadProducts() async {
    final response = await _inAppPurchase.queryProductDetails({
      plusProductId,
    });

    if (response.error != null) {
      _statusMessage =
          'JusType Plus is temporarily unavailable. Please try again later.';
      return;
    }

    if (response.notFoundIDs.isNotEmpty) {
      _statusMessage =
          'JusType Plus is temporarily unavailable. Please try again later.';
    }

    if (response.productDetails.isNotEmpty) {
      _plusProduct = response.productDetails.first;
      _statusMessage = '';
    }
  }

  Future<void> _loadStoredEntitlement() async {
    final preferences = await SharedPreferences.getInstance();
    _isPlusUnlocked = preferences.getBool(_verifiedPlusEntitlementKey) ?? false;
  }

  Future<void> _unlockPlus() async {
    _isPlusUnlocked = true;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_verifiedPlusEntitlementKey, true);
  }

  void _startStoreRequestTimeout(Duration duration, String timeoutMessage) {
    _storeRequestTimeout?.cancel();
    _storeRequestTimeout = Timer(duration, () {
      if (_isPlusUnlocked || !_purchasePending) return;

      _purchasePending = false;
      _storeRequestInProgress = false;
      _storeRequestType = null;
      _purchaseRequestStartedAt = null;
      _statusMessage = timeoutMessage;
      notifyListeners();
    });
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.productID != plusProductId) {
        continue;
      }

      if (purchaseDetails.status == PurchaseStatus.pending) {
        if (_storeRequestInProgress) {
          _purchasePending = true;
        }
        continue;
      }

      _storeRequestTimeout?.cancel();

      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        if (_storeRequestInProgress) {
          await _unlockPlus();
          _statusMessage = 'JusType Plus is unlocked.';
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        if (_storeRequestInProgress) {
          _statusMessage = 'Purchase failed. Please try again.';
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        if (_storeRequestInProgress) {
          _statusMessage = 'Purchase canceled.';
        }
      }

      _purchasePending = false;
      _storeRequestInProgress = false;
      _storeRequestType = null;
      _purchaseRequestStartedAt = null;

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }

    notifyListeners();
  }

  @visibleForTesting
  Future<void> resetForTesting() async {
    _isPlusUnlocked = false;
    _purchasePending = false;
    _storeRequestInProgress = false;
    _storeRequestType = null;
    _purchaseRequestStartedAt = null;
    _statusMessage = '';
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_verifiedPlusEntitlementKey);
    notifyListeners();
  }

  @override
  void dispose() {
    _storeRequestTimeout?.cancel();
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}

enum _StoreRequestType {
  purchase,
  restore,
}
