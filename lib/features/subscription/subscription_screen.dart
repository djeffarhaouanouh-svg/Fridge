import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/purchase_service.dart';
import '../../core/theme/app_tokens.dart';

// ignore: avoid_print
void _log(String msg) => print('[RC:Paywall] $msg');

/// Liens légaux (à remplacer par tes URLs réelles si besoin).
const _kTermsUrl = 'https://www.example.com/terms';
const _kPrivacyUrl = 'https://www.example.com/privacy';

/// Mascotte au-dessus des offres (même emplacement / taille que l'ancien paywall NailBite).
const _kPaywallMascotAsset = 'assets/images/mascotte-paywall.png';
const double _kPaywallMascotSize = 310;

enum _Plan { lifetime, monthly, weekly }

Package? _findPackage(Offerings offerings, _Plan plan) {
  final seen = <String>{};
  final all = <Package>[];

  final current = offerings.current;
  if (current != null) {
    for (final p in current.availablePackages) {
      if (seen.add(p.storeProduct.identifier)) all.add(p);
    }
  }
  for (final offering in offerings.all.values) {
    for (final p in offering.availablePackages) {
      if (seen.add(p.storeProduct.identifier)) all.add(p);
    }
  }

  if (all.isEmpty) {
    _log('_findPackage — no packages found');
    return null;
  }

  final rcId = switch (plan) {
    _Plan.monthly => r'$rc_monthly',
    _Plan.weekly => r'$rc_weekly',
    _Plan.lifetime => r'$rc_lifetime',
  };

  final keywords = switch (plan) {
    _Plan.monthly => ['monthly', 'month'],
    _Plan.weekly => ['weekly', 'week'],
    _Plan.lifetime => ['lifetime', 'life'],
  };

  for (final p in all) {
    if (p.identifier == rcId) return p;
  }

  for (final p in all) {
    final pid = p.identifier.toLowerCase();
    for (final kw in keywords) {
      if (pid.contains(kw)) return p;
    }
  }

  for (final p in all) {
    final spid = p.storeProduct.identifier.toLowerCase();
    for (final kw in keywords) {
      if (spid.contains(kw)) return p;
    }
  }

  return null;
}

/// Paywall custom RevenueCat (porté depuis nailbite_coach_app).
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({
    super.key,
    required this.onAccessGranted,
    this.onSkip,
  });

  /// Appelé lorsque l'entitlement Pro est actif (achat ou restauration).
  final VoidCallback onAccessGranted;

  /// Appelé quand l'utilisateur appuie sur "Passer". Si null, fait un simple pop.
  final VoidCallback? onSkip;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with WidgetsBindingObserver {
  _Plan _selected = _Plan.monthly;
  Offerings? _offerings;
  bool _isPurchasing = false;
  bool _loadingOfferings = true;
  /// False si aucune clé / configure RC a échoué — l'écran s'affiche quand même avec un message.
  bool _revenueCatReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPremiumThenLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isPurchasing) {
      _refreshAndCheckPremium();
    }
  }

  Future<void> _refreshAndCheckPremium() async {
    if (!PurchaseService.isConfigured) return;
    try {
      final info = await PurchaseService.getCustomerInfo();
      final isPro = info.entitlements.active.containsKey(kEntitlementPro);
      if (!mounted) return;
      if (isPro) {
        setState(() => _isPurchasing = false);
        widget.onAccessGranted();
      }
    } catch (e) {
      _log('refreshAndCheckPremium error: $e');
    }
  }

  Future<void> _checkPremiumThenLoad() async {
    await PurchaseService.ensureConfigured();
    if (!mounted) return;

    if (!PurchaseService.isConfigured) {
      setState(() {
        _revenueCatReady = false;
        _loadingOfferings = false;
        _offerings = null;
      });
      return;
    }

    setState(() => _revenueCatReady = true);

    final alreadyPro = await PurchaseService.isPro();
    if (!mounted) return;
    if (alreadyPro) {
      widget.onAccessGranted();
      return;
    }
    final offerings = await PurchaseService.getOfferings();
    if (!mounted) return;
    setState(() {
      _offerings = offerings;
      _loadingOfferings = false;
    });
  }

  Package? _packageFor(_Plan plan) {
    if (_offerings == null) return null;
    return _findPackage(_offerings!, plan);
  }

  String _priceFor(_Plan plan) {
    final pkg = _packageFor(plan);
    if (pkg != null) return pkg.storeProduct.priceString;
    return switch (plan) {
      _Plan.lifetime => '29,97 €',
      _Plan.monthly => '7,97 €',
      _Plan.weekly => '4,97 €',
    };
  }

  Future<void> _purchase() async {
    if (!PurchaseService.isConfigured) {
      _showError(
        'RevenueCat n\'est pas prêt. Lance l\'app avec run.bat ou '
        '« Fridge App » dans VS Code (secrets.json avec les clés).',
      );
      return;
    }
    final pkg = _packageFor(_selected);
    if (pkg == null) {
      _showError(
        'Offres non disponibles. Vérifiez votre connexion et réessayez.',
      );
      return;
    }

    setState(() => _isPurchasing = true);
    try {
      final info = await PurchaseService.purchase(pkg);
      final isPro = info.entitlements.active.containsKey(kEntitlementPro);

      if (isPro) {
        if (mounted) {
          setState(() => _isPurchasing = false);
          widget.onAccessGranted();
        }
      } else {
        final restored = await PurchaseService.restorePurchases();
        final ok =
            restored.entitlements.active.containsKey(kEntitlementPro);
        if (!mounted) return;
        if (ok) {
          setState(() => _isPurchasing = false);
          widget.onAccessGranted();
        } else {
          setState(() => _isPurchasing = false);
          _showError(
            'Achat enregistré mais accès non encore activé. '
            'Patientez quelques secondes ou utilisez « Restaurer les achats ».',
          );
        }
      }
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        if (mounted) _showError("L'achat a échoué. Veuillez réessayer.");
      }
      if (mounted) setState(() => _isPurchasing = false);
    } catch (e) {
      _log('unexpected error: $e');
      if (mounted) {
        setState(() => _isPurchasing = false);
        _showError("L'achat a échoué. Veuillez réessayer.");
      }
    }
  }

  Future<void> _restorePurchases() async {
    if (!PurchaseService.isConfigured) {
      _showError('RevenueCat n\'est pas initialisé.');
      return;
    }
    setState(() => _isPurchasing = true);
    try {
      final info = await PurchaseService.restorePurchases();
      if (!mounted) return;
      if (info.entitlements.active.containsKey(kEntitlementPro)) {
        widget.onAccessGranted();
      } else {
        _showError('Aucun achat à restaurer.');
      }
    } catch (e) {
      _log('restorePurchases error: $e');
      if (mounted) _showError('La restauration a échoué.');
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isPurchasing || _loadingOfferings;
    final selectedPackage = _packageFor(_selected);
    final canPurchase = _revenueCatReady && !busy && selectedPackage != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    const SizedBox(width: 60),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.kitchen_outlined, size: 15, color: AppTokens.coral),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Recettes et suivi pensés pour ton frigo',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTokens.inkSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            if (widget.onSkip != null) {
                              widget.onSkip!();
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(
                            'Passer',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTokens.coral,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Fridge Pro',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fraunces(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppTokens.ink,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Choisis ton offre pour débloquer tout le potentiel de l'app",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTokens.inkSoft,
                          height: 1.4,
                        ),
                      ),
                      if (!_loadingOfferings && !_revenueCatReady)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 12),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber.shade700.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "RevenueCat ne s'est pas lancé",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTokens.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '• Lance avec run.bat ou VS Code « Fridge App » (secrets.json à la racine du projet).\n'
                                    '• Après modification de secrets.json : arrête l\'app puis Run — le hot reload ne recharge pas les clés.\n'
                                    '• Émulateur Android ou simulateur iOS uniquement (pas Chrome, pas Windows desktop).\n'
                                    '• Onboarding déjà fait ? Tu ne repasses plus ici : désinstalle l\'app ou efface ses données pour retester.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: AppTokens.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 56),
                      Center(
                        child: Image.asset(
                          _kPaywallMascotAsset,
                          width: _kPaywallMascotSize,
                          height: _kPaywallMascotSize,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                      if (_loadingOfferings)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(
                            backgroundColor: AppTokens.hairline,
                            color: AppTokens.coral,
                          ),
                        ),
                      _PlanCard(
                        selected: _selected == _Plan.lifetime,
                        available: _packageFor(_Plan.lifetime) != null,
                        title: 'À vie',
                        subtitle: 'Accès à vie à Fridge Pro',
                        price: _priceFor(_Plan.lifetime),
                        onTap: () => setState(() => _selected = _Plan.lifetime),
                      ),
                      const SizedBox(height: 10),
                      _PlanCard(
                        selected: _selected == _Plan.monthly,
                        available: _packageFor(_Plan.monthly) != null,
                        title: 'Mensuel',
                        subtitle: 'Abonnement mensuel',
                        price: _priceFor(_Plan.monthly),
                        badge: 'Populaire',
                        onTap: () => setState(() => _selected = _Plan.monthly),
                      ),
                      const SizedBox(height: 10),
                      _PlanCard(
                        selected: _selected == _Plan.weekly,
                        available: _packageFor(_Plan.weekly) != null,
                        title: 'Semaine',
                        subtitle: 'Abonnement hebdomadaire',
                        price: _priceFor(_Plan.weekly),
                        onTap: () => setState(() => _selected = _Plan.weekly),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: canPurchase ? _purchase : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.coral,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTokens.coral.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      ),
                    ),
                    child: _isPurchasing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            canPurchase ? 'Commencer' : 'Chargement…',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FooterLink(
                      label: 'Restaurer les achats',
                      onTap: busy ? () {} : _restorePurchases,
                    ),
                    const SizedBox(width: 12),
                    _FooterLink(label: 'Conditions', onTap: () => _openUrl(_kTermsUrl)),
                    const SizedBox(width: 12),
                    _FooterLink(label: 'Confidentialité', onTap: () => _openUrl(_kPrivacyUrl)),
                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final bool selected;
  final bool available;
  final String title;
  final String subtitle;
  final String price;
  final String? badge;
  final VoidCallback onTap;

  const _PlanCard({
    required this.selected,
    required this.available,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: available ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTokens.coral : AppTokens.hairline,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTokens.coral.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppTokens.coral : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? AppTokens.coral
                          : AppTokens.inkSoft.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: available ? AppTokens.ink : AppTokens.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTokens.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppTokens.coral : AppTokens.ink,
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -13,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTokens.coral, AppTokens.coral.withValues(alpha: 0.75)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: AppTokens.muted,
          decoration: TextDecoration.underline,
          decorationColor: AppTokens.muted,
        ),
      ),
    );
  }
}
