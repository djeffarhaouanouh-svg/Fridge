import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../config/app_secrets.dart';
import 'neon_service.dart';

/// Identifiant d’entitlement RevenueCat (projet **Fridge** dans le dashboard RC).
const String kEntitlementPro = String.fromEnvironment(
  'FRIDGE_REVENUECAT_ENTITLEMENT',
  defaultValue: 'Fridge Pro',
);

// ignore: avoid_print
void _log(String msg) => print('[RC] $msg');

/// RevenueCat : achats et abonnements (logique alignée sur nailbite_coach_app).
class PurchaseService {
  static bool _initialized = false;

  static bool get isConfigured => _initialized;

  /// Réessaie l’init (ex. si [main] a échoué avant configure, ou hot restart sans defines).
  static Future<void> ensureConfigured() async {
    if (_initialized) return;
    await init(
      androidApiKey: AppSecrets.revenueCatAndroidApiKey,
      iosApiKey: AppSecrets.revenueCatIosApiKey,
    );
  }

  static CustomerInfo? _lastCustomerInfo;
  static final _customerInfoController =
      StreamController<CustomerInfo>.broadcast();

  static Stream<CustomerInfo> get customerInfoStream =>
      _customerInfoController.stream;

  static CustomerInfo? get lastCustomerInfo => _lastCustomerInfo;

  /// À appeler une fois au démarrage ([main]) avant [runApp]. Sans clé API, noop.
  static Future<void> init({
    String? androidApiKey,
    String? iosApiKey,
    String? appUserId,
  }) async {
    if (_initialized) return;

    final apiKey = Platform.isIOS
        ? (iosApiKey ?? '')
        : Platform.isAndroid
            ? (androidApiKey ?? '')
            : (androidApiKey ?? iosApiKey ?? '');
    if (apiKey.isEmpty) {
      _log(
        'INIT — skipped (empty API key for this platform). '
        'Android: REVENUECAT_ANDROID_KEY / iOS: REVENUECAT_IOS_KEY.',
      );
      return;
    }

    _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _log('INIT — start');
    _log(
      '  androidApiKey : ${(androidApiKey ?? "").isNotEmpty ? "set" : "empty"}',
    );
    _log(
      '  iosApiKey     : ${(iosApiKey ?? "").isNotEmpty ? "set" : "empty"}',
    );
    _log('  appUserId     : ${appUserId ?? "(none — anonymous)"}');

    await Purchases.setLogLevel(
      kDebugMode ? LogLevel.verbose : LogLevel.info,
    );

    final configuration = PurchasesConfiguration(apiKey)
      ..appUserID = appUserId;

    try {
      await Purchases.configure(configuration);
    } catch (e, st) {
      _log('INIT — ❌ Purchases.configure() FAILED: $e');
      _log(st.toString());
      return;
    }
    _initialized = true;
    _log('INIT — Purchases.configure() OK');

    Purchases.addCustomerInfoUpdateListener(_updateCustomerInfo);
    _log('INIT — customerInfoUpdateListener registered');

    try {
      _log('INIT — fetching initial CustomerInfo…');
      final info = await Purchases.getCustomerInfo();
      _updateCustomerInfo(info);
      _log('INIT — CustomerInfo fetched OK');
    } catch (e) {
      _log('INIT — ⚠️  initial CustomerInfo fetch FAILED: $e');
    }

    _log('INIT — done');
    _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Associe le profil RevenueCat à l’utilisateur Fridge (après [AuthService.autoRegister]).
  static Future<void> identifyCurrentUser() async {
    if (!_initialized || kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final uid = NeonService.kUserId;
    try {
      await Purchases.logIn(uid);
      _log('Purchases.logIn($uid) OK');
    } catch (e) {
      _log('Purchases.logIn failed: $e');
    }
  }

  static void _updateCustomerInfo(CustomerInfo info) {
    _lastCustomerInfo = info;
    final active = info.entitlements.active;
    final isPro = active.containsKey(kEntitlementPro);
    _log('customerInfo UPDATE — entitlements.active: ${active.keys.toList()}');
    _log('customerInfo UPDATE — isPremium ("$kEntitlementPro"): $isPro');
    if (!isPro) {
      _log('customerInfo UPDATE — ⚠️  entitlement NOT active');
    }
    if (!_customerInfoController.isClosed) {
      _customerInfoController.add(info);
    }
  }

  static Future<bool> isPro() async {
    _log('isPro() — checking…');
    try {
      final info = await getCustomerInfo();
      final result = info.entitlements.active.containsKey(kEntitlementPro);
      _log('isPro() — result: $result');
      return result;
    } catch (e) {
      _log('isPro() — ⚠️  error: $e → returning false');
      return false;
    }
  }

  static Future<CustomerInfo> getCustomerInfo() async {
    final info = await Purchases.getCustomerInfo();
    _updateCustomerInfo(info);
    return info;
  }

  static Future<Offerings?> getOfferings() async {
    _log('getOfferings() — fetching…');
    try {
      final offerings = await Purchases.getOfferings();
      _log('getOfferings() — offerings.all keys: ${offerings.all.keys.toList()}');
      if (offerings.current == null) {
        _log('getOfferings() — ⚠️  offerings.current is NULL');
      } else {
        _log('getOfferings() — current offering: "${offerings.current!.identifier}"');
      }
      return offerings;
    } catch (e) {
      _log('getOfferings() — ❌ ERROR: $e');
      return null;
    }
  }

  static Future<CustomerInfo> purchase(Package package) async {
    _log('━━━━ purchase started ━━━━');
    final rawInfo = await Purchases.purchasePackage(package);
    _log('purchase success — raw entitlements.active: ${rawInfo.entitlements.active.keys.toList()}');

    CustomerInfo info;
    try {
      info = await Purchases.getCustomerInfo();
      _log('customer info refreshed — entitlements.active: ${info.entitlements.active.keys.toList()}');
    } catch (e) {
      _log('⚠️  forced refresh failed ($e) — using raw purchasePackage result');
      info = rawInfo;
    }

    _updateCustomerInfo(info);
    _syncSubscriptionToNeon(info, productId: package.storeProduct.identifier);
    return info;
  }

  static Future<CustomerInfo> restorePurchases() async {
    _log('restorePurchases() — calling Purchases.restorePurchases()…');
    final info = await Purchases.restorePurchases();
    final isPro = info.entitlements.active.containsKey(kEntitlementPro);
    _log('restorePurchases() — done. entitlement active: $isPro');
    _updateCustomerInfo(info);
    _syncSubscriptionToNeon(info, status: 'restored');
    return info;
  }

  static void _syncSubscriptionToNeon(
    CustomerInfo info, {
    String? productId,
    String? status,
  }) {
    final isPro = info.entitlements.active.containsKey(kEntitlementPro);
    final rcUserId = info.originalAppUserId;
    final fridgeUserId = NeonService.kUserId;

    String resolvedProductId = productId ?? 'unknown';
    DateTime? expiresAt;

    if (info.entitlements.active.containsKey(kEntitlementPro)) {
      final entitlement = info.entitlements.active[kEntitlementPro]!;
      resolvedProductId = productId ?? entitlement.productIdentifier;
      final expStr = entitlement.expirationDate;
      if (expStr != null) expiresAt = DateTime.tryParse(expStr);
    }

    NeonService().logSubscriptionPurchase(
      userId: fridgeUserId,
      revenueCatUserId: rcUserId,
      productId: resolvedProductId,
      status: status ?? (isPro ? 'active' : 'expired'),
      isPro: isPro,
      purchasedAt: DateTime.now(),
      expiresAt: expiresAt,
    );
  }

  static Future<PaywallResult> presentPaywallIfNeeded() async {
    return RevenueCatUI.presentPaywallIfNeeded(
      kEntitlementPro,
      displayCloseButton: true,
    );
  }

  static Future<PaywallResult> presentPaywall({
    Offering? offering,
    bool displayCloseButton = true,
  }) async {
    return RevenueCatUI.presentPaywall(
      offering: offering,
      displayCloseButton: displayCloseButton,
    );
  }

  static Future<void> presentCustomerCenter() async {
    await RevenueCatUI.presentCustomerCenter();
    try {
      await getCustomerInfo();
    } catch (_) {}
  }

  @visibleForTesting
  static void disposeStream() {
    _customerInfoController.close();
  }
}
