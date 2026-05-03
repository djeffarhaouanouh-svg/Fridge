import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/services/claude_service.dart';
import '../../meals/providers/meals_provider.dart';
import '../models/day_plan.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  int _selectedDayIndex = () {
    final wd = DateTime.now().weekday - 1;
    return wd.clamp(0, 5);
  }();

  static const _frDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
  static const _frMonths = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];
  static const _breakfasts = ['Granola', 'Tartines', 'Yaourt', 'Porridge', 'Smoothie', 'Œufs'];

  List<DateTime> get _weekDays {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(6, (i) => monday.add(Duration(days: i)));
  }

  int _weekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(startOfYear).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // Logique de génération conservée intégralement
  Future<void> _generatePlan() async {
    final photos = ref.read(capturedPhotosProvider);
    if (photos.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prends d\'abord une photo de ton frigo !',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    ref.read(planStatusProvider.notifier).state = PlanStatus.loading;
    try {
      final plan = await ClaudeService().generateWeekPlan(photos);
      ref.read(weekPlanProvider.notifier).state = plan;
      ref.read(planStatusProvider.notifier).state = PlanStatus.done;
    } catch (e) {
      ref.read(planStatusProvider.notifier).state = PlanStatus.error;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e', style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(planStatusProvider);
    final weekPlan = ref.watch(weekPlanProvider);
    final isLoading = status == PlanStatus.loading;
    final days = _weekDays;
    final weekNum = _weekNumber(days.first);
    final planMap = {for (final d in weekPlan) d.date: d};

    final startDay = days.first;
    final endDay = days.last;
    final dateRange =
        '${startDay.day} — ${endDay.day} ${_frMonths[startDay.month - 1]} ${startDay.year}';

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
                      child: Text('Ma semaine',
                        style: GoogleFonts.fraunces(
                          fontSize: 16, fontWeight: FontWeight.w600, color: AppTokens.ink,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 32, height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppTokens.coralSoft, shape: BoxShape.circle),
                    child: Icon(Icons.tune_rounded, size: 16, color: AppTokens.coral),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                children: [
                  // Sem. N
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: 'Sem. ',
                        style: GoogleFonts.fraunces(
                          fontSize: 26, fontWeight: FontWeight.w700, color: AppTokens.ink,
                        ),
                      ),
                      TextSpan(
                        text: '$weekNum',
                        style: GoogleFonts.fraunces(
                          fontSize: 26, fontWeight: FontWeight.w700, color: AppTokens.coral,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 2),
                  Text(dateRange,
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500, color: AppTokens.muted,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sélecteur de jours
                  SizedBox(
                    height: 64,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: days.length,
                      itemBuilder: (_, i) {
                        final isActive = i == _selectedDayIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDayIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive ? AppTokens.coral : AppTokens.surface,
                              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_frDays[i],
                                  style: GoogleFonts.inter(
                                    fontSize: 11, fontWeight: FontWeight.w600,
                                    color: isActive ? Colors.white : AppTokens.muted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text('${days[i].day}',
                                  style: GoogleFonts.fraunces(
                                    fontSize: 17, fontWeight: FontWeight.w700,
                                    color: isActive ? Colors.white : AppTokens.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // PETIT-DÉJ
                  _MealRow(
                    label: 'PETIT-DÉJ',
                    days: days,
                    frDays: _frDays,
                    meals: List.generate(
                      days.length, (i) => _breakfasts[i % _breakfasts.length],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // DÉJEUNER
                  _MealRow(
                    label: 'DÉJEUNER',
                    days: days,
                    frDays: _frDays,
                    meals: List.generate(days.length, (i) {
                      return planMap[_isoDate(days[i])]?.lunch.name ?? '';
                    }),
                  ),
                  const SizedBox(height: 20),

                  // DÎNER
                  _MealRow(
                    label: 'DÎNER',
                    days: days,
                    frDays: _frDays,
                    meals: List.generate(days.length, (i) {
                      return planMap[_isoDate(days[i])]?.dinner.name ?? '';
                    }),
                  ),
                  const SizedBox(height: 28),

                  // CTA
                  GlassButton(
                    label: 'Générer ma semaine avec mon frigo',
                    icon: Icons.auto_awesome,
                    color: GlassButtonColor.green,
                    size: GlassButtonSize.lg,
                    fullWidth: true,
                    onTap: isLoading ? null : _generatePlan,
                  ),

                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(child: CircularProgressIndicator(color: AppTokens.coral)),
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

class _MealRow extends StatelessWidget {
  final String label;
  final List<DateTime> days;
  final List<String> frDays;
  final List<String> meals;

  const _MealRow({
    required this.label,
    required this.days,
    required this.frDays,
    required this.meals,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: AppTokens.muted, letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 138,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: days.length + 1,
            itemBuilder: (_, i) {
              // Carte "+ Ajouter"
              if (i == days.length) {
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTokens.hairline, width: 1.5),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: Center(
                    child: Text('+ Ajouter',
                      style: GoogleFonts.inter(
                        fontSize: 12, color: AppTokens.muted, fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }

              final mealName = meals[i];
              final dayLabel = '${frDays[i].toUpperCase()} ${days[i].day}';

              return Container(
                width: 110,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppTokens.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image placeholder
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTokens.radiusMd),
                      ),
                      child: Container(
                        height: 80,
                        color: AppTokens.placeholder,
                        child: Center(
                          child: Icon(Icons.image_not_supported_outlined,
                            color: AppTokens.placeholderDeep, size: 22),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dayLabel,
                            style: GoogleFonts.inter(
                              fontSize: 9.5, fontWeight: FontWeight.w700, color: AppTokens.coral,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(mealName.isNotEmpty ? mealName : '—',
                            style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600, color: AppTokens.ink,
                            ),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
