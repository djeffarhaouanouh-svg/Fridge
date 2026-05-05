import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/meal_image.dart';
import '../../../core/widgets/app_header.dart';
import '../../meals/providers/meals_provider.dart';
import '../../meals/models/meal.dart';
import '../../meals/screens/recipe_screen.dart';
import '../../navigation/widgets/bottom_nav.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);
    final favoriteMeals = ref.watch(favoriteMealsProvider);
    final allMeals = ref.watch(mealsProvider);
    final detectedIngredients = ref.watch(detectedIngredientsProvider);
    final selections = ref.watch(planMealSelectionsProvider);
    final recentlyViewed = ref.watch(recentlyViewedProvider);

    final cookedCount = selections.length;
    final streak = 3; // mock

    return Scaffold(
      backgroundColor: AppTokens.paper,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
          children: [
            const AppHeader(brand: true),

            // ── 1. Identité ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 68, height: 68,
                            decoration: BoxDecoration(
                              color: AppTokens.coralSoft,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTokens.coral, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                                style: GoogleFonts.fraunces(
                                  fontSize: 26, fontWeight: FontWeight.w700, color: AppTokens.coral,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: AppTokens.coral, shape: BoxShape.circle,
                                border: Border.all(color: AppTokens.paper, width: 1.5),
                              ),
                              child: const Icon(Icons.camera_alt, size: 11, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.name,
                              style: GoogleFonts.fraunces(
                                fontSize: 18, fontWeight: FontWeight.w700, color: AppTokens.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(profile.email,
                              style: GoogleFonts.inter(fontSize: 13, color: AppTokens.muted),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _showEditNameDialog(context, profile.name, notifier),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTokens.coral, width: 1),
                                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.edit_outlined, size: 12, color: AppTokens.coral),
                                    const SizedBox(width: 5),
                                    Text('Modifier',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTokens.coral,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Objectif
                  _Label(text: 'Objectif'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _ObjectivePill(
                        emoji: '🔥', label: 'Perte de poids',
                        active: profile.objective == CookingObjective.weightLoss,
                        onTap: () => notifier.setObjective(CookingObjective.weightLoss),
                      ),
                      _ObjectivePill(
                        emoji: '💪', label: 'Prise de masse',
                        active: profile.objective == CookingObjective.muscleGain,
                        onTap: () => notifier.setObjective(CookingObjective.muscleGain),
                      ),
                      _ObjectivePill(
                        emoji: '👨‍👩‍👧', label: 'Famille',
                        active: profile.objective == CookingObjective.family,
                        onTap: () => notifier.setObjective(CookingObjective.family),
                      ),
                      _ObjectivePill(
                        emoji: '🍳', label: 'Passion cuisine',
                        active: profile.objective == CookingObjective.passion,
                        onTap: () => notifier.setObjective(CookingObjective.passion),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Niveau
                  _Label(text: 'Niveau cuisine'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _LevelPill(label: 'Débutant', active: profile.cookingLevel == CookingLevel.beginner,
                        onTap: () => notifier.setCookingLevel(CookingLevel.beginner)),
                      const SizedBox(width: 6),
                      _LevelPill(label: 'Inter.', active: profile.cookingLevel == CookingLevel.intermediate,
                        onTap: () => notifier.setCookingLevel(CookingLevel.intermediate)),
                      const SizedBox(width: 6),
                      _LevelPill(label: 'Avancé', active: profile.cookingLevel == CookingLevel.advanced,
                        onTap: () => notifier.setCookingLevel(CookingLevel.advanced)),
                      const SizedBox(width: 6),
                      _LevelPill(label: 'Expert', active: profile.cookingLevel == CookingLevel.expert,
                        onTap: () => notifier.setCookingLevel(CookingLevel.expert)),
                    ],
                  ),
                ],
              ),
            ),

            _Divider(),

            // ── 4. Stats & streak ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  _Stat(value: '$cookedCount', label: 'Plats cuisinés', icon: Icons.restaurant_outlined),
                  _Stat(value: '${favoriteMeals.length}', label: 'Favoris', icon: Icons.favorite_border),
                  _Stat(value: '$streak', label: 'Jours actifs', icon: Icons.local_fire_department_outlined),
                ],
              ),
            ),

            _Divider(),

            // ── 9. Profil nutrition ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Profil nutrition'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _MacroCard(value: '${profile.targetCalories}', unit: 'kcal', label: 'Calories', color: AppTokens.coral),
                      const SizedBox(width: 10),
                      _MacroCard(value: '${profile.targetProtein}g', unit: '', label: 'Protéines', color: const Color(0xFF4CAF50)),
                      const SizedBox(width: 10),
                      _MacroCard(value: '${profile.targetCarbs}g', unit: '', label: 'Glucides', color: const Color(0xFF2196F3)),
                      const SizedBox(width: 10),
                      _MacroCard(value: '${profile.targetFats}g', unit: '', label: 'Lipides', color: const Color(0xFFFF9800)),
                    ],
                  ),
                ],
              ),
            ),

            _Divider(),

            // ── 2. Préférences alimentaires ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Préférences alimentaires'),
                  const SizedBox(height: 14),
                  _Label(text: 'Allergies'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['Gluten', 'Lactose', 'Noix', 'Œufs', 'Fruits de mer', 'Soja'].map((a) =>
                      _ToggleChip(
                        label: a,
                        active: profile.allergies.contains(a),
                        onTap: () => notifier.toggleAllergy(a),
                        activeColor: const Color(0xFFFF5252),
                      ),
                    ).toList(),
                  ),
                  const SizedBox(height: 16),
                  _Label(text: 'Régime'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['Végétarien', 'Végétalien', 'Halal', 'Keto', 'Sans gluten', 'Sans lactose'].map((d) =>
                      _ToggleChip(
                        label: d,
                        active: profile.diets.contains(d),
                        onTap: () => notifier.toggleDiet(d),
                        activeColor: AppTokens.coral,
                      ),
                    ).toList(),
                  ),
                ],
              ),
            ),

            _Divider(),

            // ── 3. Mon frigo ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Mon frigo actuel'),
                  const SizedBox(height: 14),
                  if (detectedIngredients.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppTokens.surface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.kitchen_outlined, color: AppTokens.muted, size: 32),
                          const SizedBox(height: 8),
                          Text('Ton frigo est vide',
                            style: GoogleFonts.inter(fontSize: 13.5, color: AppTokens.muted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: detectedIngredients.map((ing) =>
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTokens.surface,
                            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                            border: Border.all(color: AppTokens.hairline),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.eco_outlined, size: 13, color: AppTokens.coral),
                              const SizedBox(width: 5),
                              Text(ing,
                                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppTokens.ink),
                              ),
                            ],
                          ),
                        ),
                      ).toList(),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: AppTokens.coralSoft,
                              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt_outlined, size: 16, color: AppTokens.coral),
                                const SizedBox(width: 7),
                                Text('Scanner',
                                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTokens.coral),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: AppTokens.surface,
                              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                              border: Border.all(color: AppTokens.hairline),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add, size: 16, color: AppTokens.inkSoft),
                                const SizedBox(width: 7),
                                Text('Ajouter',
                                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTokens.inkSoft),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            _Divider(),

            // ── 4. Favoris ───────────────────────────────────────────
            if (favoriteMeals.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: _SectionTitle(title: 'Mes favoris'),
              ),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                  itemCount: favoriteMeals.length,
                  itemBuilder: (_, i) => _MealCard(meal: favoriteMeals[i]),
                ),
              ),
              _Divider(),
            ],

            // ── 4b. Dernières recettes vues ──────────────────────────
            if (recentlyViewed.isNotEmpty || allMeals.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: _SectionTitle(title: 'Dernières recettes'),
              ),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                  itemCount: (recentlyViewed.isNotEmpty ? recentlyViewed : allMeals).length,
                  itemBuilder: (_, i) {
                    final meals = recentlyViewed.isNotEmpty ? recentlyViewed : allMeals;
                    return _MealCard(meal: meals[i]);
                  },
                ),
              ),
              _Divider(),
            ],

            // ── 6. Notifications ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Notifications'),
                  const SizedBox(height: 4),
                  _SwitchRow(
                    label: 'Produits qui expirent',
                    subtitle: 'Rappel avant péremption',
                    value: profile.notifExpiry,
                    onChanged: (v) => notifier.setNotif(expiry: v),
                  ),
                  _SwitchRow(
                    label: 'Recette du jour',
                    subtitle: 'Suggestion personnalisée',
                    value: profile.notifSuggestion,
                    onChanged: (v) => notifier.setNotif(suggestion: v),
                  ),
                  _SwitchRow(
                    label: 'Ce que tu peux cuisiner',
                    subtitle: 'Basé sur ton frigo actuel',
                    value: profile.notifFridge,
                    onChanged: (v) => notifier.setNotif(fridge: v),
                    isLast: true,
                  ),
                ],
              ),
            ),

            _Divider(),

            // ── 7. Abonnement ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEE5C42), Color(0xFFD24228)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.workspace_premium, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text('Premium',
                                style: GoogleFonts.fraunces(
                                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Recettes avancées · Plan nutrition · IA poussée',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      ),
                      child: Text('Essayer',
                        style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppTokens.coral,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _Divider(),

            // ── 8. Paramètres ────────────────────────────────────────
            _SettingRow(label: 'Langue', value: 'Français', icon: Icons.language_outlined),
            _SettingRow(label: 'Mon compte', value: profile.email, icon: Icons.person_outline),
            _SettingRow(label: 'Aide & support', icon: Icons.help_outline),
            _SettingRow(
              label: 'Se déconnecter',
              icon: Icons.logout_outlined,
              onTap: () async => FirebaseAuth.instance.signOut(),
            ),
            _SettingRow(
              label: 'Supprimer le compte',
              icon: Icons.delete_outline,
              danger: true,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

void _showEditNameDialog(
    BuildContext context, String current, UserProfileNotifier notifier) {
  final ctrl = TextEditingController(text: current);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTokens.paper,
      title: Text('Modifier le prénom',
          style: GoogleFonts.fraunces(
              fontWeight: FontWeight.w600, color: AppTokens.ink)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: GoogleFonts.inter(fontSize: 14.5, color: AppTokens.ink),
        decoration: InputDecoration(
          hintText: 'Ton prénom',
          hintStyle: GoogleFonts.inter(color: AppTokens.muted),
          filled: true,
          fillColor: AppTokens.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            borderSide: const BorderSide(color: AppTokens.hairline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            borderSide: const BorderSide(color: AppTokens.hairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            borderSide: const BorderSide(color: AppTokens.coral, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Annuler',
              style: GoogleFonts.inter(color: AppTokens.muted)),
        ),
        TextButton(
          onPressed: () async {
            final name = ctrl.text.trim();
            if (name.isNotEmpty) {
              await FirebaseAuth.instance.currentUser
                  ?.updateDisplayName(name);
              notifier.updateName(name);
            }
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: Text('Sauvegarder',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, color: AppTokens.coral)),
        ),
      ],
    ),
  );
}

// ─── Widgets helpers ────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Divider(height: 1, thickness: 1, color: AppTokens.hairline),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
    style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w600, color: AppTokens.ink),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});
  @override
  Widget build(BuildContext context) => Text(text,
    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
      color: AppTokens.muted, letterSpacing: 0.5),
  );
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _Stat({required this.value, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: GoogleFonts.fraunces(
          fontSize: 28, fontWeight: FontWeight.w700, color: AppTokens.coral)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(
          fontSize: 11.5, color: AppTokens.muted, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

class _MacroCard extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Color color;
  const _MacroCard({required this.value, required this.unit, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border(bottom: BorderSide(color: color, width: 2.5)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.fraunces(
            fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.inter(
            fontSize: 10, color: AppTokens.muted, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _ObjectivePill extends StatelessWidget {
  final String emoji, label;
  final bool active;
  final VoidCallback onTap;
  const _ObjectivePill({required this.emoji, required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppTokens.coralSoft : AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: active ? AppTokens.coral : AppTokens.hairline, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(
            fontSize: 12.5, fontWeight: FontWeight.w600,
            color: active ? AppTokens.coral : AppTokens.inkSoft)),
        ],
      ),
    ),
  );
}

class _LevelPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LevelPill({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppTokens.coral : AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.inter(
            fontSize: 11.5, fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppTokens.muted)),
        ),
      ),
    ),
  );
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color activeColor;
  const _ToggleChip({required this.label, required this.active, required this.onTap, required this.activeColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? activeColor.withValues(alpha: 0.1) : AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: active ? activeColor : AppTokens.hairline, width: 1.5),
      ),
      child: Text(label, style: GoogleFonts.inter(
        fontSize: 12.5, fontWeight: FontWeight.w600,
        color: active ? activeColor : AppTokens.inkSoft)),
    ),
  );
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;
  const _SwitchRow({required this.label, this.subtitle, required this.value, required this.onChanged, this.isLast = false});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500, color: AppTokens.ink)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: GoogleFonts.inter(
                      fontSize: 12, color: AppTokens.muted)),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTokens.coral,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
      if (!isLast)
        const Divider(height: 1, thickness: 1, color: AppTokens.hairlineSoft, indent: 0, endIndent: 0),
    ],
  );
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String? value;
  final IconData? icon;
  final bool isLast;
  final bool danger;
  final VoidCallback? onTap;
  const _SettingRow({required this.label, this.value, this.icon, this.isLast = false, this.danger = false, this.onTap});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      GestureDetector(
        onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: danger ? Colors.red.shade400 : AppTokens.muted),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(label, style: GoogleFonts.inter(
                fontSize: 14.5, fontWeight: FontWeight.w500,
                color: danger ? Colors.red.shade400 : AppTokens.ink)),
            ),
            if (value != null)
              Text(value!, style: GoogleFonts.inter(fontSize: 13, color: AppTokens.muted)),
            if (!danger)
              const Icon(Icons.chevron_right, size: 18, color: AppTokens.muted),
          ],
        ),
      ),
      ),
      if (!isLast)
        const Divider(height: 1, thickness: 1, color: AppTokens.hairline, indent: 18, endIndent: 18),
    ],
  );
}

class _MealCard extends StatelessWidget {
  final Meal meal;
  const _MealCard({required this.meal});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(
      builder: (_) => RecipeScreen(meal: meal),
    )),
    child: Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radiusMd)),
            child: SizedBox(
              height: 100, width: 130,
              child: MealImage(photo: meal.photo),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.title, style: GoogleFonts.inter(
                  fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTokens.ink),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.schedule_outlined, size: 10, color: AppTokens.muted),
                  const SizedBox(width: 3),
                  Text(meal.time, style: GoogleFonts.inter(fontSize: 10.5, color: AppTokens.muted)),
                ]),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
