import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/services/purchase_service.dart';

class _PremiumNotifier extends StateNotifier<AsyncValue<bool>> {
  _PremiumNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  StreamSubscription<CustomerInfo>? _sub;

  void _init() {
    if (kIsWeb ||
        !PurchaseService.isConfigured ||
        (!Platform.isAndroid && !Platform.isIOS)) {
      state = const AsyncValue.data(false);
      return;
    }

    final cached = PurchaseService.lastCustomerInfo;
    if (cached != null) {
      state = AsyncValue.data(
        cached.entitlements.active.containsKey(kEntitlementPro),
      );
    }

    _sub = PurchaseService.customerInfoStream.listen(
      (info) => state = AsyncValue.data(
        info.entitlements.active.containsKey(kEntitlementPro),
      ),
      onError: (Object e, StackTrace st) => state = AsyncValue.error(e, st),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// État réactif « utilisateur premium » (RevenueCat).
final isPremiumProvider =
    StateNotifierProvider<_PremiumNotifier, AsyncValue<bool>>(
  (_) => _PremiumNotifier(),
);
