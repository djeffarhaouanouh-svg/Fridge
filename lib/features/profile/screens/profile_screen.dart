import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';
import '../../meals/providers/meals_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final List<String> goals = ['Rapide', 'Sain', 'Fitness', 'Stylé'];
  final List<String> diets = ['Aucun', 'Vegan', 'Végé', 'Sans gluten'];

  String selectedGoal = 'Rapide';
  String selectedDiet = 'Aucun';

  @override
  Widget build(BuildContext context) {
    final favoriteMeals = ref.watch(favoriteMealsProvider);

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Avatar & name
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [AppTokens.accent, AppTokens.warm],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '👤',
                        style: TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mon profil',
                          style: GoogleFonts.syne(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.text,
                          ),
                        ),
                        Text(
                          '7 repas cuisinés · ${favoriteMeals.length} favoris',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppTokens.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Goals
              _ProfileSection(
                title: 'Mon objectif',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: goals.map((goal) {
                    final isSelected = goal == selectedGoal;
                    return GestureDetector(
                      onTap: () => setState(() => selectedGoal = goal),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTokens.accentDim
                              : AppTokens.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTokens.accent
                                : AppTokens.border,
                          ),
                        ),
                        child: Text(
                          goal,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                isSelected ? AppTokens.accent : AppTokens.muted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Diet
              _ProfileSection(
                title: 'Régime alimentaire',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: diets.map((diet) {
                    final isSelected = diet == selectedDiet;
                    return GestureDetector(
                      onTap: () => setState(() => selectedDiet = diet),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTokens.warm.withOpacity(0.15)
                              : AppTokens.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isSelected ? AppTokens.warm : AppTokens.border,
                          ),
                        ),
                        child: Text(
                          diet,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                isSelected ? AppTokens.warm : AppTokens.muted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Favorites
              _ProfileSection(
                title: 'Mes favoris',
                child: Column(
                  children: favoriteMeals.isEmpty
                      ? [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTokens.card,
                              borderRadius:
                                  BorderRadius.circular(AppTokens.radiusMd),
                              border: Border.all(color: AppTokens.border),
                            ),
                            child: Center(
                              child: Text(
                                'Aucun favori pour le moment',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppTokens.muted,
                                ),
                              ),
                            ),
                          ),
                        ]
                      : favoriteMeals.map((meal) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTokens.card,
                                borderRadius: BorderRadius.circular(
                                    AppTokens.radiusMd),
                                border: Border.all(color: AppTokens.border),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    meal.emoji,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          meal.title,
                                          style: GoogleFonts.syne(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppTokens.text,
                                          ),
                                        ),
                                        Text(
                                          '${meal.time} · ${meal.difficulty}',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: AppTokens.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: AppTokens.warm,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Premium CTA
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A2820), Color(0xFF1A1A2A)],
                  ),
                  border: Border.all(
                    color: AppTokens.accent.withOpacity(0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✨ Passer à Premium',
                      style: GoogleFonts.syne(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scans illimités · Plan semaine · Recettes exclusives',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppTokens.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Navigate to premium paywall
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusMd),
                          ),
                          elevation: 0,
                          shadowColor: AppTokens.accent.withOpacity(0.4),
                        ),
                        child: Text(
                          'Essai gratuit 7 jours',
                          style: GoogleFonts.syne(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.bg,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ProfileSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.syne(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTokens.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
