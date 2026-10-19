import 'package:flutter/material.dart';
import '../../data/preset_catalog.dart';
import '../../models/recipe.dart';
import '../../services/barista_ble_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/flash_recipe_dialog.dart';
import '../widgets/loadout_manager_dialog.dart';
import '../widgets/recipe_detail_dialog.dart';
import '../widgets/step2_instruction_dialog.dart';

class SlotsTab extends StatelessWidget {
  final BaristaBleService bleService;
  final StorageService? storageService;
  final void Function(Recipe recipe)? onCustomize;

  const SlotsTab({
    super.key,
    required this.bleService,
    this.storageService,
    this.onCustomize,
  });

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Clear All Slots?', style: TextStyle(color: AppTheme.crema)),
        content: const Text(
          'This will erase all 13 recipe slots in the physical Barista EEPROM memory.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rubyEmergency),
            onPressed: () {
              Navigator.of(ctx).pop();
              bleService.clearAllSlots();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(BuildContext context, int fromSlot) {
    int toSlot = (fromSlot + 1) % 13;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: Text('Move Slot ${fromSlot + 1}', style: const TextStyle(color: AppTheme.crema)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select destination slot position:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceInput,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: toSlot,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceCard,
                    items: [
                      for (int i = 0; i < 13; i++)
                        if (i != fromSlot)
                          DropdownMenuItem<int>(
                            value: i,
                            child: Text('Slot ${i + 1} (${bleService.slots[i].recipeName})',
                                style: const TextStyle(color: AppTheme.crema, fontSize: 13)),
                          ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => toSlot = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                bleService.moveSlot(fromSlot, toSlot);
              },
              child: const Text('Move'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: bleService,
      builder: (context, _) {
        final isConnected = bleService.isConnected;
        final slots = bleService.slots;
        final selectedSlot = bleService.telemetry.selectedSlot;
        final occupiedCount = slots.where((s) => s.isOccupied).length;

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: CustomScrollView(
            slivers: [
              // Top Action Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hardware Memory',
                              style: TextStyle(
                                color: AppTheme.crema,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (isConnected)
                              Text(
                                bleService.isScanningSlots
                                    ? 'Syncing Slot ${(bleService.currentFetchingSlot >= 0 ? bleService.currentFetchingSlot + 1 : 1)} of 13...'
                                    : '$occupiedCount of 13 Slots Occupied',
                                style: TextStyle(
                                  color: bleService.isScanningSlots ? AppTheme.cyanCold : AppTheme.goldPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else
                              const Row(
                                children: [
                                  Icon(Icons.link_off, size: 13, color: AppTheme.textMuted),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Machine Offline • Connect to sync EEPROM',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      if (storageService != null) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldPrimary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: const Size(88, 32),
                          ),
                          icon: const Icon(Icons.dashboard_customize_outlined, size: 14),
                          label: const Text('Loadouts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          onPressed: () => LoadoutManagerDialog.show(
                            context,
                            bleService: bleService,
                            storageService: storageService!,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      IconButton(
                        icon: bleService.isScanningSlots
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.goldLight,
                                ),
                              )
                            : Icon(
                                Icons.refresh,
                                color: isConnected ? AppTheme.goldLight : AppTheme.textMuted,
                                size: 22,
                              ),
                        tooltip: isConnected
                            ? (bleService.isScanningSlots ? 'Syncing slots...' : 'Refresh Slots')
                            : 'Connect machine to refresh',
                        onPressed: (isConnected && !bleService.isScanningSlots)
                            ? () => bleService.fetchAllSlots()
                            : null,
                      ),
                      const SizedBox(width: 4),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isConnected ? AppTheme.rubyEmergency : AppTheme.textMuted,
                          side: BorderSide(color: isConnected ? AppTheme.rubyEmergency : AppTheme.borderSubtle),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: const Size(80, 32),
                        ),
                        icon: const Icon(Icons.delete_sweep, size: 15),
                        label: const Text('Clear All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        onPressed: isConnected ? () => _confirmClearAll(context) : null,
                      ),
                    ],
                  ),
                ),
              ),

              // 13 Slots List/Grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final crossAxisCount = width > 800 ? 2 : 1;

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 8,
                        mainAxisExtent: 78,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final slot = slots[index];
                          final isSelected = isConnected && (selectedSlot == index);
                          return _buildSlotCard(context, slot, isSelected);
                        },
                        childCount: 13,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openRecipeGuide(BuildContext context, dynamic slot, {bool preferStep2 = false}) {
    Recipe? recipe;
    final uuid = slot.recipeUuid as String?;
    final name = slot.recipeName as String;

    if (storageService != null) {
      recipe = storageService!.resolveRecipe(uuid: uuid, name: name);
    } else {
      if (uuid != null && uuid.isNotEmpty) {
        recipe = PresetCatalog.findByUuid(uuid);
      }
      if (recipe == null && name.isNotEmpty) {
        recipe = PresetCatalog.findByName(name);
      }
    }

    // Graceful fallback for physical slots without an exact catalog match
    recipe ??= Recipe(
      id: uuid ?? 'slot-${slot.slotIndex}',
      name: name,
      description: 'Custom recipe profile residing in rotary Slot ${slot.displayNumber} on the machine.',
      category: 'Machine Slot',
      ingredients: const [
        'Insert the Barista whisk into the jug.',
        'Add milk, coffee, water, or other ingredients up to the level indicator.',
      ],
      instructions: const [
        'Ensure the jug lid is securely closed.',
        'Select this slot on the rotary dial or via the app.',
        'Press the start button to brew.',
      ],
    );

    if (preferStep2 && recipe.isMultiStep) {
      Step2InstructionDialog.show(
        context,
        recipe: recipe,
        bleService: bleService,
        onCustomize: onCustomize,
      );
    } else {
      RecipeDetailDialog.show(
        context,
        recipe: recipe,
        bleService: bleService,
        onCustomize: onCustomize,
      );
    }
  }

  Widget _buildSlotCard(BuildContext context, dynamic slot, bool isSelected) {
    final isOccupied = slot.isOccupied as bool;
    final slotNum = slot.displayNumber as int;
    final slotIdx = slot.slotIndex as int;
    final isExecuting = isSelected && bleService.telemetry.machineState.isExecuting;
    final isPaused = isSelected && bleService.telemetry.machineState.isPaused;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: (isOccupied && bleService.isConnected)
            ? () => bleService.selectSlot(slotIdx)
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: isExecuting
                ? AppTheme.cyanCold.withOpacity(0.04)
                : (isPaused ? AppTheme.amberHeat.withOpacity(0.04) : AppTheme.surfaceCard),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isExecuting
                  ? AppTheme.cyanCold
                  : (isPaused
                      ? AppTheme.amberHeat
                      : (isSelected
                          ? AppTheme.goldPrimary
                          : (isOccupied ? AppTheme.borderSubtle : AppTheme.surfaceElevated))),
              width: (isSelected || isExecuting || isPaused) ? 1.6 : 1,
            ),
            boxShadow: isExecuting
                ? [
                    BoxShadow(
                      color: AppTheme.cyanCold.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : (isPaused
                    ? [
                        BoxShadow(
                          color: AppTheme.amberHeat.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : (isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.goldPrimary.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
          // Slot Number Indicator
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isExecuting
                  ? AppTheme.cyanCold
                  : (isPaused
                      ? AppTheme.amberHeat
                      : (isSelected
                          ? AppTheme.goldPrimary
                          : (isOccupied ? AppTheme.surfaceElevated : AppTheme.surfaceInput))),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isExecuting
                    ? AppTheme.cyanCold
                    : (isPaused
                        ? AppTheme.amberHeat
                        : (isSelected ? AppTheme.goldLight : AppTheme.borderSubtle)),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$slotNum',
              style: TextStyle(
                color: isSelected ? Colors.black : AppTheme.crema,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Slot Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        slot.recipeName,
                        style: TextStyle(
                          color: isOccupied ? AppTheme.crema : AppTheme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isExecuting
                              ? AppTheme.cyanCold.withOpacity(0.2)
                              : (isPaused
                                  ? AppTheme.amberHeat.withOpacity(0.2)
                                  : AppTheme.goldPrimary.withOpacity(0.18)),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isExecuting
                                ? AppTheme.cyanCold
                                : (isPaused ? AppTheme.amberHeat : AppTheme.goldPrimary),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          isExecuting ? 'BREWING' : (isPaused ? 'PAUSED' : 'ACTIVE'),
                          style: TextStyle(
                            color: isExecuting
                                ? AppTheme.cyanCold
                                : (isPaused ? AppTheme.amberHeat : AppTheme.goldLight),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isOccupied
                      ? (slot.recipeUuid != null
                          ? 'CRC: ${slot.crc ?? '-'} • UUID: ${slot.recipeUuid!.substring(0, 8)}'
                          : 'Custom Recipe Flash')
                      : 'Slot Available (Empty)',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Slot Actions
          if (isOccupied) ...[
            // Guide / Step 2 Link Button
            Tooltip(
              message: isPaused ? 'View Step 2 Instructions' : 'View Recipe Guide',
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _openRecipeGuide(context, slot, preferStep2: isPaused),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: isExecuting
                        ? AppTheme.cyanCold.withOpacity(0.2)
                        : (isPaused
                            ? AppTheme.amberHeat.withOpacity(0.25)
                            : AppTheme.surfaceElevated),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isExecuting
                          ? AppTheme.cyanCold
                          : (isPaused ? AppTheme.amberHeat : AppTheme.borderSubtle),
                      width: isPaused ? 1.2 : 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPaused ? Icons.bolt : Icons.menu_book_outlined,
                        size: 13,
                        color: isExecuting
                            ? AppTheme.cyanCold
                            : (isPaused ? AppTheme.amberHeat : AppTheme.goldLight),
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        isPaused ? 'Step 2' : 'Guide',
                        style: TextStyle(
                          color: isExecuting
                              ? AppTheme.cyanCold
                              : (isPaused ? AppTheme.amberHeat : AppTheme.goldLight),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 3),
            // Direct machine selection action
            IconButton(
              icon: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
              ),
              color: isSelected
                  ? (isExecuting
                      ? AppTheme.cyanCold
                      : (isPaused ? AppTheme.amberHeat : AppTheme.goldPrimary))
                  : (bleService.isConnected ? AppTheme.textSecondary : AppTheme.borderSubtle),
              tooltip: bleService.isConnected ? 'Select on Screen' : 'Machine offline',
              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: bleService.isConnected ? () => bleService.selectSlot(slotIdx) : null,
            ),
            // Options overflow
            SizedBox(
              width: 26,
              height: 26,
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 17,
                  color: bleService.isConnected ? AppTheme.textMuted : AppTheme.borderSubtle,
                ),
                color: AppTheme.surfaceCard,
                elevation: 8,
                tooltip: 'Slot Options',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.borderSubtle),
                ),
                padding: EdgeInsets.zero,
                itemBuilder: (ctx) => [
                  if (isPaused)
                    const PopupMenuItem(
                      value: 'step2',
                      child: Row(
                        children: [
                          Icon(Icons.bolt, size: 16, color: AppTheme.amberHeat),
                          SizedBox(width: 10),
                          Text("What's Step 2?", style: TextStyle(color: AppTheme.amberHeat, fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'guide',
                    child: Row(
                      children: [
                        Icon(Icons.menu_book_outlined, size: 16, color: AppTheme.goldLight),
                        SizedBox(width: 10),
                        Text('Step-by-step Guide', style: TextStyle(color: AppTheme.crema, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (bleService.isConnected) ...[
                    const PopupMenuItem(
                      value: 'select',
                      child: Row(
                        children: [
                          Icon(Icons.touch_app, size: 16, color: AppTheme.goldPrimary),
                          SizedBox(width: 10),
                          Text('Select on Machine', style: TextStyle(color: AppTheme.crema, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'move',
                      child: Row(
                        children: [
                          Icon(Icons.swap_vert, size: 16, color: AppTheme.crema),
                          SizedBox(width: 10),
                          Text('Move Position', style: TextStyle(color: AppTheme.crema, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: AppTheme.rubyEmergency),
                          SizedBox(width: 10),
                          Text('Delete Recipe', style: TextStyle(color: AppTheme.rubyEmergency, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ],
                onSelected: (val) {
                  if (val == 'step2') {
                    _openRecipeGuide(context, slot, preferStep2: true);
                  } else if (val == 'guide') {
                    _openRecipeGuide(context, slot);
                  } else if (val == 'select') {
                    bleService.selectSlot(slotIdx);
                  } else if (val == 'move') {
                    _showMoveDialog(context, slotIdx);
                  } else if (val == 'delete') {
                    bleService.deleteSlot(slotIdx);
                  }
                },
              ),
            ),
          ] else ...[
            TextButton.icon(
              icon: Icon(
                Icons.add,
                size: 15,
                color: bleService.isConnected ? AppTheme.goldPrimary : AppTheme.textMuted,
              ),
              label: Text(
                'Flash',
                style: TextStyle(
                  color: bleService.isConnected ? AppTheme.goldPrimary : AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(60, 30),
              ),
              onPressed: bleService.isConnected
                  ? () => _showRecipePickerForSlot(context, slotIdx)
                  : null,
            ),
          ],
        ],
      ),
    ),
  ),
);
  }

  void _showRecipePickerForSlot(BuildContext context, int slotIdx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String filter = '';
        final customRecipes = storageService?.getCustomRecipes() ?? <Recipe>[];

        return StatefulBuilder(
          builder: (context, setModalState) {
            final q = filter.toLowerCase().trim();

            final filteredCustom = customRecipes.where((r) {
              if (q.isEmpty) return true;
              return r.name.toLowerCase().contains(q) ||
                  r.category.toLowerCase().contains(q) ||
                  r.tags.any((t) => t.toLowerCase().contains(q));
            }).toList();

            final filteredPresets = PresetCatalog.presets.where((r) {
              if (q.isEmpty) return true;
              return r.name.toLowerCase().contains(q) ||
                  r.category.toLowerCase().contains(q) ||
                  r.tags.any((t) => t.toLowerCase().contains(q));
            }).toList();

            final allItems = [
              ...filteredCustom.map((r) => (recipe: r, isCustom: true)),
              ...filteredPresets.map((r) => (recipe: r, isCustom: false)),
            ];

            // Pinned favorites at the top!
            allItems.sort((a, b) {
              final aFav = storageService?.isFavorite(a.recipe.id) ?? false;
              final bFav = storageService?.isFavorite(b.recipe.id) ?? false;
              if (aFav && !bFav) return -1;
              if (!aFav && bFav) return 1;
              if (a.isCustom && !b.isCustom) return -1;
              if (!a.isCustom && b.isCustom) return 1;
              return 0;
            });

            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Select Recipe for Slot ${slotIdx + 1}',
                        style: const TextStyle(
                          color: AppTheme.crema,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    style: const TextStyle(color: AppTheme.crema, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: customRecipes.isNotEmpty
                          ? 'Search ${allItems.length} recipes (Presets & Custom)...'
                          : 'Search 50+ presets...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.bgDark,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.borderSubtle),
                      ),
                    ),
                    onChanged: (val) => setModalState(() => filter = val),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: allItems.length,
                      separatorBuilder: (_, __) => const Divider(color: AppTheme.borderSubtle, height: 1),
                      itemBuilder: (context, i) {
                        final item = allItems[i];
                        final recipe = item.recipe;
                        final isCustom = item.isCustom;
                        final isFavorite = storageService?.isFavorite(recipe.id) ?? false;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  recipe.name,
                                  style: const TextStyle(
                                    color: AppTheme.crema,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isFavorite) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.star, size: 14, color: AppTheme.goldPrimary),
                              ],
                              if (isCustom) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldPrimary.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppTheme.goldPrimary, width: 0.6),
                                  ),
                                  child: const Text(
                                    'MY RECIPE',
                                    style: TextStyle(
                                      color: AppTheme.goldLight,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${recipe.category} • ${recipe.isCold ? "Cold" : "${recipe.maxTemp}°C"} • ${recipe.totalDurationSeconds}s',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.flash_on, size: 16, color: AppTheme.goldPrimary),
                          onTap: () {
                            Navigator.pop(ctx);
                            FlashRecipeDialog.show(
                              context,
                              recipe: recipe,
                              bleService: bleService,
                              initialTargetSlot: slotIdx,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
