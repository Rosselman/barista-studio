import 'phase.dart';

/// Represents a single execution step within a Barista recipe.
///
/// The Barista W545 firmware natively supports multi-step execution:
/// - Step 1 executes (MachineState.RECIPE_EXECUTING = 2).
/// - Upon completion, motor and heat cut off and the machine enters
///   MachineState.RECIPE_PAUSED (7), prompting the user on the OLED display.
/// - When the user presses the center dial button, Step 2 executes.
class RecipeStep {
  final String name; // e.g. "STEP 1", "STEP 2" (max 16 ASCII)
  final List<Phase> phases; // 1 to 3 phases
  final String? instruction; // Human-readable user prompt (e.g. "Add milk to jug")

  const RecipeStep({
    required this.name,
    required this.phases,
    this.instruction,
  });

  /// Hardware sanitized name for matrix / packet (max 16 ASCII)
  String get hardwareName {
    final clean = name.trim();
    if (clean.isEmpty) return 'STEP';
    final asciiOnly = clean.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    if (asciiOnly.isEmpty) return 'STEP';
    return asciiOnly.length > 16 ? asciiOnly.substring(0, 16) : asciiOnly;
  }

  /// Active phases with duration > 0
  List<Phase> get activePhases => phases.where((p) => p.isActive).toList();

  /// Total duration across active phases in this step
  int get totalDurationSeconds =>
      activePhases.fold(0, (acc, p) => acc + p.duration);

  /// Peak RPM across active phases in this step
  int get peakRpm {
    if (activePhases.isEmpty) return 3000;
    return activePhases.map((p) => p.speed).reduce((a, b) => a > b ? a : b);
  }

  /// Target temperature (highest) of active phases in this step
  int get maxTemp {
    if (activePhases.isEmpty) return 0;
    return activePhases.map((p) => p.temp).reduce((a, b) => a > b ? a : b);
  }

  /// True if all active phases in this step are cold (0°C)
  bool get isCold {
    if (activePhases.isEmpty) return true;
    return activePhases.every((p) => p.temp == 0);
  }

  RecipeStep copyWith({
    String? name,
    List<Phase>? phases,
    String? instruction,
  }) {
    return RecipeStep(
      name: name ?? this.name,
      phases: phases ?? this.phases,
      instruction: instruction ?? this.instruction,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phases': phases.map((p) => p.toJson()).toList(),
        if (instruction != null) 'instruction': instruction,
      };

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      name: json['name'] as String? ?? 'STEP 1',
      phases: (json['phases'] as List<dynamic>?)
              ?.map((e) => Phase.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [Phase.clamped()],
      instruction: json['instruction'] as String?,
    );
  }

  @override
  String toString() =>
      'RecipeStep($name, ${phases.length} phases, ${totalDurationSeconds}s)';
}
