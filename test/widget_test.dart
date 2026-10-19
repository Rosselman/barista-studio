import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barista_studio/data/preset_catalog.dart';
import 'package:barista_studio/models/machine_state.dart';
import 'package:barista_studio/models/phase.dart';
import 'package:barista_studio/models/recipe.dart';
import 'package:barista_studio/models/recipe_step.dart';
import 'package:barista_studio/protocol/crc16.dart';
import 'package:barista_studio/protocol/recipe_packet_builder.dart';
import 'package:barista_studio/services/storage_service.dart';

void main() {
  test('PresetCatalog has recipes loaded with required categories', () {
    expect(PresetCatalog.presets.length, greaterThanOrEqualTo(50));
    expect(PresetCatalog.categories.contains('Multi-Step'), true);
    expect(PresetCatalog.categories.contains('Non-Coffee'), true);
    expect(PresetCatalog.categories.contains('Dairy'), true);
    expect(PresetCatalog.categories.contains('Non-Dairy'), true);
    expect(PresetCatalog.categories.contains('Cold Foam & Textures'), true);
  });

  test('All preset recipes have unique UUIDs, unique names, and valid hardware names', () {
    final ids = <String>{};
    final names = <String>{};
    for (final r in PresetCatalog.presets) {
      expect(ids.contains(r.id.toLowerCase()), false, reason: 'Duplicate ID: ${r.id}');
      ids.add(r.id.toLowerCase());
      expect(names.contains(r.name.toLowerCase()), false, reason: 'Duplicate Recipe Name: ${r.name}');
      names.add(r.name.toLowerCase());
      expect(r.hardwareName.length, lessThanOrEqualTo(16), reason: 'Hardware name too long: ${r.name}');
      expect(r.hardwareName.isNotEmpty, true);
      expect(r.steps.isNotEmpty, true);
      for (final s in r.steps) {
        expect(s.phases.length, lessThanOrEqualTo(3), reason: 'Step ${s.name} in ${r.name} has >3 phases');
        for (final p in s.phases) {
          expect(p.speed >= 300 && p.speed <= 4000, true);
          expect(p.temp >= 0 && p.temp <= 70, true);
          expect(p.duration >= 0 && p.duration <= 240, true);
        }
      }
    }
  });

  test('Multi-Step recipes in PresetCatalog are properly configured', () {
    final multiStep = PresetCatalog.presets.where((r) => r.isMultiStep).toList();
    expect(multiStep.length, 19);
    for (final r in multiStep) {
      expect(r.stepCount, greaterThanOrEqualTo(2));
      expect(r.steps[0].phases.isNotEmpty, true);
      expect(r.steps[1].phases.isNotEmpty, true);
      expect(r.tags.contains('Multi-Step'), true);
    }

    // Ensure no single-step recipes are accidentally tagged Multi-Step
    final singleStep = PresetCatalog.presets.where((r) => !r.isMultiStep).toList();
    for (final r in singleStep) {
      expect(r.tags.contains('Multi-Step'), false, reason: '${r.name} tagged Multi-Step but has stepCount < 2');
    }
  });

  test('Recipe filtering by categories and tags works correctly', () {
    final multiStep = PresetCatalog.presets
        .where((r) => r.category == 'Multi-Step' || r.tags.contains('Multi-Step'))
        .toList();
    expect(multiStep.length, greaterThanOrEqualTo(10));

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

  test('RecipePacketBuilder creates valid multi-step binary packet', () {
    // 2-step recipe test: Latte Double
    // Step 1: cold froth 15s @ 3000 RPM (0°C)
    // Step 2: hot froth 35s @ 2400 RPM (65°C)
    final s1 = RecipeStep(
      name: 'STEP 1',
      phases: [Phase.clamped(speed: 3000, accel: 800, temp: 0, duration: 15)],
    );
    final s2 = RecipeStep(
      name: 'STEP 2',
      phases: [Phase.clamped(speed: 2400, accel: 800, temp: 65, duration: 35)],
    );

    final packet = RecipePacketBuilder.buildPacket(
      isAppend: false,
      targetPos: 1,
      name: 'Latte Double',
      uuidStr: '00000000-0000-0000-0000-000000000000',
      steps: [s1, s2],
    );

    // TargetPos byte = 1
    expect(packet[0], 0x01);
    // Payload length = 58 bytes (0x003A)
    expect(packet[3], 0x00);
    expect(packet[4], 0x3A);
    // Step count = 2 at byte 34
    expect(packet[34], 0x02);

    // Computed CRC must match packet CRC bytes
    final computedCrc = Crc16.compute(packet, 3, packet.length);
    final packetCrc = (packet[1] << 8) | packet[2];
    expect(packetCrc, computedCrc);
  });

  test('StorageService reactive notifications work on save and delete', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);

    int notifications = 0;
    storage.addListener(() {
      notifications++;
    });

    final recipe = Recipe(
      id: 'test-recipe-1234',
      name: 'TEST RECIPE',
      description: 'Initial description',
      category: 'Specialty',
      steps: [
        RecipeStep(
          name: 'STEP 1',
          phases: [Phase.clamped(speed: 3000, accel: 800, temp: 60, duration: 20)],
        ),
      ],
      isCustom: true,
    );

    await storage.saveCustomRecipe(recipe);
    expect(notifications, 1);
    expect(storage.getCustomRecipes().length, 1);

    await storage.updateRecipeDetails(
      'test-recipe-1234',
      description: 'Updated description',
    );
    expect(notifications, 2);
    expect(storage.getCustomRecipes().first.description, 'Updated description');

    await storage.deleteCustomRecipe('test-recipe-1234');
    expect(notifications, 3);
    expect(storage.getCustomRecipes().isEmpty, true);
  });

  test('MachineState correctly decodes hardware firmware states', () {
    // 0: STANDBY (0x00) - Machine in low power / asleep
    expect(MachineState.fromByte(0x00), MachineState.standby);
    expect(MachineState.fromByte(0x00).label, 'Standby');
    expect(MachineState.fromByte(0x00).isStandby, true);

    // 1: READY (0x01) - Machine awake on counter, dial selected
    expect(MachineState.fromByte(0x01), MachineState.ready);
    expect(MachineState.fromByte(0x01).label, 'Ready');
    expect(MachineState.fromByte(0x01).isReady, true);

    // 2: RECIPE_EXECUTING (0x02) - Motor / heater running
    expect(MachineState.fromByte(0x02), MachineState.recipeExecuting);
    expect(MachineState.fromByte(0x02).label, 'Executing');
    expect(MachineState.fromByte(0x02).isExecuting, true);

    // 3: LOCAL_SETTINGS_MODE (0x03) - Settings dial mode
    expect(MachineState.fromByte(0x03), MachineState.localSettingsMode);
    expect(MachineState.fromByte(0x03).label, 'Settings Mode');
    expect(MachineState.fromByte(0x03).isLocalSettings, true);

    // 4: ERROR (0x04)
    expect(MachineState.fromByte(0x04), MachineState.error);
    expect(MachineState.fromByte(0x04).label, 'Error');
    expect(MachineState.fromByte(0x04).isError, true);

    // 5: OVERHEATED (0x05)
    expect(MachineState.fromByte(0x05), MachineState.overheated);
    expect(MachineState.fromByte(0x05).label, 'Overheated');
    expect(MachineState.fromByte(0x05).isOverheated, true);

    // 6: OUT_OF_THE_BOX_SETTINGS (0x06)
    expect(MachineState.fromByte(0x06), MachineState.outOfTheBoxSettings);
    expect(MachineState.fromByte(0x06).label, 'First Setup');
    expect(MachineState.fromByte(0x06).isFirstSetup, true);

    // 7: RECIPE_PAUSED (0x07) - Multi-step pause waiting for button
    expect(MachineState.fromByte(0x07), MachineState.recipePaused);
    expect(MachineState.fromByte(0x07).label, 'Paused (Press Button)');
    expect(MachineState.fromByte(0x07).isPaused, true);
  });

  test('Affogato Cream is configured as a native multi-step recipe', () {
    final affogato = PresetCatalog.presets.firstWhere((r) => r.name == 'Affogato Cream');
    expect(affogato.isMultiStep, true);
    expect(affogato.stepCount, 2);
    expect(affogato.steps.first.name, 'STEP 1');
    expect(affogato.steps.last.name, 'STEP 2');
    expect(affogato.tags.contains('Multi-Step'), true);
  });
}

