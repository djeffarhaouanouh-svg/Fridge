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
    final scanMeals = ref.watch(latestScanMealsProvider);
    final allMeals = ref.watch(mealsProvider);
    final meals = scanMeals.isNotEmpty ? scanMeals : allMeals;
    final scanIngredients = ref.watch(latestScanIngredientsProvider);
    final fridgeIngredients = ref.watch(detectedIngredientsProvider);
    final ingredients =
        scanIngredients.isNotEmpty ? scanIngredients : fridgeIngredients;

    return Scaffold(
      backgroundColor: AppTokens.paper,
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
                    child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppTokens.ink),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Voici ce que j\'ai détecté',
                        style: GoogleFonts.fraunces(
                          fontSize: 16, fontWeight: FontWeight.w600, color: AppTokens.ink,
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
                              color: AppTokens.muted,
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
                        color: AppTokens.ink,
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
                            color: AppTokens.surface,
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusPill),
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
                              Text(
                                ing,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppTokens.ink,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Container(height: 1, color: AppTokens.hairlineSoft),
                    const SizedBox(height: 20),
                  ],

                  // Titre section recettes
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${meals.length} recettes pour ',
                          style: GoogleFonts.fraunces(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: AppTokens.ink, height: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: 'ce soir',
                          style: GoogleFonts.fraunces(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: AppTokens.coral, fontStyle: FontStyle.italic,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Avec ce que tu as déjà',
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500, color: AppTokens.muted,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Liste des recettes
                  ...List.generate(meals.length, (i) => _RecipeRow(
                    meal: meals[i],
                    index: i,
                  )),

                  const SizedBox(height: 28),

                  // CTA "Générer plus de recettes"
                  Align(
                    alignment: Alignment.center,
                    child: GlassButton(
                      label: 'Générer plus de recettes',
                      icon: Icons.auto_awesome,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5, height: 5,
            decoration: const BoxDecoration(
              color: AppTokens.ink, shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500, color: AppTokens.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ligne recette ────────────────────────────────────────────────────────────

class _RecipeRow extends ConsumerWidget {
  final Meal meal;
  final int index;
  const _RecipeRow({required this.meal, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final num = (index + 1).toString().padLeft(2, '0');

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => RecipeScreen(meal: meal),
        ));
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  child: SizedBox(
                    width: 72, height: 72,
                    child: MealImage(
                      photo: meal.photo,
                      fallbackKey: meal.title,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('N°$num',
                        style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppTokens.coral, letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(meal.title,
                        style: GoogleFonts.fraunces(
                          fontSize: 15.5, fontWeight: FontWeight.w600,
                          color: AppTokens.ink, height: 1.25,
                        ),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule_outlined, size: 13, color: AppTokens.muted),
                          const SizedBox(width: 4),
                          Text(meal.time,
                            style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w500, color: AppTokens.muted,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('·',
                              style: GoogleFonts.inter(fontSize: 12, color: AppTokens.muted),
                            ),
                          ),
                          Text('${meal.kcal} kcal',
                            style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600, color: AppTokens.muted,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('·',
                              style: GoogleFonts.inter(fontSize: 12, color: AppTokens.muted),
                            ),
                          ),
                          Text(meal.difficulty,
                            style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w500, color: AppTokens.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1.5, color: AppTokens.coral.withOpacity(0.25)),
        ],
      ),
    );
  }
}
