import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/services/claude_service.dart';
import '../../meals/providers/meals_provider.dart';
import '../models/day_plan.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  DateTime _focusedMonth =
      DateTime(DateTime.now().year, DateTime.now().month);

  Future<void> _generatePlan() async {
    final photos = ref.read(capturedPhotosProvider);
    if (photos.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Prends d\'abord une photo de ton frigo !',
            style: GoogleFonts.dmSans(color: Colors.white),
          ),
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
      if (plan.isNotEmpty) {
        final firstDate = DateTime.parse(plan.first.date);
        setState(() => _focusedMonth =
            DateTime(firstDate.year, firstDate.month));
      }
    } catch (e) {
      ref.read(planStatusProvider.notifier).state = PlanStatus.error;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur : $e',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  void _showDayDetails(DayPlan day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTokens.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                day.dayName,
                style: GoogleFonts.syne(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTokens.text,
                ),
              ),
              const SizedBox(height: 20),
              _MealSection(icon: '☀️', label: 'Déjeuner', meal: day.lunch),
              const SizedBox(height: 16),
              _MealSection(icon: '🌙', label: 'Dîner', meal: day.dinner),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(planStatusProvider);
    final weekPlan = ref.watch(weekPlanProvider);
    final isLoading = status == PlanStatus.loading;
    final planMap = {for (final d in weekPlan) d.date: d};

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _CalendarView(
                  focusedMonth: _focusedMonth,
                  onMonthChanged: (m) => setState(() => _focusedMonth = m),
                  planMap: planMap,
                  onDayTap: _showDayDetails,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _generatePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.accent,
                    disabledBackgroundColor:
                        AppTokens.accent.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusMd),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppTokens.bg,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Générer un plan',
                          style: GoogleFonts.syne(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.bg,
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

class _CalendarView extends StatelessWidget {
  final DateTime focusedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final Map<String, DayPlan> planMap;
  final ValueChanged<DayPlan> onDayTap;

  static const _dayHeaders = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di'];
  static const _frMonths = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  const _CalendarView({
    required this.focusedMonth,
    required this.onMonthChanged,
    required this.planMap,
    required this.onDayTap,
  });

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDay =
        DateTime(focusedMonth.year, focusedMonth.month, 1);
    final startOffset = firstDay.weekday - 1; // 0=Mon … 6=Sun
    final daysInMonth =
        DateUtils.getDaysInMonth(focusedMonth.year, focusedMonth.month);
    final totalCells = startOffset + daysInMonth;
    final rowCount = (totalCells / 7).ceil();
    final monthLabel =
        '${_frMonths[focusedMonth.month - 1]} ${focusedMonth.year}';

    return Container(
      decoration: BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month navigation
          Row(
            children: [
              _NavButton(
                icon: Icons.chevron_left,
                onTap: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month - 1),
                ),
              ),
              Expanded(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.text,
                  ),
                ),
              ),
              _NavButton(
                icon: Icons.chevron_right,
                onTap: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month + 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Day headers
          Row(
            children: _dayHeaders.map((d) {
              return Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.muted,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Day grid
          ...List.generate(rowCount, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  if (cellIndex < startOffset ||
                      cellIndex >= startOffset + daysInMonth) {
                    return const Expanded(child: SizedBox(height: 44));
                  }

                  final dayNum = cellIndex - startOffset + 1;
                  final date = DateTime(
                      focusedMonth.year, focusedMonth.month, dayNum);
                  final dateStr = _isoDate(date);
                  final isToday = date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;
                  final hasPlan = planMap.containsKey(dateStr);
                  final dayPlan = planMap[dateStr];
                  final isPast = date.isBefore(
                      DateTime(today.year, today.month, today.day));

                  return Expanded(
                    child: GestureDetector(
                      onTap: hasPlan ? () => onDayTap(dayPlan!) : null,
                      child: SizedBox(
                        height: 44,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isToday
                                    ? AppTokens.accent
                                    : hasPlan
                                        ? AppTokens.accent
                                            .withOpacity(0.15)
                                        : Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  '$dayNum',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: isToday || hasPlan
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isToday
                                        ? AppTokens.bg
                                        : isPast && !hasPlan
                                            ? AppTokens.muted
                                                .withOpacity(0.4)
                                            : AppTokens.text,
                                  ),
                                ),
                              ),
                            ),
                            if (hasPlan && !isToday)
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: AppTokens.accent,
                                  shape: BoxShape.circle,
                                ),
                              )
                            else
                              const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),

          // Legend
          if (planMap.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTokens.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Appuie sur un jour pour voir le menu',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppTokens.muted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTokens.border),
        ),
        child: Icon(icon, color: AppTokens.text, size: 20),
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  final String icon;
  final String label;
  final PlanMeal meal;

  const _MealSection({
    required this.icon,
    required this.label,
    required this.meal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: icon + label + badges
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.muted,
                ),
              ),
              const Spacer(),
              _Badge(
                icon: Icons.local_fire_department_rounded,
                label: '${meal.kcal} kcal',
                color: const Color(0xFFE8A050),
              ),
              const SizedBox(width: 6),
              _Badge(
                icon: Icons.timer_outlined,
                label: meal.time,
                color: AppTokens.muted,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            meal.name,
            style: GoogleFonts.syne(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: 14),
          // Steps
          Text(
            'Préparation',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTokens.muted,
            ),
          ),
          const SizedBox(height: 8),
          ...meal.steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: AppTokens.accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppTokens.text,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
