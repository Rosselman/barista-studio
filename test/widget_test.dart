import 'package:flutter_test/flutter_test.dart';
import 'package:barista_studio/data/preset_catalog.dart';
import 'package:barista_studio/protocol/recipe_packet_builder.dart';

void main() {
  test('PresetCatalog has recipes loaded', () {
    expect(PresetCatalog.presets.isNotEmpty, true);
    expect(PresetCatalog.categories.length, greaterThan(1));
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
