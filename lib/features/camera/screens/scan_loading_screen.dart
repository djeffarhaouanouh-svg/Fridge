import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/claude_service.dart';
import '../../../core/services/neon_service.dart';
import '../../../core/services/openai_vision_service.dart';
import '../../../core/services/fridge_sync.dart';
import '../../../core/services/fridge_expiry.dart';
import '../../../core/theme/app_tokens.dart';
import '../../meals/providers/meals_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../meals/screens/results_screen.dart';

class ScanLoadingScreen extends ConsumerStatefulWidget {
  final List<Uint8List> photos;
  const ScanLoadingScreen({required this.photos, super.key});

  @override
  ConsumerState<ScanLoadingScreen> createState() => _ScanLoadingScreenState();
}

class _ScanLoadingScreenState extends ConsumerState<ScanLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _progressCtrl;
  late final AnimationController _pulseCtrl;
  String _message = 'Analyse de ta photo…';
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _runAnalysis();
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _progressCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Timer _after(int ms, VoidCallback fn) {
    final t = Timer(Duration(milliseconds: ms), fn);
    _timers.add(t);
    return t;
  }

  void _animateTo(double target, {int ms = 700}) {
    _progressCtrl.animateTo(
      target.clamp(0.0, 1.0),
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOut,
    );
  }

  void _msg(String text) {
    if (mounted) setState(() => _message = text);
  }

  Future<void> _runAnalysis() async {
    _animateTo(0.05);
    _after(900, () {
      _animateTo(0.13);
      _msg('Identification des aliments…');
    });
    _after(1800, () => _animateTo(0.19));

    try {
      final vision = OpenAiVisionService();
      final claude = ClaudeService();

      // ── Étape 1 : détection ingrédients ─────────────────────────────────
      final ingredients =
          await vision.detectIngredients(List.from(widget.photos));

      if (ingredients.isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final existing = ref.read(detectedIngredientsProvider);
      final latestDetected = <String>[];
      final latestSeen = <String>{};
      for (final item in ingredients) {
        final v = item.trim();
        if (v.isEmpty) continue;
        if (latestSeen.add(v.toLowerCase())) latestDetected.add(v);
      }
      final merged = <String>[];
      final seen = <String>{};
      for (final item in [...existing, ...latestDetected]) {
        final v = item.trim();
        if (v.isEmpty) continue;
        if (seen.add(v.toLowerCase())) merged.add(v);
      }

      ref.read(detectedIngredientsProvider.notifier).state = merged;
      ref.read(latestScanIngredientsProvider.notifier).state = latestDetected;
      await recordIngredientsAdded(latestDetected);
      await persistFridgeToNeon(merged);

      _animateTo(0.25, ms: 500);
      _msg('${latestDetected.length} ingrédients détectés ✓');
      await Future.delayed(const Duration(milliseconds: 650));

      // ── Étape 2 : génération recettes ────────────────────────────────────
      _msg('Recherche des meilleures associations…');
      _animateTo(0.40);

      _after(1300, () {
        _animateTo(0.57);
        _msg('Création de recettes personnalisées…');
      });
      _after(3200, () => _animateTo(0.74));
      _after(5500, () => _animateTo(0.87));

      final profile = ref.read(userProfileProvider);
      final meals = await claude.findRecipes(
        merged,
        profile: profile,
        neonService: NeonService(),
      );

      if (meals.isNotEmpty) {
        ref.read(latestScanMealsProvider.notifier).state = meals;
        await ref
            .read(mealsProvider.notifier)
            .mergeScanResultsAndPersist(meals);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_scan_date', DateTime.now().toIso8601String());

      // ── Étape 3 : terminé ────────────────────────────────────────────────
      _animateTo(1.0, ms: 400);
      _msg('${meals.length} recettes parfaites trouvées 🔥');
      await Future.delayed(const Duration(milliseconds: 900));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a1, a2) => const ResultsScreen(),
            transitionsBuilder: (_, a1, a2, child) => FadeTransition(
              opacity: a1,
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Mascotte pulsante
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, child) => Transform.scale(
                  scale: 0.94 + _pulseCtrl.value * 0.06,
                  child: child,
                ),
                child: Image.asset(
                  'assets/images/mascotte_normal.png',
                  width: 88,
                  height: 88,
                ),
              ),

              const SizedBox(height: 40),

              // Pourcentage
              AnimatedBuilder(
                animation: _progressCtrl,
                builder: (_, __) {
                  final pct = (_progressCtrl.value * 100).round();
                  return Text(
                    '$pct%',
                    style: GoogleFonts.fraunces(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Barre de progression
              AnimatedBuilder(
                animation: _progressCtrl,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 6,
                    color: Colors.white12,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressCtrl.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTokens.coral,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: AppTokens.coral.withOpacity(0.6),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Message IA
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: anim,
                      curve: Curves.easeOut,
                    )),
                    child: child,
                  ),
                ),
                child: Text(
                  _message,
                  key: ValueKey(_message),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
