import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final dialogBg = isDark ? const Color(0xFF1E1E1E) : AppTokens.paper;
  final textColor = isDark ? Colors.white : AppTokens.ink;
  final mutedColor = isDark ? Colors.white70 : AppTokens.muted;
  final fieldBg = isDark ? const Color(0xFF2A2A2A) : AppTokens.surface;
  try {
    final submitted = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(
            'Ajouter un ingrédient',
            style: GoogleFonts.fraunces(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Ex : tomates, yaourt…',
              hintStyle: GoogleFonts.inter(color: mutedColor),
              filled: true,
              fillColor: fieldBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
            style: GoogleFonts.inter(fontSize: 15, color: textColor),
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
                style: GoogleFonts.inter(color: mutedColor, fontWeight: FontWeight.w600),
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

Future<void> showRemoveFridgeIngredientDialog(BuildContext context, WidgetRef ref) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final list = List<String>.from(ref.read(detectedIngredientsProvider));
  if (list.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Aucun ingrédient à supprimer.',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: AppTokens.inkSoft,
      ),
    );
    return;
  }

  final selected = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppTokens.paper,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supprimer un ingrédient',
              style: GoogleFonts.fraunces(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTokens.ink,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 260,
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? Colors.white12 : AppTokens.hairline,
                ),
                itemBuilder: (_, i) {
                  final ing = list[i];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: SizedBox(
                      width: 22,
                      height: 22,
                      child: Center(child: buildIngredientIcon(ing, emojiSize: 15)),
                    ),
                    title: Text(
                      ing,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white : AppTokens.ink,
                      ),
                    ),
                    trailing: Icon(Icons.delete_outline, color: Colors.red.shade400),
                    onTap: () => Navigator.pop(sheetContext, ing),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );

  if (selected == null) return;
  final updated = List<String>.from(ref.read(detectedIngredientsProvider));
  updated.remove(selected);
  ref.read(detectedIngredientsProvider.notifier).state = updated;
  await persistFridgeToNeon(updated);
}

Future<void> showFridgeActionDialog(BuildContext context, WidgetRef ref) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppTokens.paper,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add, color: AppTokens.coral),
            title: Text(
              'Ajouter',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : AppTokens.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => Navigator.pop(sheetContext, 'add'),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
            title: Text(
              'Supprimer',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : AppTokens.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => Navigator.pop(sheetContext, 'remove'),
          ),
        ],
      ),
    ),
  );

  if (action == 'add') {
    await showAddFridgeIngredientDialog(context, ref);
  } else if (action == 'remove') {
    await showRemoveFridgeIngredientDialog(context, ref);
  }
}

final fridgeSectionExpandedProvider = StateProvider<bool>((ref) => false);

Color _sheetBg(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFF1E1E1E) : AppTokens.paper;
}

Color _sheetText(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? Colors.white : AppTokens.ink;
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);
    final favoriteMeals = ref.watch(favoriteMealsProvider);
    final detectedIngredients = ref.watch(detectedIngredientsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFridgeExpanded = ref.watch(fridgeSectionExpandedProvider);
    final hasMoreFridgeItems = detectedIngredients.length > 5;
    final visibleFridgeItems =
        isFridgeExpanded ? detectedIngredients : detectedIngredients.take(5).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
          children: [
            const SizedBox(height: 20),

            // ── 1. Identité ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Infos compte (sans bulle avatar)
                  Row(
                    children: [
                      Expanded(
                        child: Text(profile.name,
                          style: GoogleFonts.fraunces(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTokens.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                        icon: Icon(
                          Icons.settings_outlined,
                          color: isDark ? Colors.white70 : AppTokens.inkSoft,
                          size: 22,
                        ),
                        tooltip: 'Paramètres',
                      ),
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
                  _FridgeSectionTitle(),
                  const SizedBox(height: 14),
                  if (detectedIngredients.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFFFDFBF8) : AppTokens.surface,
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
                      children: [
                        ...visibleFridgeItems.map((ing) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFFFFFCF8) : AppTokens.surface,
                            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                            border: Border.all(
                              color: isDark ? const Color(0xFFEDE5DA) : AppTokens.hairline,
                            ),
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
                        )),
                        if (hasMoreFridgeItems)
                          GestureDetector(
                            onTap: () => ref.read(fridgeSectionExpandedProvider.notifier).state = !isFridgeExpanded,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                border: Border.all(color: isDark ? Colors.white24 : AppTokens.hairline),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFridgeExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: isDark ? Colors.white70 : AppTokens.inkSoft,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isFridgeExpanded
                                        ? 'Réduire'
                                        : 'Voir +${detectedIngredients.length - 5}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : AppTokens.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
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
                          onTap: () => showFridgeActionDialog(context, ref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFFFFFCF8) : AppTokens.surface,
                              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                              border: Border.all(
                                color: isDark ? const Color(0xFFEDE5DA) : AppTokens.hairline,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add, size: 16, color: AppTokens.inkSoft),
                                const SizedBox(width: 7),
                                Text('Ajouter/Supprimer',
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

            // ── Favoris ──────────────────────────────────────────────
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

            // ── Préférences culinaires ───────────────────────────────
            _SettingRow(
              label: 'Mon corps',
              value: _bodyDataSummary(profile),
              icon: Icons.accessibility_new_outlined,
              onTap: () => _showBodyDataSheet(context, ref, notifier),
            ),
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
              onTap: () => _showDietsSheet(context, ref, notifier),
            ),
            _SettingRow(
              label: 'Votre cuisine',
              value: _joinOrNone(profile.kitchenEquipments),
              icon: Icons.kitchen_outlined,
              isLast: true,
              onTap: () => _showKitchenEquipmentsSheet(context, ref, notifier),
            ),

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
              label: 'Paramètres',
              icon: Icons.settings,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              ),
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
    backgroundColor: _sheetBg(context),
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

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);
    final aiTone = ref.watch(aiToneProvider);
    final themePreference = ref.watch(themePreferenceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF151515) : AppTokens.paper;
    final titleColor = isDark ? Colors.white : AppTokens.ink;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Paramètres',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
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
            _SettingRow(
              label: 'Langue',
              value: 'Français',
              icon: Icons.language_outlined,
            ),
            _SettingRow(
              label: 'Mon compte',
              value: profile.email,
              icon: Icons.person_outline,
              onTap: () => _showEditAccountDialog(
                context,
                profile.name,
                profile.email,
                notifier,
              ),
            ),
            _SettingRow(
              label: 'Ton de l’IA',
              value: _aiToneLabel(aiTone),
              icon: Icons.record_voice_over_outlined,
              onTap: () => _showAiToneSheet(context, ref),
            ),
            _SettingRow(
              label: 'Thème',
              value: _themeLabel(themePreference),
              icon: Icons.dark_mode_outlined,
              onTap: () => _showThemeSheet(context, ref),
            ),
            _SettingRow(
              label: 'Mes photos',
              icon: Icons.photo_library_outlined,
              onTap: () => _showUserPhotosSheet(context, ref),
            ),
            _SettingRow(label: 'Aide & support', icon: Icons.help_outline),
            _SettingRow(
              label: 'Se déconnecter',
              icon: Icons.logout_outlined,
              onTap: () async {
                await AuthService.logout();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('profile_onboarding_done_v1', false);
                if (context.mounted) {
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
  }
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
    backgroundColor: _sheetBg(context),
    builder: (_) => SafeArea(
      top: false,
      child: Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(aiToneProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Coach', style: TextStyle(color: _sheetText(context))),
                trailing: current == AiTone.coach
                    ? const Icon(Icons.check, color: AppTokens.coral)
                    : null,
                onTap: () {
                  ref.read(aiToneProvider.notifier).state = AiTone.coach;
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Chef', style: TextStyle(color: _sheetText(context))),
                trailing: current == AiTone.chef
                    ? const Icon(Icons.check, color: AppTokens.coral)
                    : null,
                onTap: () {
                  ref.read(aiToneProvider.notifier).state = AiTone.chef;
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Ami', style: TextStyle(color: _sheetText(context))),
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
    backgroundColor: _sheetBg(context),
    builder: (_) => SafeArea(
      top: false,
      child: Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(themePreferenceProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Light', style: TextStyle(color: _sheetText(context))),
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
                title: Text('Dark', style: TextStyle(color: _sheetText(context))),
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

String _bodyDataSummary(UserProfile profile) {
  final parts = <String>[];
  if (profile.gender == 'homme') parts.add('Homme');
  if (profile.gender == 'femme') parts.add('Femme');
  if (profile.age != null) parts.add('${profile.age} ans');
  if (profile.currentWeight != null) {
    final w = profile.currentWeight!;
    final label = w == w.truncateToDouble() ? '${w.toInt()} kg' : '${w.toStringAsFixed(1)} kg';
    parts.add(label);
  }
  return parts.isEmpty ? 'Non renseigné' : parts.join(' · ');
}

void _showBodyDataSheet(BuildContext context, WidgetRef ref, UserProfileNotifier notifier) {
  final profile = ref.read(userProfileProvider);
  showModalBottomSheet(
    context: context,
    backgroundColor: _sheetBg(context),
    isScrollControlled: true,
    builder: (_) => _BodyDataSheet(
      initialGender: profile.gender,
      initialAge: profile.age,
      initialWeight: profile.currentWeight,
      initialTargetWeight: profile.targetWeight,
      notifier: notifier,
    ),
  );
}

class _BodyDataSheet extends StatefulWidget {
  final String? initialGender;
  final int? initialAge;
  final double? initialWeight;
  final double? initialTargetWeight;
  final UserProfileNotifier notifier;

  const _BodyDataSheet({
    required this.initialGender,
    required this.initialAge,
    required this.initialWeight,
    required this.initialTargetWeight,
    required this.notifier,
  });

  @override
  State<_BodyDataSheet> createState() => _BodyDataSheetState();
}

class _BodyDataSheetState extends State<_BodyDataSheet> {
  late String? _gender;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _targetCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _gender = widget.initialGender;
    _ageCtrl = TextEditingController(
      text: widget.initialAge != null ? '${widget.initialAge}' : '',
    );
    _weightCtrl = TextEditingController(
      text: widget.initialWeight != null
          ? widget.initialWeight!.toStringAsFixed(widget.initialWeight! == widget.initialWeight!.truncateToDouble() ? 0 : 1)
          : '',
    );
    _targetCtrl = TextEditingController(
      text: widget.initialTargetWeight != null
          ? widget.initialTargetWeight!.toStringAsFixed(widget.initialTargetWeight! == widget.initialTargetWeight!.truncateToDouble() ? 0 : 1)
          : '',
    );
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_gender == null) return false;
    final age = int.tryParse(_ageCtrl.text);
    if (age == null || age < 10 || age > 120) return false;
    final w = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    if (w == null || w < 20 || w > 300) return false;
    final tw = double.tryParse(_targetCtrl.text.replaceAll(',', '.'));
    if (tw == null || tw < 20 || tw > 300) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    await widget.notifier.setBodyData(
      gender: _gender!,
      age: int.parse(_ageCtrl.text),
      weight: double.parse(_weightCtrl.text.replaceAll(',', '.')),
      targetWeight: double.parse(_targetCtrl.text.replaceAll(',', '.')),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : AppTokens.ink;
    final mutedColor = isDark ? Colors.white54 : AppTokens.muted;
    final fieldBg = isDark ? const Color(0xFF2A2A2A) : AppTokens.surface;
    final borderColor = isDark ? Colors.white12 : AppTokens.hairline;

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      borderSide: BorderSide(color: borderColor),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      borderSide: BorderSide(color: primary, width: 1.5),
    );
    final inputStyle = GoogleFonts.inter(fontSize: 15, color: textColor);
    final hintStyle = GoogleFonts.inter(color: mutedColor);
    final labelStyle = GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: mutedColor);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mon corps',
            style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 20),

          // Genre
          Text('Genre', style: labelStyle),
          const SizedBox(height: 8),
          Row(
            children: [
              _GenderChip(
                label: 'Homme',
                icon: Icons.male_rounded,
                selected: _gender == 'homme',
                primary: primary,
                isDark: isDark,
                onTap: () => setState(() => _gender = 'homme'),
              ),
              const SizedBox(width: 10),
              _GenderChip(
                label: 'Femme',
                icon: Icons.female_rounded,
                selected: _gender == 'femme',
                primary: primary,
                isDark: isDark,
                onTap: () => setState(() => _gender = 'femme'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Âge
          Text('Âge', style: labelStyle),
          const SizedBox(height: 8),
          TextField(
            controller: _ageCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            style: inputStyle,
            decoration: InputDecoration(
              hintText: 'Ex : 25',
              hintStyle: hintStyle,
              suffixText: 'ans',
              suffixStyle: GoogleFonts.inter(color: mutedColor),
              filled: true,
              fillColor: fieldBg,
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: focusedBorder,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),

          // Poids + poids cible côte à côte
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Poids actuel', style: labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      style: inputStyle,
                      decoration: InputDecoration(
                        hintText: '70',
                        hintStyle: hintStyle,
                        suffixText: 'kg',
                        suffixStyle: GoogleFonts.inter(color: mutedColor),
                        filled: true,
                        fillColor: fieldBg,
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Poids cible', style: labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _targetCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      style: inputStyle,
                      decoration: InputDecoration(
                        hintText: '65',
                        hintStyle: hintStyle,
                        suffixText: 'kg',
                        suffixStyle: GoogleFonts.inter(color: mutedColor),
                        filled: true,
                        fillColor: fieldBg,
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _canSave && !_saving ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                disabledBackgroundColor: primary.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Sauvegarder',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? primary.withValues(alpha: 0.12)
        : (isDark ? const Color(0xFF2A2A2A) : AppTokens.surface);
    final borderColor = selected ? primary.withValues(alpha: 0.6) : Colors.transparent;
    final contentColor = selected ? primary : (isDark ? Colors.white54 : AppTokens.inkSoft);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: contentColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _objectiveLabel(CookingObjective? objective) => switch (objective) {
      CookingObjective.weightLoss => 'Perte de poids',
      CookingObjective.muscleGain => 'Prise de masse',

      CookingObjective.healthy => 'Manger sainement',
      CookingObjective.learn => 'Apprendre à cuisiner',
      CookingObjective.maintain => 'Garder la ligne',
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
    backgroundColor: _sheetBg(context),
    isScrollControlled: true,
    builder: (_) => SafeArea(
      top: false,
      child: Consumer(
        builder: (context, ref, _) {
          final objective = ref.watch(userProfileProvider).objective;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: objective == CookingObjective.weightLoss,
                onChanged: (_) async {
                  await notifier.setObjective(CookingObjective.weightLoss);
                },
                title: Text('Perte de poids', style: TextStyle(color: _sheetText(context))),
                activeColor: AppTokens.coral,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
              CheckboxListTile(
                value: objective == CookingObjective.muscleGain,
                onChanged: (_) async {
                  await notifier.setObjective(CookingObjective.muscleGain);
                },
                title: Text('Prise de masse', style: TextStyle(color: _sheetText(context))),
                activeColor: AppTokens.coral,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
              CheckboxListTile(
                value: objective == CookingObjective.healthy,
                onChanged: (_) async {
                  await notifier.setObjective(CookingObjective.healthy);
                },
                title: Text('Manger sainement', style: TextStyle(color: _sheetText(context))),
                activeColor: AppTokens.coral,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
              CheckboxListTile(
                value: objective == CookingObjective.learn,
                onChanged: (_) async {
                  await notifier.setObjective(CookingObjective.learn);
                },
                title: Text('Apprendre à cuisiner', style: TextStyle(color: _sheetText(context))),
                activeColor: AppTokens.coral,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
              CheckboxListTile(
                value: objective == CookingObjective.maintain,
                onChanged: (_) async {
                  await notifier.setObjective(CookingObjective.maintain);
                },
                title: Text('Garder la ligne', style: TextStyle(color: _sheetText(context))),
                activeColor: AppTokens.coral,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
            ],
          );
        },
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
    backgroundColor: _sheetBg(context),
    isScrollControlled: true,
    builder: (_) => SafeArea(
      top: false,
      child: Consumer(
        builder: (context, ref, _) {
          final level = ref.watch(userProfileProvider).cookingLevel;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: level == CookingLevel.beginner,
                onChanged: (checked) async {
                  if (checked == true) await notifier.setCookingLevel(CookingLevel.beginner);
                },
                title: Text('Débutant', style: TextStyle(color: _sheetText(context))),
                activeColor: AppTokens.coral,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
              CheckboxListTile(
                value: level == CookingLevel.intermediate,
                onChanged: (checked) async {
                  if (checked == true) await notifier.setCookingLevel(CookingLevel.intermediate);
                },
                title: Text('Intermédiaire', style: TextStyle(color: _sheetText(context))),
                activeColor: AppTokens.coral,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
              CheckboxListTile(
                value: level == CookingLevel.advanced,
                onChanged: (checked) async {
                  if (checked == true) await notifier.setCookingLevel(CookingLevel.advanced);
                },
                title: Text('Avancé', style: TextStyle(color: _sheetText(context))),
                activeColor: AppTokens.coral,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
              CheckboxListTile(
                value: level == CookingLevel.expert,
                onChanged: (checked) async {
                  if (checked == true) await notifier.setCookingLevel(CookingLevel.expert);
                },
                title: Text('Expert', style: TextStyle(color: _sheetText(context))),
                activeColor: AppTokens.coral,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
            ],
          );
        },
      ),
    ),
  );
}

void _showAllergiesSheet(
  BuildContext context,
  WidgetRef ref,
  UserProfileNotifier notifier,
) {
  const options = ['Gluten', 'Lactose', 'Noix', 'Œufs', 'Fruits de mer', 'Soja', 'Aucune'];
  showModalBottomSheet(
    context: context,
    backgroundColor: _sheetBg(context),
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
                  title: Text(a, style: TextStyle(color: _sheetText(context))),
                  activeColor: AppTokens.coral,
                  checkColor: Colors.white,
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
  const options = ['Végétarien', 'Végétalien', 'Halal', 'Sans gluten', 'Sans lactose', 'Aucun'];
  showModalBottomSheet(
    context: context,
    backgroundColor: _sheetBg(context),
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
                  title: Text(d, style: TextStyle(color: _sheetText(context))),
                  activeColor: AppTokens.coral,
                  checkColor: Colors.white,
                ),
            ],
          );
        },
      ),
    ),
  );
}

void _showKitchenEquipmentsSheet(
  BuildContext context,
  WidgetRef ref,
  UserProfileNotifier notifier,
) {
  const options = [
    'Micro-ondes',
    'Four',
    'Plaques de cuisson',
    'Friteuse',
    'Mixeur',
    'Robot cuiseur',
    'Air-fryer',
  ];
  final icons = <String, IconData>{
    'Micro-ondes': Icons.microwave_outlined,
    'Four': Icons.local_fire_department_outlined,
    'Plaques de cuisson': Icons.grid_4x4_outlined,
    'Friteuse': Icons.set_meal_outlined,
    'Mixeur': Icons.blender_outlined,
    'Robot cuiseur': Icons.soup_kitchen_outlined,
    'Air-fryer': Icons.kitchen_outlined,
  };

  showModalBottomSheet(
    context: context,
    backgroundColor: _sheetBg(context),
    isScrollControlled: true,
    builder: (_) => SafeArea(
      top: false,
      child: Consumer(
        builder: (context, ref, _) {
          final selected = ref.watch(userProfileProvider).kitchenEquipments;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in options)
                CheckboxListTile(
                  value: selected.contains(item),
                  onChanged: (_) => notifier.toggleKitchenEquipment(item),
                  title: Row(
                    children: [
                      Icon(
                        icons[item] ?? Icons.kitchen_outlined,
                        size: 18,
                        color: _sheetText(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(color: _sheetText(context)),
                        ),
                      ),
                    ],
                  ),
                  activeColor: AppTokens.coral,
                  checkColor: Colors.white,
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? Colors.white12 : AppTokens.hairline,
      ),
    );
  }
}

class _FridgeSectionTitle extends ConsumerWidget {
  const _FridgeSectionTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<String?>(
      future: SharedPreferences.getInstance()
          .then((p) => p.getString('last_scan_date')),
      builder: (context, snap) {
        String? subtitle;
        if (snap.hasData && snap.data != null) {
          final last = DateTime.tryParse(snap.data!);
          if (last != null) {
            final days = DateTime.now().difference(last).inDays;
            subtitle = days == 0
                ? "(scanné aujourd'hui)"
                : days == 1
                    ? "(il y a 1 jour)"
                    : "(il y a $days jours)";
          }
        }
        return Row(
          children: [
            Text(
              'Mon frigo actuel',
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTokens.ink,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 6),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: isDark ? Colors.white54 : AppTokens.muted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: GoogleFonts.fraunces(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppTokens.ink,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _Stat({required this.value, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.fraunces(
            fontSize: 28, fontWeight: FontWeight.w700, color: AppTokens.coral)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(
            fontSize: 11.5,
            color: isDark ? Colors.white70 : AppTokens.muted,
            fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Color color;
  const _MacroCard({required this.value, required this.unit, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border(bottom: BorderSide(color: color, width: 2.5)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.fraunces(
              fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 3),
            Text(label, style: GoogleFonts.inter(
              fontSize: 10,
              color: isDark ? Colors.white70 : AppTokens.muted,
              fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;
  const _SwitchRow({required this.label, this.subtitle, required this.value, required this.onChanged, this.isLast = false});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppTokens.ink)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : AppTokens.muted)),
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
          Divider(height: 1, thickness: 1, color: isDark ? Colors.white12 : AppTokens.hairlineSoft, indent: 0, endIndent: 0),
      ],
    );
  }
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTokens.ink;
    final mutedColor = isDark ? Colors.white70 : AppTokens.muted;
    final dividerColor = isDark ? Colors.white12 : AppTokens.hairline;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: danger ? Colors.red.shade400 : mutedColor),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(label, style: GoogleFonts.inter(
                    fontSize: 14.5, fontWeight: FontWeight.w500,
                    color: danger ? Colors.red.shade400 : textColor)),
                ),
                if (value != null)
                  Text(value!, style: GoogleFonts.inter(fontSize: 13, color: mutedColor)),
                if (!danger)
                  Icon(Icons.chevron_right, size: 18, color: mutedColor),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 1, color: dividerColor, indent: 18, endIndent: 18),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;
  const _MealCard({required this.meal});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(
      builder: (_) => RecipeScreen(meal: meal),
    )),
    child: Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radiusMd)),
            child: SizedBox(
              height: 100, width: 130,
              child: MealImage(
                photo: meal.photo,
                fallbackKey: meal.title,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.title, style: GoogleFonts.inter(
                  fontSize: 11.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTokens.ink),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.schedule_outlined, size: 10, color: isDark ? Colors.white70 : AppTokens.muted),
                  const SizedBox(width: 3),
                  Text(meal.time, style: GoogleFonts.inter(fontSize: 10.5, color: isDark ? Colors.white70 : AppTokens.muted)),
                ]),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}
