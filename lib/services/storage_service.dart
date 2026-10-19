import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/default_loadouts.dart';
import '../data/preset_catalog.dart';
import '../models/recipe.dart';
import '../models/slot_info.dart';
import '../models/wheel_loadout.dart';
import '../protocol/barista_ble_constants.dart';

class StorageService extends ChangeNotifier {
  static const String _keyCmid = 'barista_cmid_key_hex';
  static const String _keyLastMac = 'barista_last_connected_mac';
  static const String _keyCustomRecipes = 'barista_custom_recipes';
  static const String _keyUuidNamePrefix = 'barista_recipe_name_';
  static const String _keyCachedSlotsPrefix = 'barista_cached_slots_';
  static const String _keyFavorites = 'barista_favorite_recipes';
  static const String _keyLoadouts = 'barista_custom_wheel_loadouts';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- CMID Authentication Key ---
  String getCmidKey() {
    return _prefs.getString(_keyCmid) ??
        BaristaBleConstants.defaultPairedCmid;
  }

  Future<bool> setCmidKey(String keyHex) async {
    final res = await _prefs.setString(_keyCmid, keyHex.toUpperCase());
    notifyListeners();
    return res;
  }

  // --- Last Connected MAC ---
  String? getLastConnectedMac() {
    return _prefs.getString(_keyLastMac);
  }

  Future<bool> setLastConnectedMac(String mac) async {
    return _prefs.setString(_keyLastMac, mac);
  }

  // --- Custom Recipes ---
  List<Recipe> getCustomRecipes() {
    final rawList = _prefs.getStringList(_keyCustomRecipes) ?? [];
    final recipes = <Recipe>[];
    for (final raw in rawList) {
      try {
        final Map<String, dynamic> json = jsonDecode(raw);
        recipes.add(Recipe.fromJson(json));
      } catch (e) {
        if (kDebugMode) {
          print('[StorageService] Error decoding custom recipe: $e');
        }
      }
    }
    return recipes;
  }

  Future<bool> saveCustomRecipe(Recipe recipe) async {
    final list = getCustomRecipes();
    final idx = list.indexWhere((r) => r.id == recipe.id);
    if (idx >= 0) {
      list[idx] = recipe;
    } else {
      list.insert(0, recipe);
    }
    // Also store UUID to name map
    await cacheRecipeName(recipe.id, recipe.name);

    final rawList = list.map((r) => jsonEncode(r.toJson())).toList();
    final res = await _prefs.setStringList(_keyCustomRecipes, rawList);
    notifyListeners();
    return res;
  }

  Future<bool> deleteCustomRecipe(String id) async {
    final list = getCustomRecipes();
    list.removeWhere((r) => r.id == id);
    final rawList = list.map((r) => jsonEncode(r.toJson())).toList();
    final res = await _prefs.setStringList(_keyCustomRecipes, rawList);
    notifyListeners();
    return res;
  }

  /// Update metadata such as user-written description, name, or tags for a custom recipe
  Future<bool> updateRecipeDetails(
    String id, {
    String? name,
    String? description,
    List<String>? tags,
  }) async {
    final list = getCustomRecipes();
    final idx = list.indexWhere((r) => r.id == id);
    if (idx < 0) return false;

    final current = list[idx];
    list[idx] = current.copyWith(
      name: name ?? current.name,
      description: description ?? current.description,
      tags: tags ?? current.tags,
    );

    if (name != null) {
      await cacheRecipeName(id, name);
    }

    final rawList = list.map((r) => jsonEncode(r.toJson())).toList();
    final res = await _prefs.setStringList(_keyCustomRecipes, rawList);
    notifyListeners();
    return res;
  }

  // --- UUID to Name Mapping Cache & Comprehensive Recipe Resolver ---
  Future<void> cacheRecipeName(String uuid, String name) async {
    final clean = uuid.replaceAll('-', '').toLowerCase().trim();
    if (clean.isEmpty) return;
    await _prefs.setString('$_keyUuidNamePrefix$clean', name);
    if (uuid != clean) {
      await _prefs.setString('$_keyUuidNamePrefix${uuid.toLowerCase().trim()}', name);
    }
  }

  String? getCachedRecipeName(String uuid) {
    final clean = uuid.replaceAll('-', '').toLowerCase().trim();
    return _prefs.getString('$_keyUuidNamePrefix$clean') ??
        _prefs.getString('$_keyUuidNamePrefix${uuid.toLowerCase().trim()}');
  }

  /// Comprehensive recipe name resolver:
  /// 1. Checks SharedPreferences cache by normalized UUID
  /// 2. Checks PresetCatalog presets
  /// 3. Checks saved Custom Recipes in StorageService
  /// 4. Checks built-in Default Loadouts recipes
  /// Automatically populates cache on match for fast O(1) subsequent lookups.
  String? resolveRecipeName(String uuid) {
    final clean = uuid.replaceAll('-', '').toLowerCase().trim();
    if (clean.isEmpty) return null;

    // 1. Direct cache lookup
    final cached = getCachedRecipeName(uuid);
    if (cached != null && cached.trim().isNotEmpty) {
      return cached.trim();
    }

    // 2. Preset catalog
    final preset = PresetCatalog.findByUuid(uuid);
    if (preset != null) {
      cacheRecipeName(uuid, preset.name);
      return preset.name;
    }

    // 3. User custom recipes
    for (final custom in getCustomRecipes()) {
      if (custom.id.replaceAll('-', '').toLowerCase().trim() == clean) {
        cacheRecipeName(uuid, custom.name);
        return custom.name;
      }
    }

    // 4. Default Loadouts
    for (final loadout in DefaultLoadouts.defaults) {
      for (final entry in loadout.slots) {
        if (entry.recipeId.replaceAll('-', '').toLowerCase().trim() == clean) {
          cacheRecipeName(uuid, entry.recipeName);
          return entry.recipeName;
        }
      }
    }

    return null;
  }

  /// Comprehensive Recipe model resolver:
  /// Resolves the full Recipe model from UUID or recipe name across PresetCatalog,
  /// user Custom Recipes, and Default Loadouts.
  Recipe? resolveRecipe({String? uuid, String? name}) {
    if (uuid != null && uuid.trim().isNotEmpty) {
      final clean = uuid.replaceAll('-', '').toLowerCase().trim();
      final preset = PresetCatalog.findByUuid(clean);
      if (preset != null) return preset;

      for (final custom in getCustomRecipes()) {
        if (custom.id.replaceAll('-', '').toLowerCase().trim() == clean) {
          return custom;
        }
      }

      for (final loadout in DefaultLoadouts.defaults) {
        for (final entry in loadout.slots) {
          if (entry.recipeId.replaceAll('-', '').toLowerCase().trim() == clean) {
            final fromCatalog = PresetCatalog.findByUuid(entry.recipeId);
            if (fromCatalog != null) return fromCatalog;
          }
        }
      }
    }

    if (name != null && name.trim().isNotEmpty) {
      final cleanName = name.toLowerCase().trim();
      final preset = PresetCatalog.findByName(cleanName);
      if (preset != null) return preset;

      for (final custom in getCustomRecipes()) {
        if (custom.name.toLowerCase().trim() == cleanName) {
          return custom;
        }
      }

      for (final loadout in DefaultLoadouts.defaults) {
        for (final entry in loadout.slots) {
          if (entry.recipeName.toLowerCase().trim() == cleanName) {
            final fromCatalog = PresetCatalog.findByUuid(entry.recipeId);
            if (fromCatalog != null) return fromCatalog;
          }
        }
      }
    }

    return null;
  }

  // --- Hardware Memory / Cached Slot Table ---
  List<SlotInfo>? getCachedSlots(String? macAddress) {
    if (macAddress == null || macAddress.isEmpty) return null;
    final cleanMac = macAddress.replaceAll(':', '').toUpperCase().trim();
    final rawList = _prefs.getStringList('$_keyCachedSlotsPrefix$cleanMac');
    if (rawList == null || rawList.length != 13) return null;
    try {
      final list = <SlotInfo>[];
      for (int i = 0; i < rawList.length; i++) {
        final Map<String, dynamic> json = jsonDecode(rawList[i]);
        list.add(SlotInfo(
          slotIndex: json['slotIndex'] as int? ?? i,
          isOccupied: json['isOccupied'] as bool? ?? false,
          recipeUuid: json['recipeUuid'] as String?,
          recipeName: json['recipeName'] as String? ?? 'Slot ${i + 1}',
          crc: json['crc'] as int?,
        ));
      }
      return list;
    } catch (e) {
      if (kDebugMode) {
        print('[StorageService] Error decoding cached slots for $macAddress: $e');
      }
      return null;
    }
  }

  Future<void> saveCachedSlots(String? macAddress, List<SlotInfo> slots) async {
    if (macAddress == null || macAddress.isEmpty || slots.length != 13) return;
    final cleanMac = macAddress.replaceAll(':', '').toUpperCase().trim();
    final rawList = slots.map((s) => jsonEncode({
      'slotIndex': s.slotIndex,
      'isOccupied': s.isOccupied,
      'recipeUuid': s.recipeUuid,
      'recipeName': s.recipeName,
      'crc': s.crc,
    })).toList();
    await _prefs.setStringList('$_keyCachedSlotsPrefix$cleanMac', rawList);
  }

  // --- Favorite Recipes ---
  Set<String> getFavorites() {
    final list = _prefs.getStringList(_keyFavorites) ?? [];
    return list.toSet();
  }

  bool isFavorite(String recipeId) {
    return getFavorites().contains(recipeId);
  }

  Future<bool> toggleFavorite(String recipeId) async {
    final current = getFavorites();
    if (current.contains(recipeId)) {
      current.remove(recipeId);
    } else {
      current.add(recipeId);
    }
    final res = await _prefs.setStringList(_keyFavorites, current.toList());
    notifyListeners();
    return res;
  }

  // --- Wheel Loadouts (Profiles) ---
  List<WheelLoadout> getCustomLoadouts() {
    final rawList = _prefs.getStringList(_keyLoadouts) ?? [];
    final loadouts = <WheelLoadout>[];
    for (final raw in rawList) {
      try {
        final Map<String, dynamic> json = jsonDecode(raw);
        loadouts.add(WheelLoadout.fromJson(json));
      } catch (e) {
        if (kDebugMode) {
          print('[StorageService] Error decoding custom loadout: $e');
        }
      }
    }
    return loadouts;
  }

  /// Returns both built-in curated defaults and user-created custom loadouts
  List<WheelLoadout> getAllLoadouts() {
    final custom = getCustomLoadouts();
    return [
      ...DefaultLoadouts.defaults,
      ...custom,
    ];
  }

  Future<bool> saveLoadout(WheelLoadout loadout) async {
    final list = getCustomLoadouts();
    final idx = list.indexWhere((l) => l.id == loadout.id);
    if (idx >= 0) {
      list[idx] = loadout;
    } else {
      list.insert(0, loadout);
    }

    final rawList = list.map((l) => jsonEncode(l.toJson())).toList();
    final res = await _prefs.setStringList(_keyLoadouts, rawList);
    notifyListeners();
    return res;
  }

  Future<bool> deleteLoadout(String id) async {
    final list = getCustomLoadouts();
    list.removeWhere((l) => l.id == id);
    final rawList = list.map((l) => jsonEncode(l.toJson())).toList();
    final res = await _prefs.setStringList(_keyLoadouts, rawList);
    notifyListeners();
    return res;
  }
}

