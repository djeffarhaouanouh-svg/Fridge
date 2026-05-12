import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/ingredient_category.dart';
import '../../../core/widgets/meal_image.dart';
import '../../../core/widgets/glass_button.dart';
import '../../meals/providers/meals_provider.dart';
import '../../meals/models/meal.dart';
import 'recipe_screen.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : AppTokens.ink;
    final muted = isDark ? Colors.white70 : AppTokens.muted;
    final surface = isDark ? const Color(0xFF1E1E1E) : AppTokens.surface;
    final hair = isDark ? Colors.white24 : AppTokens.hairline;
    final hairSoft = isDark ? Colors.white12 : AppTokens.hairlineSoft;
    final scanMeals = ref.watch(latestScanMealsProvider);
    final allMeals = ref.watch(mealsProvider);
    final meals = scanMeals.isNotEmpty ? scanMeals : allMeals;
    final scanIngredients = ref.watch(latestScanIngredientsProvider);
    final fridgeIngredients = ref.watch(detectedIngredientsProvider);
    final ingredients =
        scanIngredients.isNotEmpty ? scanIngredients : fridgeIngredients;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppTokens.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Icon(Icons.arrow_back_ios_new, size: 18, color: ink),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Voici ce que j\'ai détecté',
                        style: GoogleFonts.fraunces(
                          fontSize: 16, fontWeight: FontWeight.w600, color: ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                children: [
                  // Section ingrédients détectés (dernière photo)
                  if (ingredients.isNotEmpty) ...[
                    Text(
                      'DÉTECTÉS · ${ingredients.length}',
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppTokens.coral, letterSpacing: 0.06 * 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        ...ingredients.map((ing) => _IngredientTag(label: ing)),
                        GestureDetector(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const _IngredientsEditorSheet(),
                          ),
                          child: Text('+ Ajouter ou modifier',
                            style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500,
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Section frigo actuel (tous les ingrédients connus)
                  if (fridgeIngredients.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Mon frigo actuel',
                      style: GoogleFonts.fraunces(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: fridgeIngredients.map((ing) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusPill),
                            border: Border.all(color: hair),
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
                              Text(
                                ing,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: ink,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Container(height: 1, color: hairSoft),
                    const SizedBox(height: 20),
                  ],

                  // Titre section recettes — AI personality
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'J\'ai trouvé ',
                          style: GoogleFonts.fraunces(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: ink, height: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: '${meals.length} idées',
                          style: GoogleFonts.fraunces(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: AppTokens.coral, fontStyle: FontStyle.italic,
                            height: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: ' pour ce soir 👨‍🍳',
                          style: GoogleFonts.fraunces(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: ink, height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _aiSubtitle(meals),
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500, color: muted,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Liste des recettes
                  ...List.generate(meals.length, (i) => _RecipeCard(
                    meal: meals[i],
                    index: i,
                  )),

                  const SizedBox(height: 28),

                  // CTA Explorer
                  Align(
                    alignment: Alignment.center,
                    child: GlassButton(
                      label: 'Explorer d\'autres idées',
                      icon: Icons.explore_outlined,
                      color: GlassButtonColor.green,
                      size: GlassButtonSize.lg,
                      fullWidth: false,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet édition ingrédients ────────────────────────────────────────

class _IngredientsEditorSheet extends ConsumerStatefulWidget {
  const _IngredientsEditorSheet();

  @override
  ConsumerState<_IngredientsEditorSheet> createState() =>
      _IngredientsEditorSheetState();
}

class _IngredientsEditorSheetState
    extends ConsumerState<_IngredientsEditorSheet> {
  final _addCtrl = TextEditingController();
  final _editCtrl = TextEditingController();
  int? _editingIndex;

  @override
  void dispose() {
    _addCtrl.dispose();
    _editCtrl.dispose();
    super.dispose();
  }

  void _startEdit(int index, String current) {
    setState(() {
      _editingIndex = index;
      _editCtrl.text = current;
    });
  }

  Future<void> _saveEdit(int index) async {
    final val = _editCtrl.text.trim();
    if (val.isNotEmpty) {
      final list = List<String>.from(ref.read(latestScanIngredientsProvider));
      list[index] = val;
      ref.read(latestScanIngredientsProvider.notifier).state = list;
    }
    setState(() => _editingIndex = null);
  }

  Future<void> _delete(int index) async {
    final list = List<String>.from(ref.read(latestScanIngredientsProvider));
    list.removeAt(index);
    ref.read(latestScanIngredientsProvider.notifier).state = list;
    if (_editingIndex == index) setState(() => _editingIndex = null);
  }

  Future<void> _addIngredient() async {
    final val = _addCtrl.text.trim();
    if (val.isEmpty) return;
    final list = List<String>.from(ref.read(latestScanIngredientsProvider));
    list.add(val.toLowerCase());
    ref.read(latestScanIngredientsProvider.notifier).state = list;
    _addCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = ref.watch(latestScanIngredientsProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTokens.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.muted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Modifier les ingrédients',
              style: GoogleFonts.fraunces(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppTokens.ink,
              ),
            ),
            const SizedBox(height: 16),

            // Liste éditable
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: ingredients.length,
                itemBuilder: (_, i) {
                  if (_editingIndex == i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _editCtrl,
                              autofocus: true,
                              style: GoogleFonts.inter(fontSize: 14, color: AppTokens.ink),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppTokens.coral),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppTokens.coral, width: 1.5),
                                ),
                              ),
                              onSubmitted: (_) => _saveEdit(i),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _saveEdit(i),
                            child: const Icon(Icons.check_circle, size: 22, color: AppTokens.coral),
                          ),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 5, height: 5,
                          decoration: const BoxDecoration(
                            color: AppTokens.ink, shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(ingredients[i],
                            style: GoogleFonts.inter(fontSize: 14, color: AppTokens.ink),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _startEdit(i, ingredients[i]),
                          child: Icon(Icons.edit_outlined, size: 18, color: AppTokens.muted),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () => _delete(i),
                          child: const Icon(Icons.close, size: 18, color: AppTokens.coral),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),
            Container(height: 1, color: AppTokens.hairlineSoft),
            const SizedBox(height: 12),

            // Champ ajouter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addCtrl,
                    style: GoogleFonts.inter(fontSize: 14, color: AppTokens.ink),
                    decoration: InputDecoration(
                      hintText:
                          'ajoute un ingrédient que je n\'ai pas détecté',
                      hintStyle: GoogleFonts.inter(color: AppTokens.muted, fontSize: 14),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _addIngredient(),
                  ),
                ),
                GestureDetector(
                  onTap: _addIngredient,
                  child: Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(
                      color: AppTokens.coral, shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Bouton valider
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTokens.ink,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
                child: Center(
                  child: Text('Valider',
                    style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
                    ),
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

// ── Chip ingrédient ──────────────────────────────────────────────────────────

class _IngredientTag extends StatelessWidget {
  final String label;
  const _IngredientTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E1E1E) : AppTokens.surface;
    final ink = isDark ? Colors.white : AppTokens.ink;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(
              color: ink, shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500, color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers IA ───────────────────────────────────────────────────────────────

int _parseTimeMinutes(String time) {
  final match = RegExp(r'(\d+)').firstMatch(time);
  return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
}

String _aiSubtitle(List<Meal> meals) {
  if (meals.isEmpty) return 'Avec ce que tu as déjà';
  final n = meals.length;
  final fastCount = meals.where((m) {
    final min = _parseTimeMinutes(m.time);
    return min > 0 && min <= 20;
  }).length;
  if (fastCount == n) return 'Tout se prépare en moins de 20 minutes ⚡';
  final highProteinCount = meals.where((m) => m.protein == 'élevé').length;
  if (highProteinCount * 2 >= n) return 'Riches en protéines, parfait pour tes objectifs 💪';
  final lightCount = meals.where((m) => m.kcal > 0 && m.kcal < 400).length;
  if (lightCount == n) return 'Des recettes légères et équilibrées 🌿';
  final options = [
    'Tes ingrédients matchent super bien ensemble.',
    'Tu peux faire quelque chose de vraiment bon ce soir.',
    'Avec ce que tu as déjà dans ton frigo.',
  ];
  return options[n % options.length];
}

String _aiComment(Meal meal) {
  final timeMin = _parseTimeMinutes(meal.time);
  if (timeMin > 0 && timeMin <= 15) return 'Prêt en moins de 15 minutes.';
  if (meal.protein == 'élevé' || (meal.proteinG != null && meal.proteinG! >= 25)) {
    return 'Excellent apport en protéines.';
  }
  if (meal.kcal > 0 && meal.kcal < 350) return 'Léger et frais pour ce soir.';
  if (meal.kcal > 550) return 'Copieux et bien nourrissant.';
  if (meal.difficulty == 'facile') return 'Simple à préparer, délicieux à déguster.';
  return 'Parfait avec ce que tu as dans ton frigo.';
}

// ── Carte recette premium ─────────────────────────────────────────────────────

class _RecipeCard extends ConsumerWidget {
  final Meal meal;
  final int index;
  const _RecipeCard({required this.meal, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : AppTokens.ink;
    final muted = isDark ? Colors.white70 : AppTokens.muted;
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final num = (index + 1).toString().padLeft(2, '0');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => RecipeScreen(meal: meal, isGeneratedRecipe: true),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppTokens.coral.withOpacity(0.13),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTokens.radiusMd),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 210,
                    width: double.infinity,
                    child: MealImage(
                      photo: meal.photo,
                      fallbackKey: meal.title,
                    ),
                  ),
                  // Gradient bottom overlay
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // N° badge
                  Positioned(
                    top: 12, left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTokens.coral,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: AppTokens.coral.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text('N°$num',
                        style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.title,
                    style: GoogleFonts.fraunces(
                      fontSize: 17, fontWeight: FontWeight.w700,
                      color: ink, height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(_aiComment(meal),
                    style: GoogleFonts.inter(
                      fontSize: 12.5, fontWeight: FontWeight.w400,
                      color: muted, fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Badge(
                        label: '${meal.kcal} kcal',
                        icon: Icons.local_fire_department_rounded,
                        color: AppTokens.coral,
                      ),
                      _Badge(
                        label: meal.protein == 'élevé' ? 'Protéines ↑' : 'Protéines',
                        icon: Icons.fitness_center_rounded,
                        color: meal.protein == 'élevé'
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF9E9E9E),
                      ),
                      _Badge(
                        label: meal.difficulty,
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFFF5A623),
                      ),
                      _Badge(
                        label: meal.time,
                        icon: Icons.schedule_rounded,
                        color: const Color(0xFF5B8DEF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                    child: Text('Voir la recette',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.5, fontWeight: FontWeight.w600,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Badge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
            style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
