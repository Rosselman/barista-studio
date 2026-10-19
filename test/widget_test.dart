import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barista_studio/data/default_loadouts.dart';
import 'package:barista_studio/data/preset_catalog.dart';
import 'package:barista_studio/models/machine_state.dart';
import 'package:barista_studio/models/phase.dart';
import 'package:barista_studio/models/recipe.dart';
import 'package:barista_studio/models/recipe_step.dart';
import 'package:barista_studio/models/slot_info.dart';
import 'package:barista_studio/models/wheel_loadout.dart';
import 'package:barista_studio/protocol/crc16.dart';
import 'package:barista_studio/protocol/recipe_packet_builder.dart';
import 'package:barista_studio/services/barista_ble_service.dart';
import 'package:barista_studio/services/storage_service.dart';
import 'package:barista_studio/theme/app_theme.dart';
import 'package:barista_studio/ui/widgets/recipe_detail_dialog.dart';

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

  test('DefaultLoadouts contains curated 13-slot profiles and resolves properly', () {
    expect(DefaultLoadouts.defaults.length, 3);

    final summer = DefaultLoadouts.summerIcedWheel;
    expect(summer.name, 'Summer Iced Wheel');
    expect(summer.slots.length, 13);
    final resolvedSummer = summer.resolveRecipes([]);
    expect(resolvedSummer.where((r) => r != null).length, 13);

    final winter = DefaultLoadouts.winterWarmers;
    expect(winter.name, 'Winter Warmers');
    expect(winter.slots.length, 13);
    final resolvedWinter = winter.resolveRecipes([]);
    expect(resolvedWinter.where((r) => r != null).length, 13);

    final guests = DefaultLoadouts.houseGuests;
    expect(guests.name, 'House Guests');
    expect(guests.slots.length, 13);
    final resolvedGuests = guests.resolveRecipes([]);
    expect(resolvedGuests.where((r) => r != null).length, 13);
  });

  test('WheelLoadout serialization roundtrip works correctly', () {
    final loadout = WheelLoadout.create(
      name: 'Custom Party Loadout',
      description: 'Favorite party drinks',
      slots: [
        const LoadoutSlotEntry(slotIndex: 0, recipeId: 'rec-1', recipeName: 'Drink 1'),
        const LoadoutSlotEntry(slotIndex: 1, recipeId: 'rec-2', recipeName: 'Drink 2', isCustom: true),
      ],
    );

    final json = loadout.toJson();
    final restored = WheelLoadout.fromJson(json);

    expect(restored.name, 'Custom Party Loadout');
    expect(restored.description, 'Favorite party drinks');
    expect(restored.slots.length, 2);
    expect(restored.slots[0].slotIndex, 0);
    expect(restored.slots[0].recipeName, 'Drink 1');
    expect(restored.slots[1].isCustom, true);
  });

  test('StorageService favorites management and persistence work reactively', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    int notificationCount = 0;
    storage.addListener(() => notificationCount++);

    expect(storage.getFavorites().isEmpty, true);
    expect(storage.isFavorite('test-recipe-1'), false);

    // Toggle ON
    await storage.toggleFavorite('test-recipe-1');
    expect(storage.isFavorite('test-recipe-1'), true);
    expect(storage.getFavorites().contains('test-recipe-1'), true);
    expect(notificationCount, 1);

    // Toggle OFF
    await storage.toggleFavorite('test-recipe-1');
    expect(storage.isFavorite('test-recipe-1'), false);
    expect(storage.getFavorites().isEmpty, true);
    expect(notificationCount, 2);
  });

  test('Favorites pinned sorting places favorited recipes at top of list', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    final r1 = PresetCatalog.presets[0];
    final r2 = PresetCatalog.presets[1];
    final r3 = PresetCatalog.presets[2];

    // Favoriting the 3rd recipe
    await storage.toggleFavorite(r3.id);

    final list = [r1, r2, r3];
    list.sort((a, b) {
      final aFav = storage.isFavorite(a.id);
      final bFav = storage.isFavorite(b.id);
      if (aFav && !bFav) return -1;
      if (!aFav && bFav) return 1;
      return 0;
    });

    expect(list.first.id, r3.id);
    expect(list[1].id, r1.id);
    expect(list[2].id, r2.id);
  });

  test('StorageService custom wheel loadouts persistence and defaults work', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    // Defaults are always included
    final all = storage.getAllLoadouts();
    expect(all.length, greaterThanOrEqualTo(3));
    expect(storage.getCustomLoadouts().isEmpty, true);

    // Save a custom loadout
    final custom = WheelLoadout.create(
      name: 'My Special Wheel',
      slots: [
        const LoadoutSlotEntry(slotIndex: 0, recipeId: 'rec-1', recipeName: 'Recipe 1'),
      ],
    );

    await storage.saveLoadout(custom);
    expect(storage.getCustomLoadouts().length, 1);
    expect(storage.getAllLoadouts().length, all.length + 1);

    // Delete custom loadout
    await storage.deleteLoadout(custom.id);
    expect(storage.getCustomLoadouts().isEmpty, true);
    expect(storage.getAllLoadouts().length, all.length);
  });

  test('PresetCatalog.findByUuid matches with and without hyphens, case-insensitively', () {
    const rawHyphen = '6450bd62-b706-44e7-8b67-7063ec64a492'; // Cappuccino
    final unhyphenated = rawHyphen.replaceAll('-', '').toUpperCase();

    final match1 = PresetCatalog.findByUuid(rawHyphen);
    expect(match1, isNotNull);
    expect(match1!.name, 'Cappuccino');

    final match2 = PresetCatalog.findByUuid(unhyphenated);
    expect(match2, isNotNull);
    expect(match2!.name, 'Cappuccino');

    final nonExistent = PresetCatalog.findByUuid('00000000-0000-0000-0000-000000000000');
    expect(nonExistent, isNull);
  });

  test('StorageService.resolveRecipeName resolves presets, custom recipes, and caches cleanly', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    // 1. Resolve preset recipe
    final resolvedPreset = storage.resolveRecipeName('d4648f3a-7a66-4e51-bb3d-848ed1176709');
    expect(resolvedPreset, 'Latte Macchiato');

    // 2. Resolve custom recipe
    final customRecipe = Recipe(
      id: 'e1e2e3e4-a1a2-b1b2-c1c2-d1d2d3d4d5d6',
      name: 'Artisan Hazelnut Cloud',
      description: 'Rich hazelnut infused foam',
      category: 'Cold Foam & Textures',
      phases: [Phase.clamped(speed: 2500, accel: 600, temp: 55, duration: 20)],
    );
    await storage.saveCustomRecipe(customRecipe);

    // Resolve with unhyphenated uppercase UUID
    final resolvedCustom = storage.resolveRecipeName('E1E2E3E4A1A2B1B2C1C2D1D2D3D4D5D6');
    expect(resolvedCustom, 'Artisan Hazelnut Cloud');

    // 3. Resolve unknown UUID
    final resolvedUnknown = storage.resolveRecipeName('99999999-9999-9999-9999-999999999999');
    expect(resolvedUnknown, isNull);
  });

  test('StorageService slot caching roundtrip preserves 13 hardware slots', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    const mac = '19:10:7D:71:4A:E9';

    expect(storage.getCachedSlots(mac), isNull);

    final testSlots = List.generate(
      13,
      (i) => i == 0
          ? const SlotInfo(
              slotIndex: 0,
              isOccupied: true,
              recipeName: 'Cappuccino',
              recipeUuid: '6450bd62-b706-44e7-8b67-7063ec64a492',
              crc: 0x1234,
            )
          : SlotInfo(slotIndex: i, recipeName: 'Slot ${i + 1} (Empty)', isOccupied: false),
    );

    await storage.saveCachedSlots(mac, testSlots);
    final cached = storage.getCachedSlots(mac);

    expect(cached, isNotNull);
    expect(cached!.length, 13);
    expect(cached[0].isOccupied, true);
    expect(cached[0].recipeName, 'Cappuccino');
    expect(cached[0].recipeUuid, '6450bd62-b706-44e7-8b67-7063ec64a492');
    expect(cached[0].crc, 0x1234);
    expect(cached[1].isOccupied, false);
    expect(cached[12].isOccupied, false);
  });

  test('PresetCatalog.findByName matches case-insensitively and returns correct Recipe', () {
    final r1 = PresetCatalog.findByName('Cappuccino');
    expect(r1, isNotNull);
    expect(r1!.name, 'Cappuccino');

    final r2 = PresetCatalog.findByName('cappuccino');
    expect(r2, isNotNull);
    expect(r2!.name, 'Cappuccino');

    final r3 = PresetCatalog.findByName('non existent drink');
    expect(r3, isNull);
  });

  test('StorageService.resolveRecipe resolves full model by uuid and name', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    // 1. Resolve preset by UUID
    final p1 = storage.resolveRecipe(uuid: '6450bd62-b706-44e7-8b67-7063ec64a492');
    expect(p1, isNotNull);
    expect(p1!.name, 'Cappuccino');

    // 2. Resolve preset by Name
    final p2 = storage.resolveRecipe(name: 'Latte Macchiato');
    expect(p2, isNotNull);
    expect(p2!.id, 'd4648f3a-7a66-4e51-bb3d-848ed1176709');

    // 3. Resolve custom recipe by Name
    final custom = Recipe(
      id: 'c0ffee00-1111-2222-3333-444455556666',
      name: 'Custom Cold Brew Delight',
      description: 'Special chilled foam',
      category: 'Iced & Cold Coffee',
      phases: [Phase.clamped(speed: 1800, accel: 500, temp: 20, duration: 25)],
    );
    await storage.saveCustomRecipe(custom);

    final resolvedCustom = storage.resolveRecipe(name: 'custom cold brew delight');
    expect(resolvedCustom, isNotNull);
    expect(resolvedCustom!.id, 'c0ffee00-1111-2222-3333-444455556666');
  });

  test('Multi-step recipes correctly configure Step 2 with instructions and parameters', () {
    final affogato = PresetCatalog.presets.firstWhere((r) => r.name == 'Affogato Cream');
    expect(affogato.isMultiStep, true);
    expect(affogato.steps.length, greaterThanOrEqualTo(2));

    final step2 = affogato.steps[1];
    expect(step2.name, 'STEP 2');
    expect(step2.instruction, isNotNull);
    expect(step2.instruction!.contains('heavy cream'), true);
    expect(step2.totalDurationSeconds, 25);
    expect(step2.maxTemp, 68);
    expect(step2.peakRpm, 2100);
  });

  testWidgets('RecipeDetailDialog renders Affogato Cream without overflow on small screens', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final ble = BaristaBleService(storageService: storage);

    final affogato = PresetCatalog.presets.firstWhere((r) => r.name == 'Affogato Cream');

    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: RecipeDetailDialog(
            recipe: affogato,
            bleService: ble,
          ),
        ),
      ),
    );

    expect(find.text('Affogato Cream'), findsOneWidget);
    expect(find.text('Multi-Step (2 Steps)'), findsOneWidget);
    expect(find.text('Hot Coffee'), findsOneWidget);
    expect(find.text('Dairy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}


