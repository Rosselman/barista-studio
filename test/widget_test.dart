import 'package:flutter_test/flutter_test.dart';
import 'package:barista_studio/data/preset_catalog.dart';
import 'package:barista_studio/protocol/recipe_packet_builder.dart';

void main() {
  test('PresetCatalog has recipes loaded with required categories', () {
    expect(PresetCatalog.presets.length, greaterThanOrEqualTo(40));
    expect(PresetCatalog.categories.contains('Non-Coffee'), true);
    expect(PresetCatalog.categories.contains('Dairy'), true);
    expect(PresetCatalog.categories.contains('Non-Dairy'), true);
    expect(PresetCatalog.categories.contains('Cold Foam & Textures'), true);
  });

  test('All preset recipes have unique UUIDs and valid hardware names', () {
    final ids = <String>{};
    for (final r in PresetCatalog.presets) {
      expect(ids.contains(r.id.toLowerCase()), false, reason: 'Duplicate ID: ${r.id}');
      ids.add(r.id.toLowerCase());
      expect(r.hardwareName.length, lessThanOrEqualTo(16), reason: 'Hardware name too long: ${r.name}');
      expect(r.hardwareName.isNotEmpty, true);
      expect(r.phases.isNotEmpty, true);
      expect(r.phases.length, lessThanOrEqualTo(3));
      for (final p in r.phases) {
        expect(p.speed >= 300 && p.speed <= 4000, true);
        expect(p.temp >= 0 && p.temp <= 70, true);
        expect(p.duration >= 0 && p.duration <= 90, true);
      }
    }
  });

  test('Recipe filtering by categories and tags works correctly', () {
    final nonCoffee = PresetCatalog.presets
        .where((r) => r.category == 'Non-Coffee' || r.tags.contains('Non-Coffee'))
        .toList();
    expect(nonCoffee.length, greaterThanOrEqualTo(10));

    final dairy = PresetCatalog.presets
        .where((r) => r.category == 'Dairy' || r.tags.contains('Dairy'))
        .toList();
    expect(dairy.length, greaterThanOrEqualTo(15));

    final nonDairy = PresetCatalog.presets
        .where((r) => r.category == 'Non-Dairy' || r.tags.contains('Non-Dairy'))
        .toList();
    expect(nonDairy.length, greaterThanOrEqualTo(8));

    final coldFoam = PresetCatalog.presets
        .where((r) => r.category == 'Cold Foam & Textures' || r.tags.contains('Cold Foam & Textures'))
        .toList();
    expect(coldFoam.length, greaterThanOrEqualTo(10));
  });

  test('RecipePacketBuilder creates valid binary packet', () {
    final recipe = PresetCatalog.presets.first;
    final packet = RecipePacketBuilder.buildPacket(
      isAppend: true,
      targetPos: 1,
      name: recipe.hardwareName,
      uuidStr: recipe.id,
      phases: recipe.phases,
    );
    expect(packet.isNotEmpty, true);
  });
}
