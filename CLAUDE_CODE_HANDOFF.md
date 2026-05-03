# Handoff Claude Code — Refonte UI Fridge App

> Tu es un dev Flutter senior. Tu dois remplacer plusieurs écrans de l'app **Fridge** (Flutter + Riverpod) pour qu'ils correspondent à une nouvelle maquette UI.
>
> **Workflow :**
> - Travaille **un écran à la fois**, dans l'ordre où je te les donne en chat.
> - Avant chaque écran : lis bien la spec ci-dessous (tokens, composants partagés, conventions) une fois pour toutes.
> - Pour chaque écran : remplace **uniquement** le fichier indiqué. Ne touche pas aux providers Riverpod, models, services.
> - **Conserve** la logique existante (`mealsProvider`, `selectedTabProvider`, `Meal.toggleFavorite`, etc.). Tu ne fais que changer le **rendu visuel**.

---

## 1. Direction visuelle

L'app passe d'un **dark mode + accent vert** à un **light mode papier chaud + accent corail Marmiton + CTA vert iOS translucide**.

C'est **une refonte du thème complet**, pas un patch.

### Palette (remplace `lib/core/theme/app_tokens.dart`)

```dart
import 'package:flutter/material.dart';

class AppTokens {
  // Inks (text)
  static const Color ink = Color(0xFF1A1410);        // titres, body
  static const Color inkSoft = Color(0xFF4A3F38);    // body secondaire
  static const Color muted = Color(0xFF9A8D83);      // labels, métadonnées
  static const Color hairline = Color(0xFFE8DFD6);   // séparateurs principaux
  static const Color hairlineSoft = Color(0xFFF1EBE3); // séparateurs subtils

  // Surfaces (papier chaud, PAS blanc froid)
  static const Color paper = Color(0xFFFDFAF5);      // background principal
  static const Color surface = Color(0xFFF7F1E8);    // cards, sections
  static const Color surface2 = Color(0xFFF0E8DC);   // tags, avatar bg
  static const Color placeholder = Color(0xFFE0D4C2);
  static const Color placeholderDeep = Color(0xFFC9B9A3);

  // Coral Marmiton (accent unique de la marque)
  static const Color coral = Color(0xFFEE5C42);
  static const Color coralSoft = Color(0xFFFFE7DF);
  static const Color coralDeep = Color(0xFFD24228);

  // Apple iOS green (uniquement pour les glass pills CTA principaux)
  static const Color iosGreen = Color(0xFF34C759);

  // Spacing (inchangé)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Border radius (revus)
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 22.0;
  static const double radiusPill = 999.0;

  // Fonts (changement majeur)
  // Display (titres) : Fraunces — serif éditorial (cuisine, marmiton-vibe)
  // Body : Inter — sans-serif neutre
  static const String fontDisplay = 'Fraunces';
  static const String fontBody = 'Inter';

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> coralGlow = [
    BoxShadow(
      color: Color(0x73EE5C42),
      blurRadius: 22,
      offset: Offset(0, 8),
    ),
  ];
}
```

### `pubspec.yaml` — ajoute si absent

```yaml
dependencies:
  google_fonts: ^6.1.0  # déjà présent
```

Remplace les usages de `GoogleFonts.syne(...)` par `GoogleFonts.fraunces(...)` et `GoogleFonts.dmSans(...)` par `GoogleFonts.inter(...)`.

### `lib/main.dart` — `MaterialApp` à mettre à jour

```dart
theme: ThemeData(
  scaffoldBackgroundColor: AppTokens.paper,
  colorScheme: ColorScheme.light(
    primary: AppTokens.coral,
    surface: AppTokens.surface,
    background: AppTokens.paper,
  ),
  textTheme: GoogleFonts.interTextTheme(),
),
```

Et change `SystemChrome.setSystemUIOverlayStyle` :
```dart
SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,         // icônes status sombres
  systemNavigationBarColor: AppTokens.paper,
  systemNavigationBarIconBrightness: Brightness.dark,
)
```

---

## 2. Règle d'usage du corail (TRÈS important)

Le corail est un **signal**, pas une décoration. À utiliser **uniquement** pour :
- Logo / wordmark
- Bouton scan central de la nav (FAB)
- Tab actif (icône + label sous l'icône)
- Italique d'emphase dans un titre display (ex: « ce soir » dans « Qu'est-ce qu'on mange ce soir ? »)
- Indicateur N°01/02/03 sur les cartes recettes
- Heart bookmark sur cartes
- Stars (rating)
- Progress bar « ingrédients matchés »
- "Tout voir" / liens secondaires
- Tags catégorie
- Nombres clés (stats profil)
- Day pill actif (Plan)
- Avatar bordure

**NE PAS utiliser le corail pour les CTA principaux** — eux sont en glass pill **vert iOS translucide**.

---

## 3. Composant partagé : `GlassButton`

Crée `lib/core/widgets/glass_button.dart` :

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_tokens.dart';

enum GlassButtonColor { green, coral, light, dark }
enum GlassButtonSize { sm, md, lg }

/// Bouton « liquid glass » Apple-style :
/// - backdrop blur + saturate
/// - bordure 0.5px translucide
/// - highlight intérieur top-left
/// - tint coloré semi-opaque
class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final GlassButtonColor color;
  final GlassButtonSize size;
  final VoidCallback? onTap;
  final bool fullWidth;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.color = GlassButtonColor.green,
    this.size = GlassButtonSize.md,
    this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = _tint(color);
    final h = switch (size) {
      GlassButtonSize.sm => 36.0,
      GlassButtonSize.md => 44.0,
      GlassButtonSize.lg => 52.0,
    };
    final fs = switch (size) {
      GlassButtonSize.sm => 12.5,
      GlassButtonSize.md => 14.0,
      GlassButtonSize.lg => 15.0,
    };

    final inner = Stack(
      children: [
        // Blurred tinted background
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(h / 2),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(color: t.bg),
            ),
          ),
        ),
        // Border + inner shine
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(h / 2),
              border: Border.all(color: t.border, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: t.shine, blurRadius: 0, offset: const Offset(0.8, 0.8),
                  spreadRadius: -0.5,
                ),
              ],
            ),
          ),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fs + 2, color: t.text),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: fs, fontWeight: FontWeight.w600, color: t.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: h,
        width: fullWidth ? double.infinity : null,
        child: inner,
      ),
    );
  }

  _Tint _tint(GlassButtonColor c) => switch (c) {
        GlassButtonColor.green => const _Tint(
            bg: Color(0x3334C759),       // rgba(52,199,89,0.20)
            border: Color(0x8C34C759),   // 0.55
            text: Color(0xFF1A6B2E),
            shine: Color(0x80FFFFFF),
          ),
        GlassButtonColor.coral => const _Tint(
            bg: Color(0x2EEE5C42),       // 0.18
            border: Color(0x80EE5C42),   // 0.50
            text: AppTokens.coralDeep,
            shine: Color(0x8CFFFFFF),
          ),
        GlassButtonColor.light => _Tint(
            bg: Colors.white.withOpacity(0.7),
            border: Colors.black.withOpacity(0.08),
            text: AppTokens.ink,
            shine: Colors.white.withOpacity(0.85),
          ),
        GlassButtonColor.dark => _Tint(
            bg: const Color(0x99141414),
            border: Colors.white.withOpacity(0.18),
            text: Colors.white,
            shine: Colors.white.withOpacity(0.18),
          ),
      };
}

class _Tint {
  final Color bg, border, text, shine;
  const _Tint({required this.bg, required this.border, required this.text, required this.shine});
}
```

**Quand utiliser quelle variante :**
- `green` : CTA principaux (« Lancer la recette », « Générer plus », « Générer ma semaine »)
- `coral` : actions d'accent secondaires (« Modifier profil », « Filtres »)
- `light` : actions tertiaires sur fond image / hero
- `dark` : sur fond très clair quand tu veux du contraste fort (rare)

---

## 4. Bottom navigation — refonte

Remplace `lib/features/navigation/widgets/bottom_nav.dart`.

**Spec :**
- Hauteur : 82
- Background : `AppTokens.paper.withOpacity(0.95)`, border-top hairline 0.5
- 5 slots maintenant : `Recettes` / `Plan` / **Scanner (FAB central)** / `Favoris` / `Profil`
- **Scanner = bouton corail circulaire** 64×64 qui dépasse vers le haut de 34px, border 3px paper, shadow corail
- Tabs latérales : icône + label, **corail** si actif, `muted` sinon

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

class BottomNav extends ConsumerWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTabProvider);

    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: AppTokens.paper.withOpacity(0.95),
        border: Border(top: BorderSide(color: AppTokens.hairline, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            _NavItem(icon: Icons.restaurant_menu_outlined, label: 'Recettes', index: 0,
              active: selected == 0, onTap: () => ref.read(selectedTabProvider.notifier).state = 0),
            _NavItem(icon: Icons.calendar_month_outlined, label: 'Plan', index: 1,
              active: selected == 1, onTap: () => ref.read(selectedTabProvider.notifier).state = 1),
            _ScannerFab(onTap: () => ref.read(selectedTabProvider.notifier).state = 2),
            _NavItem(icon: Icons.favorite_border, label: 'Favoris', index: 3,
              active: selected == 3, onTap: () => ref.read(selectedTabProvider.notifier).state = 3),
            _NavItem(icon: Icons.person_outline, label: 'Profil', index: 4,
              active: selected == 4, onTap: () => ref.read(selectedTabProvider.notifier).state = 4),
          ],
        ),
      ),
    );
  }
}

class _ScannerFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ScannerFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -34),
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppTokens.coral,
                shape: BoxShape.circle,
                border: Border.all(color: AppTokens.paper, width: 3),
                boxShadow: [
                  BoxShadow(color: AppTokens.coral.withOpacity(0.45),
                    blurRadius: 22, offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final int index;
  final bool active; final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.index,
    required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = active ? AppTokens.coral : AppTokens.muted;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: c),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: c,
            )),
          ],
        ),
      ),
    );
  }
}
```

**Note** : `MainScreen` dans `main.dart` utilise un `IndexedStack` à 4 enfants. Il faudra l'élargir à 5 (CameraScreen passe à index 2 au milieu) — adapte simplement l'ordre.

---

## 5. Conventions partagées (toutes les pages)

- **Background scaffold** : `AppTokens.paper`
- **AppBar** : pas de Material AppBar — on utilise un header custom :
  - Padding 18 horizontal, 14 vertical
  - Bouton back (icône `Icons.arrow_back_ios_new`, taille 18, ink) à gauche, optionnel
  - Titre **centré**, font Fraunces 16, weight 600, ink
  - Icône action à droite, optionnelle
- **Cartes / sections** : background `surface`, radius `radiusMd` (16), pas de bordure visible (la couleur du fond suffit)
- **Séparateurs intra-section** : Container 1px hairlineSoft
- **Padding horizontal page** : 18
- **Espacement entre sections** : 22
- **Titres section** : Fraunces 18-19, weight 600
- **Body** : Inter 13.5-14, weight 500 (regular pour métadonnées)
- **Métadonnées** : Inter 11-12, weight 500, color muted
- **Eyebrow / kicker** (au-dessus d'un titre) : Inter 11, weight 700, letter-spacing 0.06em, uppercase, **coral**

### Header réutilisable

Crée `lib/core/widgets/app_header.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_tokens.dart';

class AppHeader extends StatelessWidget {
  final String? title;
  final Widget? leading;
  final Widget? trailing;
  final bool brand; // affiche le wordmark à la place du titre
  const AppHeader({super.key, this.title, this.leading, this.trailing, this.brand = false});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
        child: Row(
          children: [
            SizedBox(width: 32, child: leading),
            Expanded(
              child: Center(
                child: brand
                  ? const _BrandWordmark()
                  : (title == null ? const SizedBox() : Text(
                      title!,
                      style: GoogleFonts.fraunces(
                        fontSize: 16, fontWeight: FontWeight.w600, color: AppTokens.ink,
                      ),
                    )),
              ),
            ),
            SizedBox(width: 32, child: Align(alignment: Alignment.centerRight, child: trailing)),
          ],
        ),
      ),
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.kitchen_outlined, color: AppTokens.coral, size: 22),
        const SizedBox(width: 6),
        Text('fridge·ai', style: GoogleFonts.fraunces(
          fontSize: 22, fontWeight: FontWeight.w700, color: AppTokens.coral,
          letterSpacing: -0.5,
        )),
      ],
    );
  }
}
```

---

## 6. Ce que tu DOIS PRÉSERVER

- Tous les **providers Riverpod** (`mealsProvider`, `selectedTabProvider`, `scanStatusProvider`, `detectedIngredientsProvider`)
- Tous les **models** (`Meal`, `Ingredient`)
- Toute la **logique métier** : favorite toggle, navigation, locked premium, data binding
- Les **noms d'imports** et la structure des dossiers

Tu **ne touches pas** à :
- `lib/core/services/*`
- `lib/features/meals/models/*`
- `lib/features/meals/providers/*`
- `lib/features/meals/data/*`
- `lib/features/plan/models/*`

---

## 7. Workflow attendu

L'utilisateur va te dire en chat « Remplace l'écran Résultats » ou « Remplace le Profil ». Pour chaque écran :

1. Lis l'écran existant pour repérer les **données utilisées** (champs de `Meal`, providers, navigation).
2. Réécris **complètement** le widget en suivant les specs ci-dessus.
3. Garde les mêmes signatures (`extends ConsumerWidget`, mêmes paramètres au constructeur).
4. Vérifie le build (`flutter analyze`).
5. Liste à la fin les éventuelles dépendances neuves ou TODOs (ex: une nouvelle photo placeholder à fournir).

**N'invente pas de champs sur `Meal`** — si la maquette montre un champ qui n'existe pas (ex: `r.have / r.total`), demande à l'utilisateur s'il veut l'ajouter au model ou si tu dois le calculer/mocker.

---

## 8. Référence visuelle

La maquette HTML interactive complète est dans le projet OpenMyFridge. Si tu peux y accéder en local, ouvre `index.html`. Sinon les specs ci-dessus sont auto-suffisantes pour tous les écrans (Recettes home, Scanner, Résultats, Plan semaine, Profil, Détail recette).

L'utilisateur te donnera un screenshot écran-par-écran si nécessaire.
