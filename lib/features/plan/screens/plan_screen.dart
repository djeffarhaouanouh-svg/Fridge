import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/services/claude_service.dart';
import '../../meals/providers/meals_provider.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  int _selectedDayIndex = 0;

  final _dayScrollController = ScrollController();
  final _breakfastScrollController = ScrollController();
  final _lunchScrollController = ScrollController();
  final _dinnerScrollController = ScrollController();

  static const _weekdayToFr = {
    1: 'Lun', 2: 'Mar', 3: 'Mer', 4: 'Jeu', 5: 'Ven', 6: 'Sam', 7: 'Dim',
  };

  static const _frMonths = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  static const _breakfasts = ['Granola', 'Tartines', 'Yaourt', 'Porridge', 'Smoothie', 'Œufs', 'Crêpes'];

  List<DateTime> get _days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) => today.add(Duration(days: i)));
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

  void _selectDay(int i) {
    setState(() => _selectedDayIndex = i);
    _scrollToDay(i);
  }

  void _scrollToDay(int i) {
    final screenW = MediaQuery.of(context).size.width;
    final contentW = screenW - 36;

    // Day pill: ~58px wide + 8px gap
    const pillW = 58.0;
    const pillGap = 8.0;
    final pillOffset = ((i * (pillW + pillGap)) - (contentW - pillW) / 2)
        .clamp(0.0, double.maxFinite);

    // Meal card: 110px wide + 10px gap
    const cardW = 110.0;
    const cardGap = 10.0;
    final cardOffset = ((i * (cardW + cardGap)) - (contentW - cardW) / 2)
        .clamp(0.0, double.maxFinite);

    const dur = Duration(milliseconds: 300);
    const curve = Curves.easeInOut;

    if (_dayScrollController.hasClients) {
      _dayScrollController.animateTo(pillOffset, duration: dur, curve: curve);
    }
    if (_breakfastScrollController.hasClients) {
      _breakfastScrollController.animateTo(cardOffset, duration: dur, curve: curve);
    }
    if (_lunchScrollController.hasClients) {
      _lunchScrollController.animateTo(cardOffset, duration: dur, curve: curve);
    }
    if (_dinnerScrollController.hasClients) {
      _dinnerScrollController.animateTo(cardOffset, duration: dur, curve: curve);
    }
  }

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
  void dispose() {
    _dayScrollController.dispose();
    _breakfastScrollController.dispose();
    _lunchScrollController.dispose();
    _dinnerScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(planStatusProvider);
    final weekPlan = ref.watch(weekPlanProvider);
    final isLoading = status == PlanStatus.loading;
    final days = _days;
    final weekNum = _weekNumber(days.first);
    final planMap = {for (final d in weekPlan) d.date: d};
    final frDays = days.map((d) => _weekdayToFr[d.weekday]!).toList();

    final start = days.first;
    final end = days.last;
    final dateRange = start.month == end.month
        ? '${start.day} — ${end.day} ${_frMonths[start.month - 1]} ${start.year}'
        : '${start.day} ${_frMonths[start.month - 1]} — ${end.day} ${_frMonths[end.month - 1]} ${end.year}';

    return Scaffold(
      backgroundColor: AppTokens.paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppTokens.ink),
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
                    decoration: const BoxDecoration(
                      color: AppTokens.coralSoft, shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune_rounded, size: 16, color: AppTokens.coral),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                children: [
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
                      controller: _dayScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: days.length,
                      itemBuilder: (_, i) {
                        final isActive = i == _selectedDayIndex;
                        return GestureDetector(
                          onTap: () => _selectDay(i),
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
                                Text(frDays[i],
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

                  _MealRow(
                    label: 'PETIT-DÉJ',
                    days: days,
                    frDays: frDays,
                    meals: List.generate(days.length, (i) => _breakfasts[i % _breakfasts.length]),
                    scrollController: _breakfastScrollController,
                    selectedDayIndex: _selectedDayIndex,
                  ),
                  const SizedBox(height: 20),

                  _MealRow(
                    label: 'DÉJEUNER',
                    days: days,
                    frDays: frDays,
                    meals: List.generate(days.length, (i) {
                      return planMap[_isoDate(days[i])]?.lunch.name ?? '';
                    }),
                    scrollController: _lunchScrollController,
                    selectedDayIndex: _selectedDayIndex,
                  ),
                  const SizedBox(height: 20),

                  _MealRow(
                    label: 'DÎNER',
                    days: days,
                    frDays: frDays,
                    meals: List.generate(days.length, (i) {
                      return planMap[_isoDate(days[i])]?.dinner.name ?? '';
                    }),
                    scrollController: _dinnerScrollController,
                    selectedDayIndex: _selectedDayIndex,
                  ),
                  const SizedBox(height: 28),

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
  final ScrollController scrollController;
  final int selectedDayIndex;

  const _MealRow({
    required this.label,
    required this.days,
    required this.frDays,
    required this.meals,
    required this.scrollController,
    required this.selectedDayIndex,
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
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: days.length + 1,
            itemBuilder: (_, i) {
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

              final isSelected = i == selectedDayIndex;
              final mealName = meals[i];
              final dayLabel = '${frDays[i].toUpperCase()} ${days[i].day}';

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 110,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTokens.coralSoft : AppTokens.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: isSelected
                      ? Border.all(color: AppTokens.coral.withValues(alpha: 0.3), width: 1)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              fontSize: 9.5, fontWeight: FontWeight.w700,
                              color: AppTokens.coral,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(mealName.isNotEmpty ? mealName : '—',
                            style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: AppTokens.ink,
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
