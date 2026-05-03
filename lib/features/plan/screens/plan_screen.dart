import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/services/claude_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../meals/providers/meals_provider.dart';
import '../../meals/models/meal.dart';

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
        bottom: false,
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
                  const SizedBox(width: 32),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
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
                    onCardTap: (i) => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => PlanMealDetailScreen(
                        day: days[i],
                        dayLabel: '${frDays[i]} ${days[i].day}',
                        mealType: 'Petit-déj',
                        mealName: _breakfasts[i % _breakfasts.length],
                      ),
                    )),
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
                    onCardTap: (i) => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => PlanMealDetailScreen(
                        day: days[i],
                        dayLabel: '${frDays[i]} ${days[i].day}',
                        mealType: 'Déjeuner',
                        mealName: planMap[_isoDate(days[i])]?.lunch.name ?? '',
                      ),
                    )),
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
                    onCardTap: (i) => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => PlanMealDetailScreen(
                        day: days[i],
                        dayLabel: '${frDays[i]} ${days[i].day}',
                        mealType: 'Dîner',
                        mealName: planMap[_isoDate(days[i])]?.dinner.name ?? '',
                      ),
                    )),
                  ),
                  const SizedBox(height: 28),

                  Center(
                    child: GlassButton(
                    label: 'Générer ma semaine',
                    icon: Icons.auto_awesome,
                    color: GlassButtonColor.coral,
                    size: GlassButtonSize.md,
                    fullWidth: false,
                    onTap: isLoading ? null : _generatePlan,
                  ),
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
  final void Function(int)? onCardTap;

  const _MealRow({
    required this.label,
    required this.days,
    required this.frDays,
    required this.meals,
    required this.scrollController,
    required this.selectedDayIndex,
    this.onCardTap,
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

              return GestureDetector(
                onTap: () => onCardTap?.call(i),
                child: AnimatedContainer(
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
              ),
            );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Page détail d'un créneau ───────────────────────────────────────────────

class PlanMealDetailScreen extends ConsumerStatefulWidget {
  final DateTime day;
  final String dayLabel;
  final String mealType;
  final String mealName;

  const PlanMealDetailScreen({
    super.key,
    required this.day,
    required this.dayLabel,
    required this.mealType,
    required this.mealName,
  });

  @override
  ConsumerState<PlanMealDetailScreen> createState() => _PlanMealDetailScreenState();
}

class _PlanMealDetailScreenState extends ConsumerState<PlanMealDetailScreen> {
  Meal? _selected;

  static const _frMonths = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  @override
  Widget build(BuildContext context) {
    final allMeals = ref.watch(mealsProvider);
    final favoriteMeals = ref.watch(favoriteMealsProvider);
    final fullDate = '${widget.day.day} ${_frMonths[widget.day.month - 1]} ${widget.day.year}';
    final meal = _selected;

    return Scaffold(
      backgroundColor: AppTokens.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppTokens.ink),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text(widget.mealType,
                            style: GoogleFonts.fraunces(
                              fontSize: 16, fontWeight: FontWeight.w600, color: AppTokens.ink,
                            ),
                          ),
                          Text(fullDate,
                            style: GoogleFonts.inter(
                              fontSize: 11.5, color: AppTokens.muted, fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
                children: [
                  // Emplacement photo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: meal != null
                          ? SizedBox(
                              key: ValueKey(meal.id),
                              height: 200,
                              width: double.infinity,
                              child: meal.photo.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: meal.photo,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(color: AppTokens.placeholder),
                                      errorWidget: (_, __, ___) => Container(color: AppTokens.placeholder),
                                    )
                                  : Container(
                                      color: AppTokens.placeholder,
                                      child: const Center(child: Icon(
                                        Icons.restaurant_outlined,
                                        color: AppTokens.placeholderDeep, size: 48,
                                      )),
                                    ),
                            )
                          : Container(
                              key: const ValueKey('empty'),
                              height: 200,
                              color: AppTokens.surface,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_circle_outline,
                                      color: AppTokens.muted, size: 36),
                                    const SizedBox(height: 10),
                                    Text('Choisis un plat ci-dessous',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5, color: AppTokens.muted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),

                  // Données du plat sélectionné
                  if (meal != null) ...[
                    const SizedBox(height: 16),
                    Text(meal.title,
                      style: GoogleFonts.fraunces(
                        fontSize: 20, fontWeight: FontWeight.w700, color: AppTokens.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _InfoChip(icon: Icons.schedule_outlined, label: meal.time),
                        const SizedBox(width: 10),
                        _InfoChip(icon: Icons.local_fire_department_outlined, label: '${meal.kcal} kcal'),
                        const SizedBox(width: 10),
                        _InfoChip(icon: Icons.bar_chart_outlined, label: meal.difficulty),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _InfoChip(icon: Icons.fitness_center_outlined, label: 'Protéines ${meal.protein}'),
                  ],

                  const SizedBox(height: 28),

                  if (favoriteMeals.isNotEmpty) ...[
                    _SectionTitle(title: 'Mes favoris'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: favoriteMeals.length,
                        itemBuilder: (_, i) => _MealPickCard(
                          meal: favoriteMeals[i],
                          isSelected: _selected?.id == favoriteMeals[i].id,
                          onTap: () => setState(() => _selected = favoriteMeals[i]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (allMeals.isNotEmpty) ...[
                    _SectionTitle(title: 'Plats de mon frigo'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: allMeals.length,
                        itemBuilder: (_, i) => _MealPickCard(
                          meal: allMeals[i],
                          isSelected: _selected?.id == allMeals[i].id,
                          onTap: () => setState(() => _selected = allMeals[i]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (favoriteMeals.isEmpty && allMeals.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: Text(
                          'Scanne ton frigo pour voir des plats ici',
                          style: GoogleFonts.inter(fontSize: 13.5, color: AppTokens.muted),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
      style: GoogleFonts.fraunces(
        fontSize: 17, fontWeight: FontWeight.w600, color: AppTokens.ink,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTokens.muted),
          const SizedBox(width: 5),
          Text(label,
            style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w500, color: AppTokens.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealPickCard extends StatelessWidget {
  final Meal meal;
  final bool isSelected;
  final VoidCallback onTap;
  const _MealPickCard({required this.meal, required this.onTap, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTokens.coralSoft : AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: isSelected
              ? Border.all(color: AppTokens.coral, width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTokens.radiusMd),
              ),
              child: SizedBox(
                height: 100, width: 130,
                child: meal.photo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: meal.photo,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppTokens.placeholder),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTokens.placeholder,
                          child: const Center(child: Icon(
                            Icons.image_not_supported_outlined,
                            color: AppTokens.placeholderDeep, size: 20,
                          )),
                        ),
                      )
                    : Container(
                        color: AppTokens.placeholder,
                        child: const Center(child: Icon(
                          Icons.restaurant_outlined,
                          color: AppTokens.placeholderDeep, size: 24,
                        )),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.title,
                    style: GoogleFonts.inter(
                      fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTokens.ink,
                    ),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined, size: 10, color: AppTokens.muted),
                      const SizedBox(width: 3),
                      Text(meal.time,
                        style: GoogleFonts.inter(fontSize: 10.5, color: AppTokens.muted),
                      ),
                    ],
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
