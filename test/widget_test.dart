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
import 'package:barista_studio/services/recipe_share_service.dart';
import 'package:barista_studio/services/storage_service.dart';
import 'package:barista_studio/theme/app_theme.dart';
import 'package:barista_studio/ui/tabs/custom_recipe_tab.dart';
import 'package:barista_studio/ui/tabs/presets_tab.dart';
import 'package:barista_studio/ui/widgets/about_dialog.dart';
import 'package:barista_studio/ui/widgets/developer_dialog.dart';
import 'package:barista_studio/ui/widgets/flash_recipe_dialog.dart';
import 'package:barista_studio/ui/widgets/loadout_manager_dialog.dart';
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

  test(
      'All preset recipes have unique UUIDs, unique names, and valid hardware names',
      () {
    final ids = <String>{};
    final names = <String>{};
    for (final r in PresetCatalog.presets) {
      expect(ids.contains(r.id.toLowerCase()), false,
          reason: 'Duplicate ID: ${r.id}');
      ids.add(r.id.toLowerCase());
      expect(names.contains(r.name.toLowerCase()), false,
          reason: 'Duplicate Recipe Name: ${r.name}');
      names.add(r.name.toLowerCase());
      expect(r.hardwareName.length, lessThanOrEqualTo(16),
          reason: 'Hardware name too long: ${r.name}');
      expect(r.hardwareName.isNotEmpty, true);
      expect(r.steps.isNotEmpty, true);
      for (final s in r.steps) {
        expect(s.phases.length, lessThanOrEqualTo(3),
            reason: 'Step ${s.name} in ${r.name} has >3 phases');
        for (final p in s.phases) {
          expect(p.speed >= 300 && p.speed <= 4000, true);
          expect(p.temp >= 0 && p.temp <= 70, true);
          expect(p.duration >= 0 && p.duration <= 240, true);
        }
      }
    }
  });

  test('Multi-Step recipes in PresetCatalog are properly configured', () {
    final multiStep =
        PresetCatalog.presets.where((r) => r.isMultiStep).toList();
    expect(multiStep.length, 24);
    for (final r in multiStep) {
      expect(r.stepCount, greaterThanOrEqualTo(2));
      expect(r.steps[0].phases.isNotEmpty, true);
      expect(r.steps[1].phases.isNotEmpty, true);
      expect(r.tags.contains('Multi-Step'), true);
    }

    // Ensure no single-step recipes are accidentally tagged Multi-Step
    final singleStep =
        PresetCatalog.presets.where((r) => !r.isMultiStep).toList();
    for (final r in singleStep) {
      expect(r.tags.contains('Multi-Step'), false,
          reason: '${r.name} tagged Multi-Step but has stepCount < 2');
    }
  });

  test('Recipe filtering by categories and tags works correctly', () {
    final multiStep = PresetCatalog.presets
        .where(
            (r) => r.category == 'Multi-Step' || r.tags.contains('Multi-Step'))
        .toList();
    expect(multiStep.length, greaterThanOrEqualTo(10));

    final nonCoffee = PresetCatalog.presets
        .where(
            (r) => r.category == 'Non-Coffee' || r.tags.contains('Non-Coffee'))
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
        .where((r) =>
            r.category == 'Cold Foam & Textures' ||
            r.tags.contains('Cold Foam & Textures'))
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

  test('StorageService reactive notifications work on save and delete',
      () async {
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
          phases: [
            Phase.clamped(speed: 3000, accel: 800, temp: 60, duration: 20)
          ],
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
    final affogato =
        PresetCatalog.presets.firstWhere((r) => r.name == 'Affogato Cream');
    expect(affogato.isMultiStep, true);
    expect(affogato.stepCount, 2);
    expect(affogato.steps.first.name, 'STEP 1');
    expect(affogato.steps.last.name, 'STEP 2');
    expect(affogato.tags.contains('Multi-Step'), true);
  });

  test(
      'DefaultLoadouts contains curated 13-slot profiles and resolves properly',
      () {
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
        const LoadoutSlotEntry(
            slotIndex: 0, recipeId: 'rec-1', recipeName: 'Drink 1'),
        const LoadoutSlotEntry(
            slotIndex: 1,
            recipeId: 'rec-2',
            recipeName: 'Drink 2',
            isCustom: true),
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

  test('StorageService favorites management and persistence work reactively',
      () async {
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

  test('Favorites pinned sorting places favorited recipes at top of list',
      () async {
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

  test('StorageService custom wheel loadouts persistence and defaults work',
      () async {
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
        const LoadoutSlotEntry(
            slotIndex: 0, recipeId: 'rec-1', recipeName: 'Recipe 1'),
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

  test(
      'PresetCatalog.findByUuid matches with and without hyphens, case-insensitively',
      () {
    const rawHyphen = '6450bd62-b706-44e7-8b67-7063ec64a492'; // Cappuccino
    final unhyphenated = rawHyphen.replaceAll('-', '').toUpperCase();

    final match1 = PresetCatalog.findByUuid(rawHyphen);
    expect(match1, isNotNull);
    expect(match1!.name, 'Cappuccino');

    final match2 = PresetCatalog.findByUuid(unhyphenated);
    expect(match2, isNotNull);
    expect(match2!.name, 'Cappuccino');

    final nonExistent =
        PresetCatalog.findByUuid('00000000-0000-0000-0000-000000000000');
    expect(nonExistent, isNull);
  });

  test(
      'StorageService.resolveRecipeName resolves presets, custom recipes, and caches cleanly',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    // 1. Resolve preset recipe
    final resolvedPreset =
        storage.resolveRecipeName('d4648f3a-7a66-4e51-bb3d-848ed1176709');
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
    final resolvedCustom =
        storage.resolveRecipeName('E1E2E3E4A1A2B1B2C1C2D1D2D3D4D5D6');
    expect(resolvedCustom, 'Artisan Hazelnut Cloud');

    // 3. Resolve unknown UUID
    final resolvedUnknown =
        storage.resolveRecipeName('99999999-9999-9999-9999-999999999999');
    expect(resolvedUnknown, isNull);
  });

  test('StorageService slot caching roundtrip preserves 13 hardware slots',
      () async {
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
          : SlotInfo(
              slotIndex: i,
              recipeName: 'Slot ${i + 1} (Empty)',
              isOccupied: false),
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

  test(
      'PresetCatalog.findByName matches case-insensitively and returns correct Recipe',
      () {
    final r1 = PresetCatalog.findByName('Cappuccino');
    expect(r1, isNotNull);
    expect(r1!.name, 'Cappuccino');

    final r2 = PresetCatalog.findByName('cappuccino');
    expect(r2, isNotNull);
    expect(r2!.name, 'Cappuccino');

    final r3 = PresetCatalog.findByName('non existent drink');
    expect(r3, isNull);
  });

  test('StorageService.resolveRecipe resolves full model by uuid and name',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    // 1. Resolve preset by UUID
    final p1 =
        storage.resolveRecipe(uuid: '6450bd62-b706-44e7-8b67-7063ec64a492');
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

    final resolvedCustom =
        storage.resolveRecipe(name: 'custom cold brew delight');
    expect(resolvedCustom, isNotNull);
    expect(resolvedCustom!.id, 'c0ffee00-1111-2222-3333-444455556666');
  });

  test(
      'Multi-step recipes correctly configure Step 2 with instructions and parameters',
      () {
    final affogato =
        PresetCatalog.presets.firstWhere((r) => r.name == 'Affogato Cream');
    expect(affogato.isMultiStep, true);
    expect(affogato.steps.length, greaterThanOrEqualTo(2));

    // Step 1: unheated crema bloom to prevent base overheating
    final step1 = affogato.steps[0];
    expect(step1.phases.first.temp, 0);
    expect(step1.phases.first.isCold, true);

    // Step 2: velvety warm cream
    final step2 = affogato.steps[1];
    expect(step2.name, 'STEP 2');
    expect(step2.instruction, isNotNull);
    expect(step2.instruction!.contains('heavy cream'), true);
    expect(step2.totalDurationSeconds, 25);
    expect(step2.maxTemp, 68);
    expect(step2.peakRpm, 2100);
  });

  testWidgets(
      'RecipeDetailDialog renders Affogato Cream without overflow on small screens',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final ble = BaristaBleService(storageService: storage);

    final affogato =
        PresetCatalog.presets.firstWhere((r) => r.name == 'Affogato Cream');

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

  testWidgets(
      'FlashRecipeDialog handles full memory without overflow in portrait',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    // Cache 13 occupied slots so bleService initializes with full memory
    final fullSlots = List.generate(
      13,
      (i) => SlotInfo(
        slotIndex: i,
        isOccupied: true,
        recipeName: 'Preset Recipe ${i + 1}',
        recipeUuid: '00000000-0000-0000-0000-${i.toString().padLeft(12, '0')}',
      ),
    );
    const testMac = 'AA:BB:CC:DD:EE:FF';
    await storage.setLastConnectedMac(testMac);
    await storage.saveCachedSlots(testMac, fullSlots);

    final ble = BaristaBleService(storageService: storage);
    final cappuccino =
        PresetCatalog.presets.firstWhere((r) => r.name == 'Cappuccino');

    // Narrow portrait phone screen (320px width)
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: FlashRecipeDialog(
            recipe: cappuccino,
            bleService: ble,
          ),
        ),
      ),
    );

    // Memory full alert is visible
    expect(find.textContaining('Hardware memory full (13/13)'), findsOneWidget);
    // Auto-append option is hidden
    expect(find.text('Next Available Slot (Auto-Append)'), findsNothing);
    // Overwrite Slot 1 is displayed on the button
    expect(find.text('Overwrite Slot 1'), findsOneWidget);
    // No layout overflow exception thrown
    expect(tester.takeException(), isNull);
  });

  test('RecipeShareService encodes and decodes baristastudio:// URI roundtrip',
      () {
    final cappuccino =
        PresetCatalog.presets.firstWhere((r) => r.name == 'Cappuccino');
    final shareUrl = RecipeShareService.encodeShareUrl(cappuccino);

    expect(shareUrl.startsWith('baristastudio://recipe?data='), isTrue);

    final decoded = RecipeShareService.decodeShareUrl(shareUrl);
    expect(decoded, isNotNull);
    expect(decoded!.name, 'Cappuccino');
    expect(decoded.isCustom, isTrue);
    expect(decoded.phases.length, cappuccino.phases.length);
    expect(decoded.phases[0].speed, cappuccino.phases[0].speed);
    expect(decoded.phases[0].temp, cappuccino.phases[0].temp);
  });

  test('RecipeShareService decodes path URIs, raw base64, and raw JSON', () {
    final original =
        PresetCatalog.presets.firstWhere((r) => r.name == 'Cold Shakerato');
    final fullUrl = RecipeShareService.encodeShareUrl(original);
    final rawData = Uri.parse(fullUrl).queryParameters['data']!;

    // Path segment format: baristastudio://recipe/<payload>
    final fromPath =
        RecipeShareService.decodeShareUrl('baristastudio://recipe/$rawData');
    expect(fromPath, isNotNull);
    expect(fromPath!.name, 'Cold Shakerato');

    // Raw payload directly
    final fromRaw = RecipeShareService.decodeShareUrl(rawData);
    expect(fromRaw, isNotNull);
    expect(fromRaw!.name, 'Cold Shakerato');

    // Raw JSON object directly
    const rawJson =
        '{"name":"Pasted JSON Recipe","phases":[{"speed":1800,"accel":500,"temp":60,"duration":30}]}';
    final fromJson = RecipeShareService.decodeShareUrl(rawJson);
    expect(fromJson, isNotNull);
    expect(fromJson!.name, 'Pasted JSON Recipe');
    expect(fromJson.phases[0].speed, 1800);
  });

  test('RecipeShareService JSON bulk export and import roundtrip', () {
    final recipes = [
      Recipe(
        id: '11111111-1111-1111-1111-111111111111',
        name: 'Custom Velvet',
        description: 'Velvety milk test',
        category: 'Custom',
        phases: [
          Phase.clamped(speed: 2400, accel: 800, temp: 65, duration: 40)
        ],
        ingredients: ['150ml Whole Milk'],
        instructions: ['Pour cold milk into jug', 'Press start'],
      ),
      Recipe(
        id: '22222222-2222-2222-2222-222222222222',
        name: 'Chilled Foam',
        description: 'Cold foam test',
        category: 'Cold',
        phases: [
          Phase.clamped(speed: 3000, accel: 1000, temp: 0, duration: 25)
        ],
      ),
    ];

    final jsonStr = RecipeShareService.exportRecipesJson(recipes);
    expect(jsonStr.contains('barista_studio_recipes_v1'), isTrue);
    expect(jsonStr.contains('Custom Velvet'), isTrue);
    expect(jsonStr.contains('Chilled Foam'), isTrue);

    // Import from backup object format
    final imported = RecipeShareService.importRecipesFromJson(jsonStr);
    expect(imported.length, 2);
    expect(imported[0].name, 'Custom Velvet');
    expect(imported[0].ingredients.length, 1);
    expect(imported[1].name, 'Chilled Foam');
    expect(imported[1].isCold, isTrue);

    // Import from raw array format
    const rawArrayJson =
        '[{"name":"Array Recipe 1"},{"name":"Array Recipe 2"}]';
    final fromArray = RecipeShareService.importRecipesFromJson(rawArrayJson);
    expect(fromArray.length, 2);
    expect(fromArray[0].name, 'Array Recipe 1');
    expect(fromArray[1].name, 'Array Recipe 2');
  });

  testWidgets(
      'RecipeDetailDialog presents shared recipe preview and 1-tap Save to My Recipes',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final ble = BaristaBleService(storageService: storage);

    final sharedRecipe = Recipe(
      id: 'shared-test-id',
      name: 'Shared Flat White',
      description: 'Velvety flat white from link',
      category: 'Specialty',
      phases: [Phase.clamped(speed: 2200, accel: 600, temp: 65, duration: 35)],
    );

    bool savedCallbackTriggered = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: RecipeDetailDialog(
            recipe: sharedRecipe,
            bleService: ble,
            storageService: storage,
            isSharedImport: true,
            onSavedToMyRecipes: () {
              savedCallbackTriggered = true;
            },
          ),
        ),
      ),
    );

    // Shared recipe preview banner is displayed
    expect(find.text('SHARED RECIPE PREVIEW'), findsOneWidget);
    expect(find.textContaining('Imported from a shared link'), findsOneWidget);

    // 1-Tap Save button is rendered
    final saveButton = find.text('Save to My Recipes');
    expect(saveButton, findsOneWidget);

    // Tap Save to My Recipes
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verified saved in storage
    final savedList = storage.getCustomRecipes();
    expect(savedList.any((r) => r.name == 'Shared Flat White'), isTrue);
    expect(savedCallbackTriggered, isTrue);
  });

  test('New dual-stage multi-step presets froth separately and unite at end',
      () {
    final duoNames = [
      'Duo Iced Cappa',
      'Mocha Duo Fusion',
      'Matcha Cloud Duo',
      'Cortado Duo',
      'Choco Cold Brew',
    ];

    for (final name in duoNames) {
      final recipe = PresetCatalog.findByName(name);
      expect(recipe, isNotNull, reason: '$name not found');
      expect(recipe!.isMultiStep, isTrue);
      expect(recipe.stepCount, 2);
      expect(recipe.hardwareName.length, lessThanOrEqualTo(16));
      expect(recipe.steps[0].phases.isNotEmpty, isTrue);
      expect(recipe.steps[1].phases.isNotEmpty, isTrue);
      expect(recipe.steps[0].instruction, contains('pour into'));
      expect(recipe.steps[1].instruction, contains('unite'));
    }
  });

  testWidgets(
      'Guided Barista Mode formulates dual-stage multi-step recipes and transfers to manual',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final ble = BaristaBleService(storageService: storage);

    final tabKey = GlobalKey<CustomRecipeTabState>();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: CustomRecipeTab(
            key: tabKey,
            bleService: ble,
            storageService: storage,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Default is Single-Cycle
    expect(find.text('Preparation Architecture'), findsOneWidget);
    expect(find.text('⚡ Single-Cycle (Standard)'), findsOneWidget);
    expect(find.text('⏸️ Dual-Stage (Froth & Unite)'), findsOneWidget);

    // Switch to Dual-Stage
    await tester.tap(find.text('⏸️ Dual-Stage (Froth & Unite)'));
    await tester.pumpAndSettle();

    // Dual-stage questionnaire cards are displayed
    expect(find.text('Stage 1: First Drink to Froth & Pour to Glass'),
        findsOneWidget);
    expect(find.text('Stage 2: Second Drink to Froth & Unite'), findsOneWidget);

    // Formulated Recipe Preview reflects dual-stage
    expect(
        find.text('Formulated Dual-Stage Recipe (2 Steps ⏸️)'), findsOneWidget);
    expect(find.text('STAGE 1'), findsOneWidget);
    expect(find.text('STAGE 2'), findsOneWidget);
    expect(find.textContaining('Hardware Pause'), findsOneWidget);

    // Verify recipe synthesis has 2 steps
    final state = tabKey.currentState!;
    final synthesized = state.currentRecipe;
    expect(synthesized.isMultiStep, isTrue);
    expect(synthesized.stepCount, 2);
    expect(synthesized.hardwareName.startsWith('DUO'), isTrue);
    expect(
        synthesized.steps[0].instruction, contains('pour into serving glass'));
    expect(synthesized.steps[1].instruction, contains('unite'));

    // Tap "Tune in Manual" to verify transfer to manual mode
    await tester.tap(find.text('Tune in Manual'));
    await tester.pumpAndSettle();

    // Should now be in manual mode with Step 1 and Step 2 preserved
    expect(find.text('Manual Sequencer'), findsOneWidget);
    expect(find.text('Multi-Step Recipe (Hardware Paused Execution)'),
        findsOneWidget);
    expect(state.currentRecipe.isMultiStep, isTrue);
    expect(state.currentRecipe.stepCount, 2);
  });

  testWidgets(
      'Guided Barista Mode single-cycle Formulated Recipe displays polished phase cards and rich description',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final ble = BaristaBleService(storageService: storage);

    final tabKey = GlobalKey<CustomRecipeTabState>();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: CustomRecipeTab(
            key: tabKey,
            bleService: ble,
            storageService: storage,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Default mode is Single-Cycle
    expect(find.text('Preparation Architecture'), findsOneWidget);
    expect(find.text('⚡ Single-Cycle (Standard)'), findsOneWidget);

    // Formulated Recipe Header displays phase count
    expect(
        find.textContaining('Formulated Single-Cycle Profile'), findsOneWidget);

    // Overview Telemetry Bar items
    expect(find.text('Duration'), findsWidgets);
    expect(find.text('Peak Speed'), findsWidgets);
    expect(find.text('Target Temp'), findsWidgets);
    expect(find.text('Structure'), findsWidgets);

    // Formulated Phase cards & badges
    expect(find.text('PHASE 1'), findsOneWidget);
    expect(find.text('PHASE 2'), findsOneWidget);
    expect(find.text('RECIPE DESCRIPTION (MY RECIPES)'), findsOneWidget);
    expect(find.text('ESTIMATED INGREDIENTS'), findsOneWidget);

    // Verify rich description generated by synthesis
    final state = tabKey.currentState!;
    final recipe = state.currentRecipe;
    expect(recipe.isMultiStep, isFalse);
    expect(recipe.description, contains('Artisanal single-cycle craft:'));
    expect(recipe.description.length, greaterThan(30));
    expect(recipe.ingredients, isNotEmpty);
    expect(recipe.instructions, isNotEmpty);

    // Tap "Save to My Recipes"
    await tester.tap(find.text('Save to My Recipes'));
    await tester.pumpAndSettle();

    // Verify stored custom recipe has the rich description
    final customList = storage.getCustomRecipes();
    expect(customList.length, 1);
    final saved = customList.first;
    expect(saved.name, recipe.name);
    expect(saved.description, recipe.description);
    expect(saved.ingredients, isNotEmpty);
    expect(saved.instructions, isNotEmpty);

    // Customize questionnaire: Hot + Oat Milk + Latte Art
    await tester.tap(find.text('🔥 Piping Hot (60-68°C)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🌾 Barista Oat Milk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🌊 Silky Latte Art'));
    await tester.pumpAndSettle();

    final oatRecipe = state.currentRecipe;
    expect(oatRecipe.description, contains('barista oat milk'));
    expect(oatRecipe.description, contains('silky, pourable microfoam'));
    expect(oatRecipe.maxTemp, 60);
  });

  testWidgets(
      'Guided Barista questionnaire buttons are responsive to full-surface and edge taps',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final ble = BaristaBleService(storageService: storage);

    final tabKey = GlobalKey<CustomRecipeTabState>();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: CustomRecipeTab(
            key: tabKey,
            bleService: ble,
            storageService: storage,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tabKey.currentState!;

    // Initial state: Cold foam is selected
    expect(state.currentRecipe.isCold, isTrue);

    // Find the InkWell for the Hot button
    final hotInkWellFinder = find.ancestor(
      of: find.text('🔥 Piping Hot (60-68°C)'),
      matching: find.byType(InkWell),
    );
    expect(hotInkWellFinder, findsOneWidget);

    // Tap at the extreme corner / padding offset of the chip (Offset(3, 3) from top-left)
    final hotTopLeft = tester.getTopLeft(hotInkWellFinder);
    await tester.tapAt(hotTopLeft + const Offset(3, 3));
    await tester.pumpAndSettle();

    // Verify it acknowledged the edge tap and switched to hot
    expect(state.currentRecipe.isCold, isFalse);
    expect(state.currentRecipe.maxTemp, greaterThan(50));

    // Tap edge of Chocolate base
    final chocoFinder = find.ancestor(
      of: find.text('🍫 Rich Chocolate / Cocoa'),
      matching: find.byType(InkWell),
    );
    expect(chocoFinder, findsOneWidget);
    final chocoTopLeft = tester.getTopLeft(chocoFinder);
    await tester.tapAt(chocoTopLeft + const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(state.currentRecipe.name, contains('CHOCO'));

    // Tap already selected button - no error or unresponsiveness
    await tester.tap(chocoFinder);
    await tester.pumpAndSettle();
    expect(state.currentRecipe.name, contains('CHOCO'));
  });

  testWidgets('AboutBaristaDialog displays v1.5.1 • Release', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AboutBaristaDialog(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BARISTA STUDIO'), findsOneWidget);
    expect(find.text('v1.5.1 • Release'), findsOneWidget);
    expect(find.text('Guided Barista & Dual-Stage Formulator'), findsOneWidget);
    expect(
        find.text('Deep Linking & Universal Recipe Sharing'), findsOneWidget);
  });

  testWidgets(
      'RecipeDetailDialog omits share button on presets and includes it on custom recipes',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final ble = BaristaBleService(storageService: storage);

    final presetRecipe =
        PresetCatalog.presets.firstWhere((r) => r.name == 'Cappuccino');
    final customRecipe = Recipe(
      id: 'custom-recipe-uuid',
      name: 'Bespoke Latte',
      description: 'A custom latte test recipe',
      isCustom: true,
      category: 'Hot Coffee',
      phases: [Phase.clamped(speed: 2000, accel: 500, temp: 65, duration: 40)],
    );

    // 1. Preset recipe: Share icon should NOT be shown
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: RecipeDetailDialog(recipe: presetRecipe, bleService: ble),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cappuccino'), findsOneWidget);
    expect(find.byIcon(Icons.share), findsNothing);

    // 2. Custom recipe: Share icon SHOULD be shown
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: RecipeDetailDialog(recipe: customRecipe, bleService: ble),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bespoke Latte'), findsOneWidget);
    expect(find.byIcon(Icons.share), findsOneWidget);
  });

  testWidgets(
      'PresetsTab card buttons show book icon for Guide and tune icon for Edit in Builder',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final ble = BaristaBleService(storageService: storage);

    // Save a custom recipe
    await storage.saveCustomRecipe(Recipe(
      id: 'custom-card-test',
      name: 'Custom Cold Foam',
      description: 'A cold foam test recipe',
      isCustom: true,
      category: 'Cold Foam & Textures',
      phases: [Phase.clamped(speed: 3000, accel: 600, temp: 0, duration: 30)],
    ));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                child: PresetsTab(bleService: ble, storageService: storage),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // In Curated Presets mode:
    expect(find.text('Guide'), findsWidgets);
    expect(find.byIcon(Icons.menu_book_outlined), findsWidgets);

    // Switch to My Recipes
    await tester.tap(find.text('My Recipes (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Edit in Builder'), findsOneWidget);
    expect(find.byIcon(Icons.tune), findsOneWidget);
  });

  test('PresetCatalog popularity order places top crowd-pleasers first', () {
    final top10 = PresetCatalog.presets.take(10).map((r) => r.name).toList();
    expect(top10, contains('Cappuccino'));
    expect(top10, contains('Latte Macchiato'));
    expect(top10, contains('Flat White'));
    expect(top10, contains('Hot Chocolate'));
    expect(top10, contains('Iced Frappe'));
    expect(top10, contains('Nitro Cold Foam'));
    expect(top10, contains('Iced Caramel Mac'));
    expect(top10, contains('Brown Sugar Oat'));
    expect(top10, contains('Matcha Silk'));
    expect(top10, contains('Velvet Cortado'));

    // Cappuccino must be #1
    expect(PresetCatalog.presets.first.name, 'Cappuccino');
  });

  testWidgets('AboutBaristaDialog displays Reddit contact /u/Rosselman',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AboutBaristaDialog(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reddit: /u/Rosselman'), findsOneWidget);
    expect(find.byIcon(Icons.forum_outlined), findsOneWidget);

    // Tap Reddit contact row to verify no exceptions
    await tester.tap(find.text('Reddit: /u/Rosselman'));
    await tester.pump();
    expect(find.text('Reddit contact copied: /u/Rosselman'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'LoadoutManagerDialog shows AppToast when trying to save empty wheel',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final ble = BaristaBleService(storageService: storage);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: LoadoutManagerDialog(bleService: ble, storageService: storage),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Save Wheel button
    final saveButton = find.text('Save Wheel');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pump();

    // AppToast should be displayed with error message
    expect(
        find.text('Cannot save empty wheel. Flash at least one recipe first.'),
        findsOneWidget);
    await tester.pumpAndSettle();
  });

  test('PresetCatalog includes all 12 scoured recipes and has 90 total presets',
      () {
    expect(PresetCatalog.presets.length, 90);

    final expectedNames = [
      'Caffe Latte',
      'Iced Nitro',
      'Caffe Salentina',
      'Caffe Marocchino',
      'Espresso Con Panna',
      'Iced Lungo',
      'Cafe con Hielo',
      'Hot Milk Foam',
      'Cold Milk Foam',
      'Warm Milk',
      'Almond Flat White',
      'Saffron Pistachio',
    ];

    for (final name in expectedNames) {
      final recipe = PresetCatalog.presets.firstWhere(
        (r) => r.name.toLowerCase() == name.toLowerCase(),
        orElse: () => throw Exception('Missing recipe: $name'),
      );
      expect(recipe.ingredients.isNotEmpty, true,
          reason: '$name has no ingredients');
      expect(recipe.instructions.isNotEmpty, true,
          reason: '$name has no instructions');
      expect(recipe.hardwareName.length, lessThanOrEqualTo(16),
          reason: '$name hardware name exceeds 16 chars');
      expect(recipe.phases.isNotEmpty, true, reason: '$name has no phases');
    }
  });

  testWidgets(
      'Developer toggle controls Live Binary Packet Inspector visibility in CustomRecipeTab',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final ble = BaristaBleService(storageService: storage);

    expect(storage.isPacketInspectorEnabled(), false);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: CustomRecipeTab(
            bleService: ble,
            storageService: storage,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Granular Sequencer (Manual Mode)
    final manualButton = find.text('Granular Sequencer');
    if (manualButton.evaluate().isNotEmpty) {
      await tester.tap(manualButton);
      await tester.pumpAndSettle();
    }

    // Packet inspector should NOT be in the widget tree when toggle is disabled
    expect(
        find.text('Live Binary Packet Inspector (CRC-16 & Hex)'), findsNothing);

    // Enable the packet inspector toggle via storage service
    await storage.setPacketInspectorEnabled(true);
    await tester.pumpAndSettle();

    // Packet inspector should now be visible
    expect(find.text('Live Binary Packet Inspector (CRC-16 & Hex)'),
        findsOneWidget);

    // Disable it again
    await storage.setPacketInspectorEnabled(false);
    await tester.pumpAndSettle();

    expect(
        find.text('Live Binary Packet Inspector (CRC-16 & Hex)'), findsNothing);
  });

  testWidgets(
      'DeveloperDialog contains Packet Inspector switch and toggles storage',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final ble = BaristaBleService(storageService: storage);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: DeveloperDialog(bleService: ble, storageService: storage),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify switch tile title and subtitle
    expect(find.text('Live Binary Packet Inspector'), findsOneWidget);
    expect(
        find.text(
            'Show raw CRC-16 & 16-byte hex packet inspector in Custom Recipe builder'),
        findsOneWidget);

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    final switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.value, false);

    // Tap switch to turn on
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(storage.isPacketInspectorEnabled(), true);
  });
}
