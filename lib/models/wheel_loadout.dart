import 'package:uuid/uuid.dart';
import '../data/preset_catalog.dart';
import '../models/recipe.dart';

class LoadoutSlotEntry {
  final int slotIndex; // 0..12
  final String recipeId;
  final String recipeName;
  final bool isCustom;

  const LoadoutSlotEntry({
    required this.slotIndex,
    required this.recipeId,
    required this.recipeName,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'slotIndex': slotIndex,
        'recipeId': recipeId,
        'recipeName': recipeName,
        'isCustom': isCustom,
      };

  factory LoadoutSlotEntry.fromJson(Map<String, dynamic> json) {
    return LoadoutSlotEntry(
      slotIndex: json['slotIndex'] as int? ?? 0,
      recipeId: json['recipeId'] as String? ?? '',
      recipeName: json['recipeName'] as String? ?? 'Recipe',
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}

class WheelLoadout {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final List<LoadoutSlotEntry> slots; // up to 13 slot entries

  const WheelLoadout({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.slots,
  });

  /// Total occupied slots in this loadout
  int get occupiedCount => slots.length;

  /// Creates a new custom loadout with auto-generated UUID and timestamp
  factory WheelLoadout.create({
    required String name,
    String description = '',
    required List<LoadoutSlotEntry> slots,
  }) {
    return WheelLoadout(
      id: const Uuid().v4(),
      name: name.trim().isEmpty ? 'My Wheel Loadout' : name.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
      slots: List.unmodifiable(slots),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'slots': slots.map((s) => s.toJson()).toList(),
      };

  factory WheelLoadout.fromJson(Map<String, dynamic> json) {
    final slotsList = (json['slots'] as List<dynamic>?)
            ?.map((s) => LoadoutSlotEntry.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    return WheelLoadout(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Untitled Loadout',
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      slots: List.unmodifiable(slotsList),
    );
  }

  /// Resolves the actual Recipe objects for this loadout using presets and custom recipes
  List<Recipe?> resolveRecipes(List<Recipe> customRecipes) {
    final Map<String, Recipe> catalogMap = {
      for (final r in PresetCatalog.presets) r.id.toLowerCase(): r,
      for (final r in PresetCatalog.presets) r.name.toLowerCase(): r,
    };
    final Map<String, Recipe> customMap = {
      for (final r in customRecipes) r.id.toLowerCase(): r,
      for (final r in customRecipes) r.name.toLowerCase(): r,
    };

    final resolved = <Recipe?>[];
    for (int i = 0; i < 13; i++) {
      final entry = slots.where((s) => s.slotIndex == i).firstOrNull;
      if (entry == null) {
        resolved.add(null);
        continue;
      }

      final idKey = entry.recipeId.toLowerCase();
      final nameKey = entry.recipeName.toLowerCase();

      Recipe? recipe = customMap[idKey] ?? customMap[nameKey];
      recipe ??= catalogMap[idKey] ?? catalogMap[nameKey];
      resolved.add(recipe);
    }
    return resolved;
  }
}
