class PlanMeal {
  final String name;
  final int kcal;
  final String time;
  final List<String> steps;

  const PlanMeal({
    required this.name,
    required this.kcal,
    required this.time,
    required this.steps,
  });

  factory PlanMeal.fromJson(Map<String, dynamic> json) => PlanMeal(
        name: json['name'] as String,
        kcal: (json['kcal'] as num).toInt(),
        time: json['time'] as String,
        steps: (json['steps'] as List).cast<String>(),
      );
}

class DayPlan {
  final String date;
  final String dayName;
  final PlanMeal lunch;
  final PlanMeal dinner;

  const DayPlan({
    required this.date,
    required this.dayName,
    required this.lunch,
    required this.dinner,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) => DayPlan(
        date: json['date'] as String,
        dayName: json['day'] as String,
        lunch: PlanMeal.fromJson(json['lunch'] as Map<String, dynamic>),
        dinner: PlanMeal.fromJson(json['dinner'] as Map<String, dynamic>),
      );
}
