import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/services/claude_service.dart';
import '../../../core/services/neon_service.dart';
import '../../../core/widgets/meal_image.dart';
import '../../meals/providers/meals_provider.dart';
import '../../meals/models/meal.dart';
import '../../meals/screens/recipe_screen.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  int _selectedDayIndex = 0;
  int _weekOffset = 0;

  final _dayScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSlotExtras());
  }

  Future<void> _loadSlotExtras() async {
    try {
      final extras = await NeonService().loadPlanSlotExtras();
      if (!mounted) return;
      final photos = <String, Uint8List>{};
      final analyses = <String, Map<String, dynamic>>{};
      for (final entry in extras.entries) {
        if (entry.value.photo != null) photos[entry.key] = entry.value.photo!;
        if (entry.value.analysis != null) analyses[entry.key] = entry.value.analysis!;
      }
      ref.read(planSlotPhotosProvider.notifier).state = photos;
      ref.read(planSlotAnalysisProvider.notifier).state = analyses;
    } catch (e) {
      debugPrint('_loadSlotExtras: $e');
    }
  }
  final _breakfastScrollController = ScrollController();
  final _lunchScrollController = ScrollController();
  final _snackScrollController = ScrollController();
  final _dinnerScrollController = ScrollController();

  static const _weekdayToFr = {
    1: 'Lun', 2: 'Mar', 3: 'Mer', 4: 'Jeu', 5: 'Ven', 6: 'Sam', 7: 'Dim',
  };

  static const _frMonths = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  List<DateTime> get _days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekStart = monday.add(Duration(days: _weekOffset * 7));
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
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

  void _prevWeek() => setState(() { _weekOffset--; _selectedDayIndex = 0; });
  void _nextWeek() => setState(() { _weekOffset++; _selectedDayIndex = 0; });

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
    if (_snackScrollController.hasClients) {
      _snackScrollController.animateTo(cardOffset, duration: dur, curve: curve);
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
    _snackScrollController.dispose();
    _dinnerScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(planStatusProvider);
    final weekPlan = ref.watch(weekPlanProvider);
    final selections = ref.watch(planMealSelectionsProvider);
    final slotPhotos = ref.watch(planSlotPhotosProvider);
    final slotAnalyses = ref.watch(planSlotAnalysisProvider);
    final isLoading = status == PlanStatus.loading;
    final days = _days;
    final planMap = {for (final d in weekPlan) d.date: d};
    final frDays = days.map((d) => _weekdayToFr[d.weekday]!).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTokens.ink;
    final mutedColor = isDark ? Colors.white70 : AppTokens.muted;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: AppHeader(brand: true)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WeekSelectorCard(
                    days: days,
                    frDays: frDays,
                    selectedIndex: _selectedDayIndex,
                    frMonths: _frMonths,
                    onDayTap: _selectDay,
                    onPrev: _prevWeek,
                    onNext: _nextWeek,
                    isDark: isDark,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                  ),
                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      'Clic sur les vignettes, planifie tes repas et suis tes calories',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppTokens.inkSoft,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _MealRow(
                    label: 'PETIT DÉJEUNER',
                    mealType: 'Petit déjeuner',
                    days: days,
                    frDays: frDays,
                    slotPhotos: slotPhotos,
                    slotAnalyses: slotAnalyses,
                    meals: List.generate(days.length, (i) {
                      final key = '${_isoDate(days[i])}_Petit déjeuner';
                      return selections[key]?.title ?? '';
                    }),
                    selectedMeals: List.generate(days.length, (i) {
                      return selections['${_isoDate(days[i])}_Petit déjeuner'];
                    }),
                    scrollController: _breakfastScrollController,
                    selectedDayIndex: _selectedDayIndex,
                    onCardTap: (i) => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => PlanMealDetailScreen(
                        day: days[i],
                        dayLabel: '${frDays[i]} ${days[i].day}',
                        mealType: 'Petit déjeuner',
                        mealName: '',
                      ),
                    )),
                  ),
                  const SizedBox(height: 16),

                  _MealRow(
                    label: 'DÉJEUNER',
                    mealType: 'Déjeuner',
                    days: days,
                    frDays: frDays,
                    slotPhotos: slotPhotos,
                    slotAnalyses: slotAnalyses,
                    meals: List.generate(days.length, (i) {
                      final key = '${_isoDate(days[i])}_Déjeuner';
                      return selections[key]?.title ?? planMap[_isoDate(days[i])]?.lunch.name ?? '';
                    }),
                    selectedMeals: List.generate(days.length, (i) {
                      return selections['${_isoDate(days[i])}_Déjeuner'];
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
                    label: 'EN CAS',
                    mealType: 'En cas',
                    days: days,
                    frDays: frDays,
                    slotPhotos: slotPhotos,
                    slotAnalyses: slotAnalyses,
                    meals: List.generate(days.length, (i) {
                      final key = '${_isoDate(days[i])}_En cas';
                      return selections[key]?.title ?? '';
                    }),
                    selectedMeals: List.generate(days.length, (i) {
                      return selections['${_isoDate(days[i])}_En cas'];
                    }),
                    scrollController: _snackScrollController,
                    selectedDayIndex: _selectedDayIndex,
                    onCardTap: (i) => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => PlanMealDetailScreen(
                        day: days[i],
                        dayLabel: '${frDays[i]} ${days[i].day}',
                        mealType: 'En cas',
                        mealName: '',
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),

                  _MealRow(
                    label: 'DÎNER',
                    mealType: 'Dîner',
                    days: days,
                    frDays: frDays,
                    slotPhotos: slotPhotos,
                    slotAnalyses: slotAnalyses,
                    meals: List.generate(days.length, (i) {
                      final key = '${_isoDate(days[i])}_Dîner';
                      return selections[key]?.title ?? planMap[_isoDate(days[i])]?.dinner.name ?? '';
                    }),
                    selectedMeals: List.generate(days.length, (i) {
                      return selections['${_isoDate(days[i])}_Dîner'];
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
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(child: CircularProgressIndicator(color: AppTokens.coral)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Carte sélecteur de semaine ─────────────────────────────────────────────

class _WeekSelectorCard extends StatelessWidget {
  final List<DateTime> days;
  final List<String> frDays;
  final int selectedIndex;
  final List<String> frMonths;
  final void Function(int) onDayTap;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool isDark;
  final Color titleColor;
  final Color mutedColor;

  const _WeekSelectorCard({
    required this.days,
    required this.frDays,
    required this.selectedIndex,
    required this.frMonths,
    required this.onDayTap,
    required this.onPrev,
    required this.onNext,
    required this.isDark,
    required this.titleColor,
    required this.mutedColor,
  });

  String _rangeTitle() {
    final s = days.first;
    final e = days.last;
    if (s.month == e.month) {
      return 'du ${s.day} au ${e.day} ${frMonths[s.month - 1]}';
    }
    return 'du ${s.day} ${frMonths[s.month - 1]} au ${e.day} ${frMonths[e.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: isDark ? Colors.white12 : AppTokens.hairline),
      ),
      child: Column(
        children: [
          // ── Navigation header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
            child: Row(
              children: [
                _NavArrow(icon: Icons.chevron_left, onTap: onPrev),
                Expanded(
                  child: Text(
                    _rangeTitle(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                ),
                _NavArrow(icon: Icons.chevron_right, onTap: onNext),
              ],
            ),
          ),

          // ── Days grid ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: List.generate(7, (i) {
                final isActive = i == selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDayTap(i),
                    child: Column(
                      children: [
                        Text(
                          frDays[i],
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isActive ? AppTokens.coral : mutedColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isActive ? AppTokens.coral : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                          ),
                          child: Center(
                            child: Text(
                              '${days[i].day}',
                              style: GoogleFonts.fraunces(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isActive ? Colors.white : titleColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: const BoxDecoration(
          color: AppTokens.coral,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─── Rangée repas ────────────────────────────────────────────────────────────

class _MealRow extends StatelessWidget {
  final String label;
  final String mealType;
  final List<DateTime> days;
  final List<String> frDays;
  final List<String> meals;
  final List<Meal?> selectedMeals;
  final ScrollController scrollController;
  final int selectedDayIndex;
  final void Function(int)? onCardTap;
  final Map<String, Uint8List> slotPhotos;
  final Map<String, Map<String, dynamic>> slotAnalyses;

  const _MealRow({
    required this.label,
    required this.mealType,
    required this.days,
    required this.frDays,
    required this.meals,
    required this.selectedMeals,
    required this.scrollController,
    required this.selectedDayIndex,
    required this.slotPhotos,
    required this.slotAnalyses,
    this.onCardTap,
  });

  static String _slotKey(DateTime day, String mealType) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}_$mealType';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTokens.ink;
    final mutedColor = isDark ? Colors.white70 : AppTokens.muted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: mutedColor, letterSpacing: 0.5,
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
                    color: isDark ? const Color(0xFF1E1E1E) : null,
                    border: Border.all(color: isDark ? Colors.white12 : AppTokens.hairline, width: 1.5),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: Center(
                    child: Text('+ Ajouter',
                      style: GoogleFonts.inter(
                        fontSize: 12, color: mutedColor, fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }

              final isSelected = i == selectedDayIndex;
              final mealName = meals[i];
              final dayLabel = '${frDays[i].toUpperCase()} ${days[i].day}';
              final selectedMeal = selectedMeals[i];

              return GestureDetector(
                onTap: () => onCardTap?.call(i),
                child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 110,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF3A2A26) : AppTokens.coralSoft)
                      : (isDark ? const Color(0xFF1E1E1E) : AppTokens.surface),
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
                      child: Builder(builder: (_) {
                        final customPhoto = slotPhotos[_slotKey(days[i], mealType)];
                        if (selectedMeal != null) {
                          return SizedBox(height: 80, width: 110, child: MealImage(photo: selectedMeal.photo, fallbackKey: selectedMeal.title));
                        }
                        if (customPhoto != null) {
                          return SizedBox(height: 80, width: 110, child: Image.memory(customPhoto, fit: BoxFit.cover));
                        }
                        return Container(
                          height: 80,
                          color: AppTokens.placeholder,
                          child: Center(
                            child: Icon(Icons.image_not_supported_outlined,
                              color: AppTokens.placeholderDeep, size: 22),
                          ),
                        );
                      }),
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
                          Builder(builder: (_) {
                            final analysis = slotAnalyses[_slotKey(days[i], mealType)];
                            final analysisKcal = analysis?['kcal'];
                            final mealKcal = selectedMeals[i]?.kcal;
                            final kcal = analysisKcal ?? (mealKcal != null && mealKcal > 0 ? mealKcal : null);
                            final displayText = kcal != null
                                ? '$kcal kcal'
                                : (mealName.isNotEmpty ? mealName : '—');
                            return Text(displayText,
                              style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: kcal != null ? AppTokens.coral : titleColor,
                              ),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            );
                          }),
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
  Uint8List? _pickedPhoto;
  Map<String, dynamic>? _analysis;
  bool _analyzing = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _slotKey;
      final savedMeal = ref.read(planMealSelectionsProvider)[key];
      final savedPhoto = ref.read(planSlotPhotosProvider)[key];
      final savedAnalysis = ref.read(planSlotAnalysisProvider)[key];
      setState(() {
        if (savedMeal != null) _selected = savedMeal;
        if (savedPhoto != null) _pickedPhoto = savedPhoto;
        if (savedAnalysis != null) _analysis = savedAnalysis;
      });
    });
  }

  String get _slotKey {
    final d = widget.day;
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}_${widget.mealType}';
  }

  void _selectMeal(Meal meal) {
    setState(() { _selected = meal; _pickedPhoto = null; _analysis = null; });
    final current = Map<String, Meal>.from(ref.read(planMealSelectionsProvider));
    current[_slotKey] = meal;
    ref.read(planMealSelectionsProvider.notifier).state = current;
    // Retire la photo custom si une recette est choisie
    final photos = Map<String, Uint8List>.from(ref.read(planSlotPhotosProvider));
    photos.remove(_slotKey);
    ref.read(planSlotPhotosProvider.notifier).state = photos;
  }

  void _removeMeal() {
    setState(() => _selected = null);
    final current = Map<String, Meal>.from(ref.read(planMealSelectionsProvider));
    current.remove(_slotKey);
    ref.read(planMealSelectionsProvider.notifier).state = current;
  }

  void _removePhoto() {
    setState(() { _pickedPhoto = null; _analysis = null; _analyzing = false; });
    final photos = Map<String, Uint8List>.from(ref.read(planSlotPhotosProvider));
    photos.remove(_slotKey);
    ref.read(planSlotPhotosProvider.notifier).state = photos;
    final analyses = Map<String, Map<String, dynamic>>.from(ref.read(planSlotAnalysisProvider));
    analyses.remove(_slotKey);
    ref.read(planSlotAnalysisProvider.notifier).state = analyses;
    NeonService().removePlanSlotPhoto(_slotKey).catchError((e) {
      debugPrint('removePlanSlotPhoto: $e');
      return null;
    });
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2A2420),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            _SourceTile(icon: Icons.camera_alt_outlined, label: 'Prendre une photo',
              onTap: () => Navigator.pop(context, ImageSource.camera)),
            const SizedBox(height: 12),
            _SourceTile(icon: Icons.photo_library_outlined, label: 'Choisir dans la galerie',
              onTap: () => Navigator.pop(context, ImageSource.gallery)),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final photo = await _picker.pickImage(source: source, imageQuality: 80);
    if (photo == null || !mounted) return;
    final bytes = await photo.readAsBytes();

    setState(() { _pickedPhoto = bytes; _selected = null; _analysis = null; _analyzing = true; });

    final photos = Map<String, Uint8List>.from(ref.read(planSlotPhotosProvider));
    photos[_slotKey] = bytes;
    ref.read(planSlotPhotosProvider.notifier).state = photos;

    final sels = Map<String, Meal>.from(ref.read(planMealSelectionsProvider));
    sels.remove(_slotKey);
    ref.read(planMealSelectionsProvider.notifier).state = sels;

    try {
      final result = await ClaudeService().analyzePhoto(bytes);
      if (!mounted) return;
      setState(() { _analysis = result; _analyzing = false; });
      final analyses = Map<String, Map<String, dynamic>>.from(ref.read(planSlotAnalysisProvider));
      analyses[_slotKey] = result;
      ref.read(planSlotAnalysisProvider.notifier).state = analyses;
      NeonService().savePlanSlotPhoto(_slotKey, bytes, result).catchError((e) {
        debugPrint('savePlanSlotPhoto: $e');
        return null;
      });
    } catch (_) {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  static const _frMonths = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  @override
  Widget build(BuildContext context) {
    final allMeals = ref.watch(mealsProvider);
    final favoriteMeals = ref.watch(favoriteMealsProvider);
    final selections = ref.watch(planMealSelectionsProvider);
    final fullDate = '${widget.day.day} ${_frMonths[widget.day.month - 1]} ${widget.day.year}';
    final meal = _selected;
    final takenIds = selections.entries
        .where((e) => e.key != _slotKey)
        .map((e) => e.value.id)
        .toSet();
    final availableFavorites =
        favoriteMeals.where((m) => !takenIds.contains(m.id)).toList();
    final availableAllMeals =
        allMeals.where((m) => !takenIds.contains(m.id)).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppTokens.ink,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text(widget.mealType,
                            style: GoogleFonts.fraunces(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : AppTokens.ink,
                            ),
                          ),
                          Text(fullDate,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : AppTokens.muted,
                              fontWeight: FontWeight.w500,
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
                    child: Stack(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _pickedPhoto != null
                              ? SizedBox(
                                  key: const ValueKey('custom'),
                                  height: 200,
                                  width: double.infinity,
                                  child: Image.memory(_pickedPhoto!, fit: BoxFit.cover),
                                )
                              : meal != null
                                  ? SizedBox(
                                      key: ValueKey(meal.id),
                                      height: 200,
                                      width: double.infinity,
                                      child: MealImage(photo: meal.photo, fallbackKey: meal.title),
                                    )
                                  : GestureDetector(
                                      key: const ValueKey('empty'),
                                      onTap: _pickPhoto,
                                      child: Container(
                                        height: 200,
                                        color: AppTokens.surface,
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.add_circle_outline,
                                                color: AppTokens.coral,
                                                size: 36),
                                              const SizedBox(height: 10),
                                              RichText(
                                                textAlign: TextAlign.center,
                                                text: TextSpan(
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context).brightness == Brightness.dark
                                                        ? Colors.white70 : AppTokens.ink,
                                                  ),
                                                  children: [
                                                    const TextSpan(text: 'Ajoute une '),
                                                    TextSpan(text: 'photo', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTokens.coral)),
                                                    const TextSpan(text: ' ou choisis un '),
                                                    TextSpan(text: 'plat', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTokens.coral)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                        ),
                        if (_pickedPhoto != null || meal != null)
                          Positioned(
                            top: 10, right: 10,
                            child: GestureDetector(
                              onTap: _pickedPhoto != null ? _removePhoto : _removeMeal,
                              child: Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600, shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.delete_outline, size: 22, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Analyse IA
                  if (_analyzing) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTokens.coral)),
                    const SizedBox(height: 8),
                    Center(child: Text('Analyse du plat en cours…',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTokens.muted))),
                  ],
                  if (_analysis != null && !_analyzing) ...[
                    const SizedBox(height: 16),
                    _AnalysisCard(analysis: _analysis!),
                  ],

                  // Données du plat sélectionné
                  if (meal != null) ...[
                    const SizedBox(height: 16),
                    Text(meal.title,
                      style: GoogleFonts.fraunces(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTokens.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MealInfoCard(meal: meal),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        label: 'Commencer',
                        icon: Icons.play_arrow_rounded,
                        color: GlassButtonColor.coral,
                        size: GlassButtonSize.md,
                        fullWidth: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RecipeScreen(meal: meal, fromPlan: true)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  if (meal == null && _pickedPhoto == null && _analysis == null && availableFavorites.isNotEmpty) ...[
                    _SectionTitle(title: 'Mes favoris'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableFavorites.length,
                        itemBuilder: (_, i) => _MealPickCard(
                          meal: availableFavorites[i],
                          isSelected: _selected?.id == availableFavorites[i].id,
                          onTap: () => _selectMeal(availableFavorites[i]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (meal == null && _pickedPhoto == null && _analysis == null && availableAllMeals.isNotEmpty) ...[
                    _SectionTitle(title: 'Plats de mon frigo'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableAllMeals.length,
                        itemBuilder: (_, i) => _MealPickCard(
                          meal: availableAllMeals[i],
                          isSelected: _selected?.id == availableAllMeals[i].id,
                          onTap: () => _selectMeal(availableAllMeals[i]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (meal == null &&
                      _pickedPhoto == null &&
                      _analysis == null &&
                      availableFavorites.isEmpty &&
                      availableAllMeals.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: Text(
                          'Toutes les recettes sont deja planifiees',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : AppTokens.muted,
                          ),
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

class _MealInfoCard extends StatelessWidget {
  final Meal meal;
  const _MealInfoCard({required this.meal});

  static String _cap(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E1E1E) : AppTokens.surface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: isDark ? Colors.white12 : AppTokens.hairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MacroTile(label: 'Calories', value: '${meal.kcal}', unit: 'kcal', highlight: true),
          _MacroTile(label: 'Durée', value: meal.time, unit: ''),
          _MacroTile(label: 'Difficulté', value: _cap(meal.difficulty), unit: ''),
          _MacroTile(label: 'Protéines', value: _cap(meal.protein), unit: ''),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(title,
      style: GoogleFonts.fraunces(
        fontSize: 17, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTokens.ink,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? Colors.white70 : AppTokens.muted),
          const SizedBox(width: 5),
          Text(label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : AppTokens.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTokens.coral, size: 22),
            const SizedBox(width: 14),
            Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final Map<String, dynamic> analysis;
  const _AnalysisCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : AppTokens.ink;
    final muted = isDark ? Colors.white70 : AppTokens.muted;
    final surface = isDark ? const Color(0xFF1E1E1E) : AppTokens.surface;

    final dishName = (analysis['dish_name'] ?? 'Plat analysé').toString();
    final portion = (analysis['portion'] ?? '').toString();
    final kcal = analysis['kcal'] ?? 0;
    final proteins = analysis['proteins'] ?? 0;
    final carbs = analysis['carbs'] ?? 0;
    final fats = analysis['fats'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: isDark ? Colors.white12 : AppTokens.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dishName,
            style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
          if (portion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(portion, style: GoogleFonts.inter(fontSize: 12.5, color: muted)),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroTile(label: 'Calories', value: '$kcal', unit: 'kcal', highlight: true),
              _MacroTile(label: 'Protéines', value: '$proteins', unit: 'g'),
              _MacroTile(label: 'Glucides', value: '$carbs', unit: 'g'),
              _MacroTile(label: 'Lipides', value: '$fats', unit: 'g'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool highlight;
  const _MacroTile({required this.label, required this.value, required this.unit, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : AppTokens.ink;
    final muted = isDark ? Colors.white60 : AppTokens.muted;
    return Column(
      children: [
        Text('$value $unit',
          style: GoogleFonts.fraunces(
            fontSize: highlight ? 20 : 16,
            fontWeight: FontWeight.w700,
            color: highlight ? AppTokens.coral : ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: muted, fontWeight: FontWeight.w500)),
      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF3A2A26) : AppTokens.coralSoft)
              : (isDark ? const Color(0xFF1E1E1E) : AppTokens.surface),
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
                  Text(meal.title,
                    style: GoogleFonts.inter(
                      fontSize: 11.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTokens.ink,
                    ),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.schedule_outlined, size: 10, color: isDark ? Colors.white70 : AppTokens.muted),
                      const SizedBox(width: 3),
                      Text(meal.time,
                        style: GoogleFonts.inter(fontSize: 10.5, color: isDark ? Colors.white70 : AppTokens.muted),
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
