import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/neon_service.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/meal_image.dart';
import '../../../main.dart';
import '../../../core/services/fridge_sync.dart';
import '../../../core/utils/ingredient_category.dart';
import '../../../core/widgets/app_header.dart';
import '../../meals/providers/meals_provider.dart';
import '../../meals/models/meal.dart';
import '../../meals/screens/recipe_screen.dart';
import '../../navigation/widgets/bottom_nav.dart';
import '../providers/profile_provider.dart';

Future<void> showAddFridgeIngredientDialog(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  try {
    final submitted = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTokens.paper,
          title: Text(
            'Ajouter un ingrédient',
            style: GoogleFonts.fraunces(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTokens.ink,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Ex : tomates, yaourt…',
              hintStyle: GoogleFonts.inter(color: AppTokens.muted),
              filled: true,
              fillColor: AppTokens.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
            style: GoogleFonts.inter(fontSize: 15, color: AppTokens.ink),
            onSubmitted: (v) {
              final t = v.trim();
              if (t.isNotEmpty) Navigator.pop(ctx, t);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Annuler',
                style: GoogleFonts.inter(color: AppTokens.muted, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () {
                final t = controller.text.trim();
                if (t.isEmpty) return;
                Navigator.pop(ctx, t);
              },
              child: Text(
                'Ajouter',
                style: GoogleFonts.inter(color: AppTokens.coral, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
    if (submitted == null || submitted.isEmpty) return;

    final list = List<String>.from(ref.read(detectedIngredientsProvider));
    final lower = submitted.toLowerCase();
    if (list.any((x) => x.toLowerCase() == lower)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cet ingrédient est déjà dans ton frigo.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppTokens.inkSoft,
        ),
      );
      return;
    }
    list.add(submitted);
    ref.read(detectedIngredientsProvider.notifier).state = list;
    await persistFridgeToNeon(list);
  } finally {
    controller.dispose();
  }
}

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
    final loginStreak = ref.watch(loginStreakProvider);
    final cookedCount = selections.length;
    final streak = loginStreak;

    return Scaffold(
      backgroundColor: AppTokens.paper,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
          children: [
            const AppHeader(brand: true),
            const SizedBox(height: 12),

            // ── 1. Identité ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Infos compte (sans bulle avatar)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name,
                        style: GoogleFonts.fraunces(
                          fontSize: 18, fontWeight: FontWeight.w700, color: AppTokens.ink,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  _SettingRow(
                    label: 'Objectif',
                    value: _objectiveLabel(profile.objective),
                    icon: Icons.flag_outlined,
                    onTap: () => _showObjectiveSheet(context, notifier),
                  ),
                  _SettingRow(
                    label: 'Niveau de cuisine',
                    value: _cookingLevelLabel(profile.cookingLevel),
                    icon: Icons.auto_awesome_outlined,
                    onTap: () => _showCookingLevelSheet(context, notifier),
                  ),
                  _SettingRow(
                    label: 'Allergies',
                    value: _joinOrNone(profile.allergies),
                    icon: Icons.warning_amber_outlined,
                    onTap: () => _showAllergiesSheet(context, ref, notifier),
                  ),
                  _SettingRow(
                    label: 'Regime',
                    value: _joinOrNone(profile.diets),
                    icon: Icons.restaurant_menu_outlined,
                    isLast: true,
                    onTap: () => _showDietsSheet(context, ref, notifier),
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
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Center(
                                  child: buildIngredientIcon(ing, emojiSize: 15),
                                ),
                              ),
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
                          onTap: () => showAddFridgeIngredientDialog(context, ref),
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

            // ── 9. Paramètres ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: _SectionTitle(title: 'Paramètres'),
            ),
            _SettingRow(
              label: 'Mes photos',
              icon: Icons.photo_library_outlined,
              onTap: () => _showUserPhotosSheet(context, ref),
            ),
            _SettingRow(
              label: 'Paramètres',
              icon: Icons.settings,
              onTap: () => _showSettingsSheet(context, ref, profile, notifier),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

void _showUserPhotosSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTokens.paper,
    isScrollControlled: true,
    builder: (_) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Consumer(
            builder: (context, ref, _) {
              final photosAsync = ref.watch(userPhotosProvider);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Mes photos'),
                  const SizedBox(height: 12),
                  photosAsync.when(
                    data: (photos) {
                      if (photos.isEmpty) {
                        return Text(
                          'Aucune photo envoyee pour le moment.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTokens.muted,
                          ),
                        );
                      }
                      return SizedBox(
                        height: 124,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: photos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final p = photos[i];
                            return _UserPhotoCard(
                              base64: p.base64,
                              onDelete: () async {
                                await NeonService().deleteUserPhoto(p.id);
                                ref.invalidate(userPhotosProvider);
                              },
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 42,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTokens.coral,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    error: (e, _) => Text(
                      'Erreur chargement photos: $e',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

void _showSettingsSheet(
  BuildContext rootContext,
  WidgetRef ref,
  UserProfile profile,
  UserProfileNotifier notifier,
) {
  showModalBottomSheet(
    context: rootContext,
    backgroundColor: AppTokens.paper,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SettingRow(label: 'Langue', value: 'Français', icon: Icons.language_outlined),
              _SettingRow(
                label: 'Mon compte',
                value: profile.email,
                icon: Icons.person_outline,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showEditAccountDialog(
                    rootContext,
                    profile.name,
                    profile.email,
                    notifier,
                  );
                },
              ),
              _SettingRow(
                label: 'Ton de l’IA',
                value: _aiToneLabel(ref.read(aiToneProvider)),
                icon: Icons.record_voice_over_outlined,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showAiToneSheet(rootContext, ref);
                },
              ),
              _SettingRow(
                label: 'Thème',
                value: _themeLabel(ref.read(themePreferenceProvider)),
                icon: Icons.dark_mode_outlined,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showThemeSheet(rootContext, ref);
                },
              ),
              _SettingRow(label: 'Aide & support', icon: Icons.help_outline),
              _SettingRow(
                label: 'Se déconnecter',
                icon: Icons.logout_outlined,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await AuthService.logout();
                  if (rootContext.mounted) {
                    ref.read(authStateProvider.notifier).state = false;
                  }
                },
              ),
              const SizedBox(height: 6),
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
    },
  );
}

String _aiToneLabel(AiTone tone) => switch (tone) {
      AiTone.coach => 'Coach',
      AiTone.chef => 'Chef',
      AiTone.ami => 'Ami',
    };

String _themeLabel(ThemePreference p) => switch (p) {
      ThemePreference.light => 'Light',
      ThemePreference.dark => 'Dark',
    };

void _showAiToneSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTokens.paper,
    builder: (_) => SafeArea(
      top: false,
      child: Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(aiToneProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Coach'),
                trailing: current == AiTone.coach
                    ? const Icon(Icons.check, color: AppTokens.coral)
                    : null,
                onTap: () {
                  ref.read(aiToneProvider.notifier).state = AiTone.coach;
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Chef'),
                trailing: current == AiTone.chef
                    ? const Icon(Icons.check, color: AppTokens.coral)
                    : null,
                onTap: () {
                  ref.read(aiToneProvider.notifier).state = AiTone.chef;
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Ami'),
                trailing: current == AiTone.ami
                    ? const Icon(Icons.check, color: AppTokens.coral)
                    : null,
                onTap: () {
                  ref.read(aiToneProvider.notifier).state = AiTone.ami;
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    ),
  );
}

void _showThemeSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTokens.paper,
    builder: (_) => SafeArea(
      top: false,
      child: Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(themePreferenceProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Light'),
                trailing: current == ThemePreference.light
                    ? const Icon(Icons.check, color: AppTokens.coral)
                    : null,
                onTap: () {
                  ref.read(themePreferenceProvider.notifier).state =
                      ThemePreference.light;
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Dark'),
                trailing: current == ThemePreference.dark
                    ? const Icon(Icons.check, color: AppTokens.coral)
                    : null,
                onTap: () {
                  ref.read(themePreferenceProvider.notifier).state =
                      ThemePreference.dark;
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    ),
  );
}

String _objectiveLabel(CookingObjective? objective) => switch (objective) {
      CookingObjective.weightLoss => 'Perte de poids',
      CookingObjective.muscleGain => 'Prise de masse',
      CookingObjective.family => 'Famille',
      CookingObjective.passion => 'Passion cuisine',
      null => 'Non défini',
    };

String _cookingLevelLabel(CookingLevel? level) => switch (level) {
      CookingLevel.beginner => 'Débutant',
      CookingLevel.intermediate => 'Intermédiaire',
      CookingLevel.advanced => 'Avancé',
      CookingLevel.expert => 'Expert',
      null => 'Non défini',
    };

String _joinOrNone(Set<String> values) {
  if (values.isEmpty) return 'Aucun';
  return values.take(2).join(', ') + (values.length > 2 ? '…' : '');
}

void _showObjectiveSheet(
  BuildContext context,
  UserProfileNotifier notifier,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTokens.paper,
    builder: (_) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Perte de poids'),
            onTap: () {
              notifier.setObjective(CookingObjective.weightLoss);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Prise de masse'),
            onTap: () {
              notifier.setObjective(CookingObjective.muscleGain);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Famille'),
            onTap: () {
              notifier.setObjective(CookingObjective.family);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Passion cuisine'),
            onTap: () {
              notifier.setObjective(CookingObjective.passion);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

void _showCookingLevelSheet(
  BuildContext context,
  UserProfileNotifier notifier,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTokens.paper,
    builder: (_) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Débutant'),
            onTap: () {
              notifier.setCookingLevel(CookingLevel.beginner);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Intermédiaire'),
            onTap: () {
              notifier.setCookingLevel(CookingLevel.intermediate);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Avancé'),
            onTap: () {
              notifier.setCookingLevel(CookingLevel.advanced);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Expert'),
            onTap: () {
              notifier.setCookingLevel(CookingLevel.expert);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

void _showAllergiesSheet(
  BuildContext context,
  WidgetRef ref,
  UserProfileNotifier notifier,
) {
  const options = ['Gluten', 'Lactose', 'Noix', 'Œufs', 'Fruits de mer', 'Soja'];
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTokens.paper,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      top: false,
      child: Consumer(
        builder: (context, ref, _) {
          final selected = ref.watch(userProfileProvider).allergies;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final a in options)
                CheckboxListTile(
                  value: selected.contains(a),
                  onChanged: (_) => notifier.toggleAllergy(a),
                  title: Text(a),
                  activeColor: AppTokens.coral,
                ),
            ],
          );
        },
      ),
    ),
  );
}

void _showDietsSheet(
  BuildContext context,
  WidgetRef ref,
  UserProfileNotifier notifier,
) {
  const options = ['Végétarien', 'Végétalien', 'Halal', 'Keto', 'Sans gluten', 'Sans lactose'];
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTokens.paper,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      top: false,
      child: Consumer(
        builder: (context, ref, _) {
          final selected = ref.watch(userProfileProvider).diets;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final d in options)
                CheckboxListTile(
                  value: selected.contains(d),
                  onChanged: (_) => notifier.toggleDiet(d),
                  title: Text(d),
                  activeColor: AppTokens.coral,
                ),
            ],
          );
        },
      ),
    ),
  );
}

void _showEditAccountDialog(
  BuildContext context,
  String currentName,
  String currentEmail,
  UserProfileNotifier notifier,
) {
  final nameCtrl = TextEditingController(text: currentName);
  final emailCtrl = TextEditingController(text: currentEmail);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTokens.paper,
      title: Text('Modifier le compte',
          style: GoogleFonts.fraunces(
              fontWeight: FontWeight.w600, color: AppTokens.ink)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            autofocus: true,
            style: GoogleFonts.inter(fontSize: 14.5, color: AppTokens.ink),
            decoration: InputDecoration(
              hintText: 'Ton prenom',
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
          const SizedBox(height: 10),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(fontSize: 14.5, color: AppTokens.ink),
            decoration: InputDecoration(
              hintText: 'Ton email',
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Annuler',
              style: GoogleFonts.inter(color: AppTokens.muted)),
        ),
        TextButton(
          onPressed: () async {
            final name = nameCtrl.text.trim();
            final email = emailCtrl.text.trim();
            if (name.isNotEmpty) {
              await notifier.updateName(name);
            }
            if (email.isNotEmpty && email != currentEmail) {
              final err = await notifier.updateEmail(email);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err)),
                );
              }
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

class _UserPhotoCard extends StatelessWidget {
  final String base64;
  final Future<void> Function() onDelete;

  const _UserPhotoCard({
    required this.base64,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(base64);
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.hairline),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              child: Image.memory(bytes, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
              activeThumbColor: AppTokens.coral,
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
