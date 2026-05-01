import 'package:hive/hive.dart';

part 'meal.g.dart';

@HiveType(typeId: 0)
class Meal {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // simple, balanced, stylish

  @HiveField(2)
  final String typeLabel;

  @HiveField(3)
  final String emoji;

  @HiveField(4)
  final String title;

  @HiveField(5)
  final int kcal;

  @HiveField(6)
  final String protein; // moyen, élevé

  @HiveField(7)
  final String difficulty; // facile, intermédiaire

  @HiveField(8)
  final String time;

  @HiveField(9)
  final bool locked;

  @HiveField(10)
  final String photo;

  @HiveField(11)
  final List<Ingredient> ingredients;

  @HiveField(12)
  final List<String> steps;

  @HiveField(13)
  final String color;

  @HiveField(14)
  final bool isFavorite;

  Meal({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.emoji,
    required this.title,
    required this.kcal,
    required this.protein,
    required this.difficulty,
    required this.time,
    required this.locked,
    required this.photo,
    required this.ingredients,
    required this.steps,
    required this.color,
    this.isFavorite = false,
  });

  Meal copyWith({
    String? id,
    String? type,
    String? typeLabel,
    String? emoji,
    String? title,
    int? kcal,
    String? protein,
    String? difficulty,
    String? time,
    bool? locked,
    String? photo,
    List<Ingredient>? ingredients,
    List<String>? steps,
    String? color,
    bool? isFavorite,
  }) {
    return Meal(
      id: id ?? this.id,
      type: type ?? this.type,
      typeLabel: typeLabel ?? this.typeLabel,
      emoji: emoji ?? this.emoji,
      title: title ?? this.title,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      difficulty: difficulty ?? this.difficulty,
      time: time ?? this.time,
      locked: locked ?? this.locked,
      photo: photo ?? this.photo,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      color: color ?? this.color,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'].toString(),
      type: json['type'] ?? '',
      typeLabel: json['typeLabel'] ?? '',
      emoji: json['emoji'] ?? '🍽️',
      title: json['title'] ?? '',
      kcal: json['kcal'] ?? 0,
      protein: json['protein'] ?? 'moyen',
      difficulty: json['difficulty'] ?? 'facile',
      time: json['time'] ?? '0 min',
      locked: json['locked'] ?? false,
      photo: json['photo'] ?? '',
      ingredients: (json['ingredients'] as List?)
              ?.map((e) => Ingredient.fromJson(e))
              .toList() ??
          [],
      steps: (json['steps'] as List?)?.cast<String>() ?? [],
      color: json['color'] ?? '#82D28C',
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'typeLabel': typeLabel,
      'emoji': emoji,
      'title': title,
      'kcal': kcal,
      'protein': protein,
      'difficulty': difficulty,
      'time': time,
      'locked': locked,
      'photo': photo,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'steps': steps,
      'color': color,
      'isFavorite': isFavorite,
    };
  }
}

@HiveType(typeId: 1)
class Ingredient {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String qty;

  @HiveField(2)
  final String photo;

  Ingredient({
    required this.name,
    required this.qty,
    required this.photo,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] ?? '',
      qty: json['qty'] ?? '',
      photo: json['photo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'qty': qty,
      'photo': photo,
    };
  }
}
