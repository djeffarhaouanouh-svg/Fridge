import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Header
              Text(
                'Plan de la semaine',
                style: GoogleFonts.syne(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTokens.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Organise tes repas',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppTokens.muted,
                ),
              ),
              const SizedBox(height: 32),

              // Days list
              Expanded(
                child: ListView.builder(
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final days = [
                      'Lundi',
                      'Mardi',
                      'Mercredi',
                      'Jeudi',
                      'Vendredi',
                      'Samedi',
                      'Dimanche'
                    ];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DayCard(
                        day: days[index],
                        isEmpty: index > 2, // Mock: only first 3 days have meals
                      ),
                    );
                  },
                ),
              ),

              // Add button
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusMd),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Générer un plan',
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
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final String day;
  final bool isEmpty;

  const _DayCard({
    required this.day,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                day,
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.text,
                ),
              ),
              const Spacer(),
              if (!isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.accentDim,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '2 repas',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.accent,
                    ),
                  ),
                ),
            ],
          ),
          if (isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Aucun repas planifié',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTokens.muted,
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            _MealSlot(
              icon: '☀️',
              label: 'Déjeuner',
              meal: 'Pâtes à l\'ail & parmesan',
            ),
            const SizedBox(height: 8),
            _MealSlot(
              icon: '🌙',
              label: 'Dîner',
              meal: 'Bol de riz au poulet',
            ),
          ],
        ],
      ),
    );
  }
}

class _MealSlot extends StatelessWidget {
  final String icon;
  final String label;
  final String meal;

  const _MealSlot({
    required this.icon,
    required this.label,
    required this.meal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppTokens.muted,
                  ),
                ),
                Text(
                  meal,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
