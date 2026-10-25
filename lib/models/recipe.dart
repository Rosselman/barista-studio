import 'package:uuid/uuid.dart';
import 'phase.dart';
import 'recipe_step.dart';

class Recipe {
  final String id;
  final String name; // Displayed on front LED matrix (Max 16 ASCII)
  final String description;
  final String category; // Primary category for display
  final List<String> tags; // Classification tags for multi-filter matching
  final List<RecipeStep> steps; // Multi-step support (Step 1, Step 2, etc.)
  final List<String> ingredients;
  final List<String> instructions;
  final bool isCustom;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.tags = const [],
    List<RecipeStep>? steps,
    List<Phase>? phases,
    this.ingredients = const [],
    this.instructions = const [],
    this.isCustom = false,
  }) : steps = (steps != null && steps.isNotEmpty)
            ? List.unmodifiable(steps)
            : List.unmodifiable([
                RecipeStep(
                  name: 'STEP 1',
                  phases: phases ?? [Phase.clamped()],
                ),
              ]);

  /// Backward-compatible list of all phases across all steps
  List<Phase> get phases => steps.expand((s) => s.phases).toList();

  /// Whether this recipe utilizes the Barista hardware's multi-step paused execution
  bool get isMultiStep => steps.length > 1;

  /// Total number of steps in this recipe
  int get stepCount => steps.length;

  /// Sanitized name for hardware LED screen (max 16 ASCII characters)
  String get hardwareName {
    final clean = name.trim();
    if (clean.isEmpty) return 'Recipe';
    final asciiOnly = clean.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    if (asciiOnly.isEmpty) return 'Recipe';
    return asciiOnly.length > 16 ? asciiOnly.substring(0, 16) : asciiOnly;
  }

  /// Total duration across all active phases across all steps
  int get totalDurationSeconds {
    return steps.fold(0, (acc, s) => acc + s.totalDurationSeconds);
  }

  /// Highest speed across active phases in all steps
  int get peakRpm {
    int max = 0;
    for (final s in steps) {
      for (final p in s.activePhases) {
        if (p.speed > max) max = p.speed;
      }
    }
    return max > 0 ? max : 3000;
  }

  /// Target temperature of active phases across all steps (highest)
  int get maxTemp {
    int max = 0;
    for (final s in steps) {
      for (final p in s.activePhases) {
        if (p.temp > max) max = p.temp;
      }
    }
    return max;
  }

  /// True if all active phases across all steps are cold (0°C)
  bool get isCold {
    for (final s in steps) {
      for (final p in s.activePhases) {
        if (p.temp != 0) return false;
      }
    }
    return true;
  }

  /// List of all active phases across all steps
  List<Phase> get activePhases => steps.expand((s) => s.activePhases).toList();

  /// True if the recipe involves turmeric in name, description, ingredients, or instructions.
  bool get hasTurmeric {
    if (name.toLowerCase().contains('turmeric')) return true;
    if (description.toLowerCase().contains('turmeric')) return true;
    for (final ing in ingredients) {
      if (ing.toLowerCase().contains('turmeric')) return true;
    }
    for (final ins in instructions) {
      if (ins.toLowerCase().contains('turmeric')) return true;
    }
    for (final s in steps) {
      if (s.name.toLowerCase().contains('turmeric')) return true;
      if (s.instruction != null &&
          s.instruction!.toLowerCase().contains('turmeric')) {
        return true;
      }
    }
    return false;
  }

  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    List<String>? tags,
    List<RecipeStep>? steps,
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
      tags: tags ?? this.tags,
      steps: steps ?? (phases != null ? [RecipeStep(name: 'STEP 1', phases: phases)] : this.steps),
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
        'tags': tags,
        'steps': steps.map((s) => s.toJson()).toList(),
        'phases': phases.map((p) => p.toJson()).toList(), // legacy compatibility
        'ingredients': ingredients,
        'instructions': instructions,
        'isCustom': isCustom,
      };

  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<RecipeStep>? parsedSteps;
    if (json['steps'] is List && (json['steps'] as List).isNotEmpty) {
      parsedSteps = (json['steps'] as List)
          .map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    List<Phase>? parsedPhases;
    if (json['phases'] is List) {
      parsedPhases = (json['phases'] as List)
          .map((e) => Phase.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Recipe(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Custom Froth',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Specialty',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      steps: parsedSteps,
      phases: parsedPhases,
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
