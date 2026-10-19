import 'package:flutter/material.dart';
import '../../models/wheel_loadout.dart';
import '../../services/barista_ble_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import 'batch_flash_dialog.dart';

class LoadoutManagerDialog extends StatefulWidget {
  final BaristaBleService bleService;
  final StorageService storageService;

  const LoadoutManagerDialog({
    super.key,
    required this.bleService,
    required this.storageService,
  });

  static Future<void> show(
    BuildContext context, {
    required BaristaBleService bleService,
    required StorageService storageService,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => LoadoutManagerDialog(
        bleService: bleService,
        storageService: storageService,
      ),
    );
  }

  @override
  State<LoadoutManagerDialog> createState() => _LoadoutManagerDialogState();
}

class _LoadoutManagerDialogState extends State<LoadoutManagerDialog> {
  int _selectedFilterIndex = 0; // 0: All, 1: Curated, 2: Custom

  void _showSaveCurrentWheelDialog(BuildContext context) {
    final occupiedSlots = widget.bleService.slots.where((s) => s.isOccupied).toList();
    if (occupiedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save empty wheel. Flash at least one recipe first.'),
          backgroundColor: AppTheme.surfaceElevated,
        ),
      );
      return;
    }

    final nameController = TextEditingController(text: 'My Custom Wheel');
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Row(
          children: [
            Icon(Icons.bookmark_add_outlined, color: AppTheme.goldPrimary, size: 22),
            SizedBox(width: 8),
            Text('Save Current Wheel', style: TextStyle(color: AppTheme.crema, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving ${occupiedSlots.length} occupied slots as a reusable loadout profile.',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Text('Loadout Name', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceInput,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: TextField(
                controller: nameController,
                maxLength: 28,
                style: const TextStyle(color: AppTheme.crema, fontSize: 14, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  hintText: 'e.g. Summer Iced Wheel, Weekend Brunch',
                  hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Description (Optional)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceInput,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: TextField(
                controller: descController,
                maxLines: 2,
                maxLength: 120,
                style: const TextStyle(color: AppTheme.crema, fontSize: 13),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  hintText: 'e.g. Selection for hot afternoons and friends...',
                  hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
            onPressed: () async {
              final name = nameController.text.trim();
              final desc = descController.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();

              final slotEntries = <LoadoutSlotEntry>[];
              for (final slot in occupiedSlots) {
                slotEntries.add(
                  LoadoutSlotEntry(
                    slotIndex: slot.slotIndex,
                    recipeId: slot.recipeUuid ?? '',
                    recipeName: slot.recipeName,
                    isCustom: slot.recipeUuid == null,
                  ),
                );
              }

              final newLoadout = WheelLoadout.create(
                name: name.isEmpty ? 'My Custom Wheel' : name,
                description: desc,
                slots: slotEntries,
              );

              await widget.storageService.saveLoadout(newLoadout);
              if (mounted) {
                setState(() {});
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Saved "${newLoadout.name}" to Loadouts!'),
                    backgroundColor: AppTheme.surfaceElevated,
                  ),
                );
              }
            },
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLoadout(BuildContext context, WheelLoadout loadout) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Text('Delete Loadout Profile?', style: TextStyle(color: AppTheme.crema)),
        content: Text(
          'Are you sure you want to delete "${loadout.name}"? This cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rubyEmergency,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              await widget.storageService.deleteLoadout(loadout.id);
              if (mounted) {
                setState(() {});
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${loadout.name}"'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allLoadouts = widget.storageService.getAllLoadouts();
    final customLoadouts = widget.storageService.getCustomLoadouts();
    final customIds = customLoadouts.map((c) => c.id).toSet();

    List<WheelLoadout> displayList;
    if (_selectedFilterIndex == 1) {
      displayList = allLoadouts.where((l) => !customIds.contains(l.id)).toList();
    } else if (_selectedFilterIndex == 2) {
      displayList = customLoadouts;
    } else {
      displayList = allLoadouts;
    }

    final isConnected = widget.bleService.isConnected;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.dashboard_customize_outlined, color: AppTheme.goldPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved Loadouts (Profiles)',
                      style: TextStyle(
                        color: AppTheme.crema,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Swap your entire 13-slot dial arrangement in one batch flash',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Bar: Filter Pills + Save Wheel Button
          Row(
            children: [
              // Segmented Filter
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All (${allLoadouts.length})', 0),
                      const SizedBox(width: 6),
                      _buildFilterChip('Curated Defaults', 1),
                      const SizedBox(width: 6),
                      _buildFilterChip('My Profiles (${customLoadouts.length})', 2),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.goldLight,
                  side: const BorderSide(color: AppTheme.goldPrimary, width: 0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(80, 32),
                ),
                icon: const Icon(Icons.bookmark_add_outlined, size: 14),
                label: const Text('Save Wheel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                onPressed: () => _showSaveCurrentWheelDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // List of Loadouts
          Expanded(
            child: displayList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard_customize_outlined, size: 48, color: AppTheme.textMuted.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text(
                          'No custom loadout profiles yet',
                          style: TextStyle(color: AppTheme.crema, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Arrange your 13 slots on the wheel, then tap "Save Wheel" above.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final loadout = displayList[index];
                      final isCustom = customIds.contains(loadout.id);
                      return _buildLoadoutCard(context, loadout, isCustom: isCustom, isConnected: isConnected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: AppTheme.goldPrimary,
      backgroundColor: AppTheme.surfaceElevated,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 11,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppTheme.goldPrimary : AppTheme.borderSubtle,
          width: 0.8,
        ),
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedFilterIndex = index);
      },
    );
  }

  Widget _buildLoadoutCard(
    BuildContext context,
    WheelLoadout loadout, {
    required bool isCustom,
    required bool isConnected,
  }) {
    final count = loadout.slots.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCustom ? AppTheme.goldPrimary.withOpacity(0.3) : AppTheme.borderSubtle,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row & badges
          Row(
            children: [
              Expanded(
                child: Text(
                  loadout.name,
                  style: const TextStyle(
                    color: AppTheme.crema,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isCustom ? AppTheme.goldPrimary.withOpacity(0.16) : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCustom ? AppTheme.goldPrimary.withOpacity(0.5) : AppTheme.borderSubtle,
                    width: 0.6,
                  ),
                ),
                child: Text(
                  isCustom ? 'Custom Profile' : 'Curated Preset',
                  style: TextStyle(
                    color: isCustom ? AppTheme.goldLight : AppTheme.textSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (loadout.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              loadout.description,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),

          // 13-slot mini visualizer chips
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(13, (i) {
              final slotEntry = loadout.slots.where((s) => s.slotIndex == i).firstOrNull;
              final recipeName = slotEntry?.recipeName ?? 'Empty';
              final isFilled = slotEntry != null;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isFilled ? AppTheme.surfaceElevated : AppTheme.surfaceInput,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isFilled ? AppTheme.borderSubtle : Colors.transparent,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '${i + 1}: ${isFilled ? recipeName : '-'}',
                  style: TextStyle(
                    color: isFilled ? AppTheme.crema : AppTheme.textMuted,
                    fontSize: 9.5,
                    fontWeight: isFilled ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Text(
                '$count of 13 Slots Defined',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
              ),
              const Spacer(),
              if (isCustom)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.rubyEmergency),
                  tooltip: 'Delete Loadout',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  onPressed: () => _confirmDeleteLoadout(context, loadout),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected ? AppTheme.goldPrimary : AppTheme.surfaceElevated,
                  foregroundColor: isConnected ? Colors.black : AppTheme.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(100, 32),
                ),
                icon: const Icon(Icons.flash_on, size: 14),
                label: const Text('Batch Flash', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                onPressed: isConnected
                    ? () {
                        Navigator.of(context).pop();
                        BatchFlashDialog.show(
                          context,
                          loadout: loadout,
                          bleService: widget.bleService,
                          storageService: widget.storageService,
                        );
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
