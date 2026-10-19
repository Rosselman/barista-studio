import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/recipe.dart';

class RecipeShareService {
  static const String uriScheme = 'baristastudio';
  static const String uriHostRecipe = 'recipe';

  /// Encodes a recipe into a compact, compressed `baristastudio://recipe?data=...` link.
  static String encodeShareUrl(Recipe recipe) {
    final Map<String, dynamic> data = recipe.toJson();
    final jsonStr = jsonEncode(data);
    final compressed = gzip.encode(utf8.encode(jsonStr));
    final base64Str = base64UrlEncode(compressed);
    return '$uriScheme://$uriHostRecipe?data=$base64Str';
  }

  /// Decodes a share link, URI, raw base64 string, or raw JSON into a valid Recipe.
  /// Automatically gives imported recipes a fresh unique UUID and marks isCustom = true.
  static Recipe? decodeShareUrl(String input) {
    try {
      final raw = input.trim();
      if (raw.isEmpty) return null;

      String payload = raw;

      // Handle custom URI scheme or web links
      if (raw.startsWith('$uriScheme://') ||
          raw.startsWith('http://') ||
          raw.startsWith('https://')) {
        final uri = Uri.tryParse(raw);
        if (uri != null) {
          if (uri.queryParameters.containsKey('data')) {
            payload = uri.queryParameters['data']!;
          } else if (uri.pathSegments.isNotEmpty) {
            payload = uri.pathSegments.last;
          }
        }
      }

      // Handle raw JSON object directly
      if (payload.startsWith('{') && payload.endsWith('}')) {
        final Map<String, dynamic> json = jsonDecode(payload);
        return Recipe.fromJson(json).copyWith(
          id: const Uuid().v4(),
          isCustom: true,
        );
      }

      // Base64 decoding (support both URL-safe and standard with padding normalizer)
      final normalized = base64.normalize(payload);
      List<int> bytes;
      try {
        bytes = base64Url.decode(normalized);
      } catch (_) {
        bytes = base64.decode(normalized);
      }

      // Gzip decompression (magic header: 0x1f, 0x8b)
      List<int> decompressed;
      if (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
        decompressed = gzip.decode(bytes);
      } else {
        decompressed = bytes;
      }

      final jsonStr = utf8.decode(decompressed);
      final Map<String, dynamic> json = jsonDecode(jsonStr);
      return Recipe.fromJson(json).copyWith(
        id: const Uuid().v4(),
        isCustom: true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Exports a list of custom recipes into a formatted JSON backup string.
  static String exportRecipesJson(List<Recipe> recipes) {
    final Map<String, dynamic> backup = {
      'format': 'barista_studio_recipes_v1',
      'exportedAt': DateTime.now().toIso8601String(),
      'count': recipes.length,
      'recipes': recipes.map((r) => r.toJson()).toList(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backup);
  }

  /// Imports recipes from a JSON string.
  /// Supports:
  /// - Full backup object: `{"format": "...", "recipes": [...]}`
  /// - Generic object with customRecipes: `{"customRecipes": [...]}`
  /// - Raw array of recipes: `[{...}, {...}]`
  /// - Single recipe object: `{"name": "...", "steps": [...]}`
  static List<Recipe> importRecipesFromJson(String jsonString) {
    final clean = jsonString.trim();
    if (clean.isEmpty) return [];

    try {
      final dynamic decoded = jsonDecode(clean);
      final List<Recipe> results = [];

      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            results.add(Recipe.fromJson(item).copyWith(
              id: const Uuid().v4(),
              isCustom: true,
            ));
          }
        }
      } else if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('recipes') && decoded['recipes'] is List) {
          for (final item in decoded['recipes'] as List) {
            if (item is Map<String, dynamic>) {
              results.add(Recipe.fromJson(item).copyWith(
                id: const Uuid().v4(),
                isCustom: true,
              ));
            }
          }
        } else if (decoded.containsKey('customRecipes') && decoded['customRecipes'] is List) {
          for (final item in decoded['customRecipes'] as List) {
            if (item is Map<String, dynamic>) {
              results.add(Recipe.fromJson(item).copyWith(
                id: const Uuid().v4(),
                isCustom: true,
              ));
            }
          }
        } else if (decoded.containsKey('name')) {
          // Single recipe object
          results.add(Recipe.fromJson(decoded).copyWith(
            id: const Uuid().v4(),
            isCustom: true,
          ));
        }
      }

      return results;
    } catch (_) {
      return [];
    }
  }
}
