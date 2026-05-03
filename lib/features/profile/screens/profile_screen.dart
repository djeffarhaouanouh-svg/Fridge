import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_tokens.dart';
import '../../meals/providers/meals_provider.dart';
import '../../meals/models/meal.dart';
import '../../meals/screens/recipe_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteMeals = ref.watch(favoriteMealsProvider);
    final allMeals = ref.watch(mealsProvider);

    return Scaffold(
      backgroundColor: AppTokens.paper,
      body: SafeArea(
        child: ListView(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              child: Center(
                child: Text('Profil',
                  style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600, color: AppTokens.ink,
                  ),
                ),
              ),
            ),

            // User card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      color: AppTokens.coralSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTokens.coral, width: 1.5),
                    ),
                    child: Center(
                      child: Text('L',
                        style: GoogleFonts.fraunces(
                          fontSize: 24, fontWeight: FontWeight.w700, color: AppTokens.coral,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Louis Dubois',
                          style: GoogleFonts.inter(
                            fontSize: 17, fontWeight: FontWeight.w700, color: AppTokens.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('louis@fridge.ai',
                          style: GoogleFonts.inter(
                            fontSize: 13, color: AppTokens.muted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTokens.coral, width: 1),
                              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_outlined, size: 13, color: AppTokens.coral),
                                const SizedBox(width: 5),
                                Text('Modifier',
                                  style: GoogleFonts.inter(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: AppTokens.coral,
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
            ),

            const SizedBox(height: 28),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  _Stat(value: '${allMeals.length}', label: 'Recettes'),
                  _Stat(value: '${favoriteMeals.length}', label: 'Favoris'),
                  _Stat(value: '0', label: 'Scans'),
                ],
              ),
            ),

            const SizedBox(height: 22),
            const Divider(height: 1, thickness: 1, color: AppTokens.hairline),
            const SizedBox(height: 20),

            // Mes favoris
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Text('Mes favoris',
                style: GoogleFonts.fraunces(
                  fontSize: 18, fontWeight: FontWeight.w600, color: AppTokens.ink,
                ),
              ),
            ),

            SizedBox(
              height: 160,
              child: favoriteMeals.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Center(
                        child: Text('Aucun favori pour le moment',
                          style: GoogleFonts.inter(fontSize: 13, color: AppTokens.muted),
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                      itemCount: favoriteMeals.length,
                      itemBuilder: (_, i) => _FavoriteCard(meal: favoriteMeals[i]),
                    ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1, color: AppTokens.hairline),

            // Settings rows
            _SettingRow(label: 'Mon frigo', value: '8 ingrédients'),
            _SettingRow(label: 'Notifications'),
            _SettingRow(label: 'Aide', isLast: true),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
            style: GoogleFonts.fraunces(
              fontSize: 28, fontWeight: FontWeight.w700, color: AppTokens.coral,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
            style: GoogleFonts.inter(
              fontSize: 12, color: AppTokens.muted, fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Meal meal;
  const _FavoriteCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => RecipeScreen(meal: meal),
      )),
      child: Container(
        width: 118,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              child: SizedBox(
                height: 96, width: 118,
                child: meal.photo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: meal.photo,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppTokens.placeholder),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTokens.placeholder,
                          child: Center(child: Icon(Icons.image_not_supported_outlined,
                            color: AppTokens.placeholderDeep, size: 20)),
                        ),
                      )
                    : Container(
                        color: AppTokens.placeholder,
                        child: Center(child: Icon(Icons.image_not_supported_outlined,
                          color: AppTokens.placeholderDeep, size: 20)),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(meal.title,
              style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppTokens.ink,
              ),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(meal.time,
              style: GoogleFonts.inter(fontSize: 11, color: AppTokens.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool isLast;
  const _SettingRow({required this.label, this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 14.5, fontWeight: FontWeight.w500, color: AppTokens.ink,
                  ),
                ),
              ),
              if (value != null && value!.isNotEmpty)
                Text(value!,
                  style: GoogleFonts.inter(fontSize: 13, color: AppTokens.muted),
                ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1, thickness: 1, color: AppTokens.hairline,
            indent: 18, endIndent: 18,
          ),
      ],
    );
  }
}
