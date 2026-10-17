import 'package:uuid/uuid.dart';
import 'phase.dart';

class Recipe {
  final String id;
  final String name; // Displayed on front LED matrix (Max 16 ASCII)
  final String description;
  final String category; // 'Hot', 'Iced / Cold Foam', 'Plant-Based / Non-Dairy', 'Chocolate & Matcha', 'Specialty'
  final List<Phase> phases; // Max 3 phases
  final List<String> ingredients;
  final List<String> instructions;
  final bool isCustom;

  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.phases,
    this.ingredients = const [],
    this.instructions = const [],
    this.isCustom = false,
  });

  /// Sanitized name for hardware LED screen (max 16 ASCII characters)
  String get hardwareName {
    final clean = name.trim();
    if (clean.isEmpty) return 'Recipe';
    // Remove non-ASCII characters for clean matrix display
    final asciiOnly = clean.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    if (asciiOnly.isEmpty) return 'Recipe';
    return asciiOnly.length > 16 ? asciiOnly.substring(0, 16) : asciiOnly;
  }

  /// Total duration across all active phases
  int get totalDurationSeconds {
    return phases
        .where((p) => p.isActive)
        .fold(0, (acc, p) => acc + p.duration);
  }

  /// Highest speed across active phases
  int get peakRpm {
    final active = phases.where((p) => p.isActive);
    if (active.isEmpty) return 3000;
    return active.map((p) => p.speed).reduce((a, b) => a > b ? a : b);
  }

  /// Target temperature of active phases (highest)
  int get maxTemp {
    final active = phases.where((p) => p.isActive);
    if (active.isEmpty) return 0;
    return active.map((p) => p.temp).reduce((a, b) => a > b ? a : b);
  }

  bool get isCold {
    final active = phases.where((p) => p.isActive);
    if (active.isEmpty) return true;
    return active.every((p) => p.temp == 0);
  }

  List<Phase> get activePhases => phases.where((p) => p.isActive).toList();

  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    List<Phase>? phases,
    List<String>? ingredients,
    List<String>? instructions,
    bool? isCustom,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      phases: phases ?? this.phases,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'phases': phases.map((p) => p.toJson()).toList(),
        'ingredients': ingredients,
        'instructions': instructions,
        'isCustom': isCustom,
      };

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Custom Froth',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Specialty',
      phases: (json['phases'] as List<dynamic>?)
              ?.map((e) => Phase.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [Phase.clamped()],
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isCustom: json['isCustom'] as bool? ?? true,
    );
  }
}
