import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart' show InAppPurchase;
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:justype/services/purchase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeInAppPurchasePlatform fakeStore;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    SharedPreferences.setMockInitialValues({});
    fakeStore = _FakeInAppPurchasePlatform();
    InAppPurchasePlatform.instance = fakeStore;
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await fakeStore.dispose();
  });

  test('does not unlock Plus from stale local purchase data', () async {
    SharedPreferences.setMockInitialValues({
      'plus_unlocked': true,
      'plus_entitlement_transaction': 'old-debug-transaction',
    });
    final service = PurchaseService(inAppPurchase: InAppPurchase.instance);

    await service.initialize();

    expect(service.isPlusUnlocked, isFalse);
    expect(fakeStore.queryCount, 1);

    service.dispose();
  });

  test('does not unlock Plus from automatic StoreKit redelivery', () async {
    final service = PurchaseService(inAppPurchase: InAppPurchase.instance);

    await service.initialize();
    fakeStore.emitPurchases([
      _purchaseDetails(status: PurchaseStatus.purchased),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(service.purchasePending, isFalse);
    expect(service.isPlusUnlocked, isFalse);
    expect(fakeStore.completeCount, 1);

    service.dispose();
  });

  test('immediate owned purchase response does not unlock Plus', () async {
    final service = PurchaseService(inAppPurchase: InAppPurchase.instance);

    await service.initialize();
    await service.buyPlus();

    expect(fakeStore.buyCount, 1);
    expect(service.purchasePending, isTrue);
    expect(service.isPlusUnlocked, isFalse);
    expect(service.statusMessage, 'Connecting to App Store...');

    fakeStore.emitPurchases([
      _purchaseDetails(status: PurchaseStatus.purchased),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(service.purchasePending, isFalse);
    expect(service.isPlusUnlocked, isFalse);
    expect(service.statusMessage, contains('already owns'));
    expect(fakeStore.completeCount, 1);

    service.dispose();
  });

  test('StoreKit purchase unlocks Plus after the payment flow starts',
      () async {
    final service = PurchaseService(
      inAppPurchase: InAppPurchase.instance,
      minimumPurchaseSheetDelay: Duration.zero,
    );

    await service.initialize();
    await service.buyPlus();

    expect(fakeStore.buyCount, 1);
    expect(service.purchasePending, isTrue);
    expect(service.isPlusUnlocked, isFalse);

    fakeStore.emitPurchases([
      _purchaseDetails(status: PurchaseStatus.purchased),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(service.purchasePending, isFalse);
    expect(service.isPlusUnlocked, isTrue);
    expect(service.statusMessage, 'JusType Plus is unlocked.');

    service.dispose();
  });

  test('StoreKit-confirmed Plus entitlement persists across launches',
      () async {
    final service = PurchaseService(
      inAppPurchase: InAppPurchase.instance,
      minimumPurchaseSheetDelay: Duration.zero,
    );

    await service.initialize();
    await service.buyPlus();
    fakeStore.emitPurchases([
      _purchaseDetails(status: PurchaseStatus.purchased),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(service.isPlusUnlocked, isTrue);
    service.dispose();

    final nextLaunch = PurchaseService(inAppPurchase: InAppPurchase.instance);
    await nextLaunch.initialize();

    expect(nextLaunch.isPlusUnlocked, isTrue);

    nextLaunch.dispose();
  });

  test('restore unlocks Plus only after user taps restore', () async {
    final service = PurchaseService(inAppPurchase: InAppPurchase.instance);

    await service.initialize();
    await service.restorePurchases();

    expect(service.purchasePending, isTrue);
    expect(service.isPlusUnlocked, isFalse);

    fakeStore.emitPurchases([
      _purchaseDetails(
        status: PurchaseStatus.restored,
        purchaseID: 'storekit-transaction-id',
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(service.purchasePending, isFalse);
    expect(service.isPlusUnlocked, isTrue);
    expect(service.statusMessage, 'JusType Plus is unlocked.');

    service.dispose();
  });

  test('shows an error if the App Store purchase sheet cannot start', () async {
    fakeStore.buyResult = false;
    final service = PurchaseService(inAppPurchase: InAppPurchase.instance);

    await service.initialize();
    await service.buyPlus();

    expect(service.purchasePending, isFalse);
    expect(service.isPlusUnlocked, isFalse);
    expect(
      service.statusMessage,
      contains('Purchase could not be started'),
    );

    service.dispose();
  });
}

ProductDetails _plusProduct() {
  return ProductDetails(
    id: PurchaseService.plusProductId,
    title: 'JusType Plus Lifetime',
    description: 'Unlock JusType Plus.',
    price: r'$3.99',
    rawPrice: 3.99,
    currencyCode: 'USD',
    currencySymbol: r'$',
  );
}

PurchaseDetails _purchaseDetails({
  required PurchaseStatus status,
  String? purchaseID,
}) {
  return PurchaseDetails(
    purchaseID: purchaseID,
    productID: PurchaseService.plusProductId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'test',
    ),
    transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
    status: status,
  )..pendingCompletePurchase = true;
}

class _FakeInAppPurchasePlatform extends Fake
    with MockPlatformInterfaceMixin
    implements InAppPurchasePlatform {
  final StreamController<List<PurchaseDetails>> _purchaseController =
      StreamController<List<PurchaseDetails>>.broadcast();

  bool isStoreAvailable = true;
  bool buyResult = true;
  int buyCount = 0;
  int completeCount = 0;
  int queryCount = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _purchaseController.stream;

  @override
  Future<bool> isAvailable() async => isStoreAvailable;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    queryCount += 1;
    final products = identifiers.contains(PurchaseService.plusProductId)
        ? [_plusProduct()]
        : <ProductDetails>[];
    return ProductDetailsResponse(
      productDetails: products,
      notFoundIDs:
          identifiers.difference({PurchaseService.plusProductId}).toList(),
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buyCount += 1;
    return buyResult;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completeCount += 1;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}

  @override
  Future<String> countryCode() async => 'USA';

  void emitPurchases(List<PurchaseDetails> purchases) {
    _purchaseController.add(purchases);
  }

  Future<void> dispose() async {
    await _purchaseController.close();
  }
}
