class DayPlan {
  final String date;
  final String dayName;
  final String lunch;
  final String dinner;

  const DayPlan({
    required this.date,
    required this.dayName,
    required this.lunch,
    required this.dinner,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) => DayPlan(
        date: json['date'] as String,
        dayName: json['day'] as String,
        lunch: json['lunch'] as String,
        dinner: json['dinner'] as String,
      );
}
