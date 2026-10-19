import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/default_loadouts.dart';
import '../models/recipe.dart';
import '../models/wheel_loadout.dart';
import '../protocol/barista_ble_constants.dart';

class StorageService extends ChangeNotifier {
  static const String _keyCmid = 'barista_cmid_key_hex';
  static const String _keyLastMac = 'barista_last_connected_mac';
  static const String _keyCustomRecipes = 'barista_custom_recipes';
  static const String _keyUuidNamePrefix = 'barista_recipe_name_';
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

  // --- UUID to Name Mapping Cache ---
  Future<void> cacheRecipeName(String uuid, String name) async {
    final key = '$_keyUuidNamePrefix${uuid.toLowerCase()}';
    await _prefs.setString(key, name);
  }

  String? getCachedRecipeName(String uuid) {
    final key = '$_keyUuidNamePrefix${uuid.toLowerCase()}';
    return _prefs.getString(key);
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

