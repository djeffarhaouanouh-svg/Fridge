import 'dart:math';
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
import '../../home/providers/daily_hero_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/day_plan.dart';

/// Clé stockage créneau plan : `YYYY-MM-DD_Type`.
String planSlotStorageKey(DateTime day, String mealType) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}_$mealType';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  int? _rangeStart;
  int? _rangeEnd;
  int _weekOffset = 0;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final idx = _days.indexWhere((d) => d == today);
    if (idx >= 0) _rangeStart = idx;
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
    await _loadTodayConsumed();
  }

  Future<void> _loadTodayConsumed() async {
    try {
      final data = await NeonService().loadTodayConsumed();
      if (!mounted) return;
      ref.read(todayConsumedProvider.notifier).state = data;
    } catch (e) {
      debugPrint('_loadTodayConsumed: $e');
    }
  }

  static const _weekdayToFr = {
    1: 'Lun', 2: 'Mar', 3: 'Mer', 4: 'Jeu', 5: 'Ven', 6: 'Sam', 7: 'Dim',
  };

  static const _weekdayLongFr = {
    1: 'Lundi',
    2: 'Mardi',
    3: 'Mercredi',
    4: 'Jeudi',
    5: 'Vendredi',
    6: 'Samedi',
    7: 'Dimanche',
  };

  static const _slotDefs = [
    ('Petit déjeuner', 'Petit-déjeuner'),
    ('Déjeuner', 'Déjeuner'),
    ('En cas', 'En cas'),
    ('Dîner', 'Dîner'),
  ];

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

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  void _handleDayTap(int i) {
    setState(() {
      if (_rangeStart == null || _rangeEnd != null) {
        _rangeStart = i;
        _rangeEnd = null;
      } else {
        if (i == _rangeStart) {
          _rangeEnd = i;
        } else if (i < _rangeStart!) {
          _rangeEnd = _rangeStart;
          _rangeStart = i;
        } else {
          _rangeEnd = i;
        }
      }
    });
  }

  void _prevWeek() => setState(() { _weekOffset--; _rangeStart = null; _rangeEnd = null; });
  void _nextWeek() => setState(() { _weekOffset++; _rangeStart = null; _rangeEnd = null; });

  List<DateTime> get _visibleDays {
    final start = _rangeStart;
    if (start == null) return [];
    final end = _rangeEnd ?? start;
    final allDays = _days;
    return [for (int i = start; i <= end; i++) allDays[i]];
  }

  String _defaultPlanMealName(String iso, String mealType, Map<String, DayPlan> planByDate) {
    final dp = planByDate[iso];
    if (dp == null) return '';
    if (mealType == 'Déjeuner') return dp.lunch.name;
    if (mealType == 'Dîner') return dp.dinner.name;
    return '';
  }

  String _slotLineTitle(
    DateTime day,
    String mealType,
    Map<String, Meal> selections,
    Map<String, DayPlan> planByDate,
    Map<String, Map<String, dynamic>> slotAnalyses,
  ) {
    final key = planSlotStorageKey(day, mealType);
    final sel = selections[key];
    if (sel != null && sel.title.isNotEmpty) return sel.title;
    final iso = _isoDate(day);
    final fromPlan = _defaultPlanMealName(iso, mealType, planByDate);
    if (fromPlan.isNotEmpty) return fromPlan;
    final dish = slotAnalyses[key]?['dish_name'] as String?;
    if (dish != null && dish.isNotEmpty) return dish;
    return '';
  }

  void _openSlotEditor(DateTime day, String mealType, Map<String, DayPlan> planByDate) {
    final iso = _isoDate(day);
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PlanMealDetailScreen(
        day: day,
        dayLabel: '${day.day} ${_frMonths[day.month - 1]}',
        mealType: mealType,
        mealName: _defaultPlanMealName(iso, mealType, planByDate),
      ),
    )).then((_) => _loadTodayConsumed());
  }

  void _openAddSlotMenu(DateTime day, Map<String, DayPlan> planByDate) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    'Ajouter un repas',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                for (final pair in _slotDefs)
                  ListTile(
                    title: Text(pair.$2, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openSlotEditor(day, pair.$1, planByDate);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final status = ref.watch(planStatusProvider);
    final weekPlan = ref.watch(weekPlanProvider);
    final selections = ref.watch(planMealSelectionsProvider);
    final slotPhotos = ref.watch(planSlotPhotosProvider);
    final slotAnalyses = ref.watch(planSlotAnalysisProvider);
    final isLoading = status == PlanStatus.loading;

    // Calcul local des calories/macros d'aujourd'hui — réactif et instantané
    final _now = DateTime.now();
    final todayPrefix =
        '${_now.year.toString().padLeft(4, '0')}-'
        '${_now.month.toString().padLeft(2, '0')}-'
        '${_now.day.toString().padLeft(2, '0')}';
    int consumedKcal = 0, consumedPro = 0, consumedCarbs = 0, consumedFats = 0;
    for (final entry in selections.entries) {
      if (!entry.key.startsWith(todayPrefix)) continue;
      final analysis = slotAnalyses[entry.key];
      if (analysis != null) {
        consumedKcal  += (analysis['kcal']     as num?)?.toInt() ?? 0;
        consumedPro   += (analysis['proteins'] as num?)?.toInt() ?? 0;
        consumedCarbs += (analysis['carbs']    as num?)?.toInt() ?? 0;
        consumedFats  += (analysis['fats']     as num?)?.toInt() ?? 0;
      } else {
        consumedKcal += entry.value.kcal;
      }
    }
    final days = _days;
    final planByDate = {for (final d in weekPlan) d.date: d};
    final frDays = days.map((d) => _weekdayToFr[d.weekday]!).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTokens.ink;
    final mutedColor = isDark ? Colors.white70 : AppTokens.muted;

    final pageBg = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final ink = isDark ? Colors.white : const Color(0xFF000000);
    final muted = isDark ? Colors.white54 : const Color(0xFF757575);
    const mondayAccent = Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: pageBg,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _PlanDotPatternPainter(isDark: isDark))),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: _PlanNutritionDashboard(
                  targetCalories: profile.targetCalories,
                  targetProtein: profile.targetProtein,
                  targetCarbs: profile.targetCarbs,
                  targetFats: profile.targetFats,
                  consumedCalories: consumedKcal,
                  consumedProtein: consumedPro,
                  consumedCarbs: consumedCarbs,
                  consumedFats: consumedFats,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 75),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                          border: Border.all(color: isDark ? Colors.white12 : AppTokens.hairline),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _WeekSelectorCard(
                              days: days,
                              frDays: frDays,
                              rangeStart: _rangeStart,
                              rangeEnd: _rangeEnd,
                              frMonths: _frMonths,
                              onDayTap: _handleDayTap,
                              onPrev: _prevWeek,
                              onNext: _nextWeek,
                              isDark: isDark,
                              titleColor: titleColor,
                              mutedColor: mutedColor,
                              showDecoration: false,
                            ),
                            if (_rangeStart == null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.touch_app_outlined, color: mutedColor, size: 36),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Sélectionne un ou plusieurs jours',
                                        style: GoogleFonts.inter(fontSize: 14, color: mutedColor, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else ...[
                              Container(height: 1, color: isDark ? Colors.white12 : AppTokens.hairline),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                                child: Column(
                                  children: [
                                    for (final day in _visibleDays)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _DayPlanCard(
                                          day: day,
                                          isDark: isDark,
                                          isSelected: false,
                                          headerTitle:
                                              '${_weekdayLongFr[day.weekday]}, ${day.day} ${_frMonths[day.month - 1]}',
                                          headerAccentColor: day.weekday == DateTime.monday ? mondayAccent : ink,
                                          cardBg: isDark ? const Color(0xFF252525) : const Color(0xFFF2F2F2),
                                          ink: ink,
                                          muted: muted,
                                          selections: selections,
                                          slotPhotos: slotPhotos,
                                          slotAnalyses: slotAnalyses,
                                          slotDefs: _slotDefs,
                                          onSlotTap: (mealType) => _openSlotEditor(day, mealType, planByDate),
                                          slotTitle: (mealType) => _slotLineTitle(
                                            day,
                                            mealType,
                                            selections,
                                            planByDate,
                                            slotAnalyses,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Motif de fond très léger (points).
class _PlanDotPatternPainter extends CustomPainter {
  final bool isDark;

  _PlanDotPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()
      ..color = isDark ? const Color(0x14FFFFFF) : const Color(0x08000000);
    for (double x = 0; x < size.width + 24; x += 28) {
      for (double y = 0; y < size.height + 24; y += 28) {
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PlanDotPatternPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// ─── Carte sélecteur de semaine ─────────────────────────────────────────────

class _WeekSelectorCard extends StatelessWidget {
  final List<DateTime> days;
  final List<String> frDays;
  final int? rangeStart;
  final int? rangeEnd;
  final List<String> frMonths;
  final void Function(int) onDayTap;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool isDark;
  final Color titleColor;
  final Color mutedColor;
  final bool showDecoration;

  const _WeekSelectorCard({
    required this.days,
    required this.frDays,
    required this.rangeStart,
    required this.rangeEnd,
    required this.frMonths,
    required this.onDayTap,
    required this.onPrev,
    required this.onNext,
    required this.isDark,
    required this.titleColor,
    required this.mutedColor,
    this.showDecoration = true,
  });

  String _rangeTitle() {
    final s = days.first;
    final e = days.last;
    if (s.month == e.month) {
      return 'du ${s.day} au ${e.day} ${frMonths[s.month - 1]}';
    }
    return 'du ${s.day} ${frMonths[s.month - 1]} au ${e.day} ${frMonths[e.month - 1]}';
  }

  bool _isInRange(int i) {
    if (rangeStart == null) return false;
    final end = rangeEnd ?? rangeStart!;
    return i >= rangeStart! && i <= end;
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final bandColor = AppTokens.coral.withValues(alpha: 0.15);

    final inner = Column(
      children: [
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
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
            child: Row(
              children: List.generate(7, (i) {
                final effectiveEnd = rangeEnd ?? rangeStart;
                final isStart = i == rangeStart;
                final isEnd = effectiveEnd != null && i == effectiveEnd;
                final isInRange = _isInRange(i);
                final isSelected = isStart || isEnd;

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
                            color: isInRange ? AppTokens.coral : mutedColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 34,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Bande gauche
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: 0.5,
                                  child: Container(
                                    color: (isInRange && !isStart) ? bandColor : Colors.transparent,
                                  ),
                                ),
                              ),
                              // Bande droite
                              Align(
                                alignment: Alignment.centerRight,
                                child: FractionallySizedBox(
                                  widthFactor: 0.5,
                                  child: Container(
                                    color: (isInRange && !isEnd) ? bandColor : Colors.transparent,
                                  ),
                                ),
                              ),
                              // Cercle du jour
                              Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTokens.coral : Colors.transparent,
                                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${days[i].day}',
                                      style: GoogleFonts.fraunces(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.white : titleColor,
                                      ),
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
              }),
            ),
          ),
        ],
    );

    if (!showDecoration) return inner;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: isDark ? Colors.white12 : AppTokens.hairline),
      ),
      child: inner,
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

// ─── Carte jour (sections repas) ──────────────────────────────────────────────

class _DayPlanCard extends StatelessWidget {
  final DateTime day;
  final bool isDark;
  final bool isSelected;
  final String headerTitle;
  final Color headerAccentColor;
  final Color cardBg;
  final Color ink;
  final Color muted;
  final Map<String, Meal> selections;
  final Map<String, Uint8List> slotPhotos;
  final Map<String, Map<String, dynamic>> slotAnalyses;
  final List<(String, String)> slotDefs;
  final void Function(String mealType) onSlotTap;
  final String Function(String mealType) slotTitle;

  const _DayPlanCard({
    required this.day,
    required this.isDark,
    required this.isSelected,
    required this.headerTitle,
    required this.headerAccentColor,
    required this.cardBg,
    required this.ink,
    required this.muted,
    required this.selections,
    required this.slotPhotos,
    required this.slotAnalyses,
    required this.slotDefs,
    required this.onSlotTap,
    required this.slotTitle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: isSelected
            ? Border.all(color: AppTokens.coral.withValues(alpha: 0.65), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              headerTitle,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: headerAccentColor,
              ),
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < slotDefs.length; i++) ...[
              _DayMealSlotTile(
                typeLabel: slotDefs[i].$2,
                titleText: slotTitle(slotDefs[i].$1),
                ink: ink,
                muted: muted,
                selectedMeal: selections[planSlotStorageKey(day, slotDefs[i].$1)],
                customPhoto: slotPhotos[planSlotStorageKey(day, slotDefs[i].$1)],
                onTap: () => onSlotTap(slotDefs[i].$1),
              ),
              if (i < slotDefs.length - 1) const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayMealSlotTile extends StatelessWidget {
  final String typeLabel;
  final String titleText;
  final Color ink;
  final Color muted;
  final Meal? selectedMeal;
  final Uint8List? customPhoto;
  final VoidCallback onTap;

  const _DayMealSlotTile({
    required this.typeLabel,
    required this.titleText,
    required this.ink,
    required this.muted,
    required this.selectedMeal,
    required this.customPhoto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = titleText.isNotEmpty ? titleText : 'Ajouter un plat';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: _slotThumbnail(
                    selectedMeal: selectedMeal,
                    customPhoto: customPhoto,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      typeLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.add, color: AppTokens.coral, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotThumbnail({required Meal? selectedMeal, required Uint8List? customPhoto}) {
    if (selectedMeal != null) {
      return MealImage(photo: selectedMeal.photo, fallbackKey: selectedMeal.title);
    }
    if (customPhoto != null) {
      return Image.memory(customPhoto, fit: BoxFit.cover);
    }
    return Container(
      color: AppTokens.placeholder,
      child: Center(
        child: Text(_slotEmoji(), style: const TextStyle(fontSize: 26)),
      ),
    );
  }

  String _slotEmoji() {
    switch (typeLabel) {
      case 'Petit-déjeuner': return '🥣';
      case 'Déjeuner':       return '🥗';
      case 'En cas':         return '🍎';
      case 'Dîner':          return '🍜';
      default:               return '🍽️';
    }
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

  String get _slotKey => planSlotStorageKey(widget.day, widget.mealType);

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
    final sportAsync = ref.watch(sportRecipesProvider);
    final minceurAsync = ref.watch(minceurRecipesProvider);
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
    final sportMeals = sportAsync.maybeWhen(
      data: (list) => list.where((m) => !takenIds.contains(m.id)).toList(),
      orElse: () => const <Meal>[],
    );
    final minceurMeals = minceurAsync.maybeWhen(
      data: (list) => list.where((m) => !takenIds.contains(m.id)).toList(),
      orElse: () => const <Meal>[],
    );

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
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 75),
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
                                              Text(
                                                'Clic pour prendre une photo de ton plat',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTokens.coral,
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

                  if (meal == null && _pickedPhoto == null && _analysis == null) ...[
                    const SizedBox(height: 8),
                    _SectionTitle(title: 'Étudiant fauché'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _budgetMeals.length,
                        itemBuilder: (_, i) => _MealPickCard(
                          meal: _budgetMeals[i],
                          isSelected: _selected?.id == _budgetMeals[i].id,
                          onTap: () => _selectMeal(_budgetMeals[i]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _SectionTitle(title: 'Salades'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _saladMeals.length,
                        itemBuilder: (_, i) => _MealPickCard(
                          meal: _saladMeals[i],
                          isSelected: _selected?.id == _saladMeals[i].id,
                          onTap: () => _selectMeal(_saladMeals[i]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (sportMeals.isNotEmpty) ...[
                      _SectionTitle(title: 'Prise de masse'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: sportMeals.length,
                          itemBuilder: (_, i) => _MealPickCard(
                            meal: sportMeals[i],
                            isSelected: _selected?.id == sportMeals[i].id,
                            onTap: () => _selectMeal(sportMeals[i]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (minceurMeals.isNotEmpty) ...[
                      _SectionTitle(title: 'Minceur'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: minceurMeals.length,
                          itemBuilder: (_, i) => _MealPickCard(
                            meal: minceurMeals[i],
                            isSelected: _selected?.id == minceurMeals[i].id,
                            onTap: () => _selectMeal(minceurMeals[i]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
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

// ─── Collections statiques ───────────────────────────────────────────────────

final _budgetMeals = [
  Meal(
    id: 'plan_budget_1', type: 'simple', typeLabel: 'Simple', emoji: '🍝',
    title: 'Pâtes bolognaise budget', kcal: 560, protein: 'moyen',
    difficulty: 'facile', time: '18 min', locked: false,
    photo: 'assets/images/spaghetti-bolognese.png', color: '#F2994A',
    ingredients: [Ingredient(name: 'Pâtes', qty: '120 g', photo: ''), Ingredient(name: 'Boeuf haché', qty: '150 g', photo: ''), Ingredient(name: 'Sauce tomate', qty: '200 ml', photo: '')],
    steps: ['Fais cuire les pâtes dans une eau salée.', 'Poêle chaude: saisis le boeuf puis ajoute la sauce tomate.', 'Mélange avec les pâtes et sers bien chaud.'],
    prepTimeMin: 6, cookTimeMin: 12,
  ),
  Meal(
    id: 'plan_budget_2', type: 'simple', typeLabel: 'Simple', emoji: '🍜',
    title: 'Ramen minute', kcal: 490, protein: 'moyen',
    difficulty: 'facile', time: '16 min', locked: false,
    photo: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=900', color: '#F2C94C',
    ingredients: [Ingredient(name: 'Nouilles', qty: '1 paquet', photo: ''), Ingredient(name: 'Oeuf', qty: '1', photo: ''), Ingredient(name: 'Bouillon', qty: '350 ml', photo: '')],
    steps: ['Porte le bouillon a frémissement.', 'Ajoute les nouilles et cuis 3 à 4 minutes.', 'Termine avec l oeuf mollet.'],
    prepTimeMin: 4, cookTimeMin: 12,
  ),
  Meal(
    id: 'plan_budget_3', type: 'balanced', typeLabel: 'Équilibré', emoji: '🍚',
    title: 'Riz sauté économique', kcal: 430, protein: 'moyen',
    difficulty: 'facile', time: '20 min', locked: false,
    photo: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=900', color: '#6FCF97',
    ingredients: [Ingredient(name: 'Riz cuit', qty: '180 g', photo: ''), Ingredient(name: 'Carotte', qty: '1', photo: ''), Ingredient(name: 'Oeuf', qty: '1', photo: '')],
    steps: ['Fais revenir les légumes en petits dés.', 'Ajoute le riz, puis saisis à feu vif 3 minutes.', 'Pousse le riz sur le côté et brouille l oeuf avant de mélanger.'],
    prepTimeMin: 7, cookTimeMin: 13,
  ),
];

final _saladMeals = [
  Meal(
    id: 'plan_salad_1', type: 'balanced', typeLabel: 'Équilibré', emoji: '🥗',
    title: 'César légère', kcal: 340, protein: 'moyen',
    difficulty: 'facile', time: '14 min', locked: false,
    photo: 'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=900', color: '#82D28C',
    ingredients: [Ingredient(name: 'Laitue', qty: '1/2', photo: ''), Ingredient(name: 'Poulet', qty: '120 g', photo: ''), Ingredient(name: 'Parmesan', qty: '20 g', photo: '')],
    steps: ['Coupe la laitue et prépare les copeaux de parmesan.', 'Poêle le poulet assaisonné puis tranche-le.', 'Mélange avec la sauce césar et les croûtons.'],
    prepTimeMin: 8, cookTimeMin: 6,
  ),
  Meal(
    id: 'plan_salad_2', type: 'stylish', typeLabel: 'Stylé', emoji: '🥑',
    title: 'Bowl avocat-feta', kcal: 360, protein: 'moyen',
    difficulty: 'facile', time: '12 min', locked: false,
    photo: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=900', color: '#6FCF97',
    ingredients: [Ingredient(name: 'Avocat', qty: '1', photo: ''), Ingredient(name: 'Feta', qty: '60 g', photo: ''), Ingredient(name: 'Concombre', qty: '1/2', photo: '')],
    steps: ['Coupe tous les ingrédients en cubes.', 'Ajoute un filet d huile d olive et du citron.', 'Assaisonne puis mélange délicatement.'],
    prepTimeMin: 10, cookTimeMin: 2,
  ),
  Meal(
    id: 'plan_salad_3', type: 'balanced', typeLabel: 'Équilibré', emoji: '🥗',
    title: 'Salade de quinoa', kcal: 320, protein: 'moyen',
    difficulty: 'facile', time: '15 min', locked: false,
    photo: 'https://images.unsplash.com/photo-1505576399279-565b52d4ac71?w=900', color: '#27AE60',
    ingredients: [Ingredient(name: 'Quinoa', qty: '80 g', photo: ''), Ingredient(name: 'Tomates cerises', qty: '8', photo: ''), Ingredient(name: 'Menthe', qty: '6 feuilles', photo: '')],
    steps: ['Rince puis cuis le quinoa dans deux volumes d eau.', 'Laisse tiédir et ajoute tomates et herbes.', 'Assaisonne avec citron, huile d olive et sel.'],
    prepTimeMin: 9, cookTimeMin: 6,
  ),
];

// ─── Dashboard nutrition ────────────────────────────────────────────────────

class _PlanNutritionDashboard extends StatelessWidget {
  final int targetCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFats;
  final int consumedCalories;
  final int consumedProtein;
  final int consumedCarbs;
  final int consumedFats;

  const _PlanNutritionDashboard({
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFats,
    required this.consumedCalories,
    required this.consumedProtein,
    required this.consumedCarbs,
    required this.consumedFats,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A1A) : AppTokens.surface;
    final textColor = isDark ? Colors.white : AppTokens.ink;
    final mutedColor = isDark ? Colors.white54 : AppTokens.muted;
    final dividerColor = isDark ? Colors.white12 : AppTokens.hairline;

    const burned = 0;
    final remaining = (targetCalories - consumedCalories + burned).clamp(0, targetCalories);
    final progress = targetCalories > 0 ? (consumedCalories / targetCalories).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: isDark ? null : Border.all(color: AppTokens.hairline),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const h = 160.0;
              final centerY = h * 0.88;
              final radius = constraints.maxWidth * 0.40;
              final midY = centerY - radius / 2;
              final alignY = ((midY / h) * 2 - 1).clamp(-1.0, 1.0);
              return SizedBox(
                height: h,
                child: CustomPaint(
                  painter: _DashArcPainter(progress: progress, isDark: isDark),
                  child: Align(
                    alignment: Alignment(0, alignY),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$remaining', style: GoogleFonts.fraunces(fontSize: 28, fontWeight: FontWeight.w700, color: textColor)),
                        Text('Restantes', style: GoogleFonts.inter(fontSize: 11, color: mutedColor, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: dividerColor),
          const SizedBox(height: 14),
          Row(
            children: [
              _DashMacroBar(label: 'Glucides', current: consumedCarbs, target: targetCarbs, color: const Color(0xFF2196F3), mutedColor: mutedColor),
              _DashMacroBar(label: 'Protéines', current: consumedProtein, target: targetProtein, color: AppTokens.coral, mutedColor: mutedColor),
              _DashMacroBar(label: 'Lipides', current: consumedFats, target: targetFats, color: const Color(0xFFFF9800), mutedColor: mutedColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashCalorieItem extends StatelessWidget {
  final String value;
  final String label;
  final Color textColor;
  final Color mutedColor;
  const _DashCalorieItem({required this.value, required this.label, required this.textColor, required this.mutedColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: mutedColor, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _DashMacroBar extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final Color color;
  final Color mutedColor;
  const _DashMacroBar({required this.label, required this.current, required this.target, required this.color, required this.mutedColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: mutedColor, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? Colors.white12 : AppTokens.hairline,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            Text('$current / ${target}g', style: GoogleFonts.inter(fontSize: 11, color: mutedColor)),
          ],
        ),
      ),
    );
  }
}

class _DashArcPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  const _DashArcPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.88);
    final radius = size.width * 0.40;
    final trackColor = isDark ? Colors.white12 : const Color(0xFFE0E0E0);

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi, pi, false,
      Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = 7..strokeCap = StrokeCap.round);

    if (progress > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi, pi * progress, false,
        Paint()..color = AppTokens.coral..style = PaintingStyle.stroke..strokeWidth = 7..strokeCap = StrokeCap.round);
    }

    final dotAngle = pi + pi * progress;
    canvas.drawCircle(
      Offset(center.dx + radius * cos(dotAngle), center.dy + radius * sin(dotAngle)),
      5,
      Paint()..color = AppTokens.coral..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_DashArcPainter old) => old.progress != progress || old.isDark != isDark;
}

class _MealPickCard extends ConsumerWidget {
  final Meal meal;
  final bool isSelected;
  final VoidCallback onTap;
  static const double _cardWidth = 130;
  static const double _favoriteTapZone = 40;
  const _MealPickCard({required this.meal, required this.onTap, this.isSelected = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allMeals = ref.watch(mealsProvider);
    final liveMeal = allMeals.firstWhere((m) => m.id == meal.id, orElse: () => meal);
    final isFav = liveMeal.isFavorite;

    return GestureDetector(
      onTapUp: (details) {
        final p = details.localPosition;
        final onFavoriteZone =
            p.dx >= (_cardWidth - _favoriteTapZone) && p.dy <= _favoriteTapZone;
        if (onFavoriteZone) return;
        onTap();
      },
      child: Container(
        width: _cardWidth,
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
              child: Stack(
                children: [
                  SizedBox(
                    height: 100, width: _cardWidth,
                    child: MealImage(
                      photo: meal.photo,
                      fallbackKey: meal.title,
                    ),
                  ),
                  Positioned(
                    top: 6, right: 6,
                    child: GestureDetector(
                      onTap: () => ref.read(mealsProvider.notifier).toggleFavorite(meal.id),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 15,
                          color: isFav ? AppTokens.coral : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
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
