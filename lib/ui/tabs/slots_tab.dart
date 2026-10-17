import 'package:flutter/material.dart';
import '../../data/preset_catalog.dart';
import '../../services/barista_ble_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/flash_recipe_dialog.dart';

class SlotsTab extends StatelessWidget {
  final BaristaBleService bleService;

  const SlotsTab({super.key, required this.bleService});

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Clear All 13 Slots?', style: TextStyle(color: AppTheme.crema)),
        content: const Text(
          'This will purge all custom and preset recipes stored in the Barista machine memory.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Physical Hardware Memory',
                            style: TextStyle(
                              color: AppTheme.crema,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$occupiedCount of 13 Slots Occupied',
                            style: const TextStyle(
                              color: AppTheme.goldPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh, color: AppTheme.goldLight),
                            tooltip: 'Refresh Slots',
                            onPressed: () => bleService.fetchAllSlots(),
                          ),
                          const SizedBox(width: 4),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.rubyEmergency,
                              side: const BorderSide(color: AppTheme.rubyEmergency),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.delete_sweep, size: 16),
                            label: const Text('Clear All', style: TextStyle(fontSize: 12)),
                            onPressed: () => _confirmClearAll(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 13 Slots List/Grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final crossAxisCount = width > 800 ? 2 : 1;

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 110,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final slot = slots[index];
                          final isSelected = selectedSlot == index;
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

  Widget _buildSlotCard(BuildContext context, dynamic slot, bool isSelected) {
    final isOccupied = slot.isOccupied as bool;
    final slotNum = slot.displayNumber as int;
    final slotIdx = slot.slotIndex as int;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppTheme.goldPrimary
              : (isOccupied ? AppTheme.borderSubtle : AppTheme.surfaceElevated),
          width: isSelected ? 1.6 : 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Slot Number Indicator
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.goldPrimary
                  : (isOccupied ? AppTheme.surfaceElevated : AppTheme.surfaceInput),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.goldLight : AppTheme.borderSubtle,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$slotNum',
              style: TextStyle(
                color: isSelected ? Colors.black : AppTheme.crema,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 14),

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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.goldPrimary, width: 0.6),
                        ),
                        child: const Text(
                          'ACTIVE ON SCREEN',
                          style: TextStyle(
                            color: AppTheme.goldLight,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isOccupied
                      ? (slot.recipeUuid != null
                          ? 'UUID: ${slot.recipeUuid!.substring(0, 8)}... • CRC: ${slot.crc ?? '-'}'
                          : 'Custom Recipe Flash')
                      : 'Slot Available (Empty)',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Slot Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOccupied) ...[
                // Tap to select on physical machine
                IconButton(
                  icon: const Icon(Icons.radio_button_checked, size: 20),
                  color: isSelected ? AppTheme.goldPrimary : AppTheme.textMuted,
                  tooltip: 'Select on Barista Screen',
                  onPressed: () => bleService.selectSlot(slotIdx),
                ),
                // Move position
                IconButton(
                  icon: const Icon(Icons.swap_vert, size: 20),
                  color: AppTheme.textMuted,
                  tooltip: 'Move Position',
                  onPressed: () => _showMoveDialog(context, slotIdx),
                ),
                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppTheme.rubyEmergency,
                  tooltip: 'Delete Slot',
                  onPressed: () => bleService.deleteSlot(slotIdx),
                ),
              ] else ...[
                // Overwrite / Flash to this empty slot
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16, color: AppTheme.goldPrimary),
                  label: const Text('Flash', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 12)),
                  onPressed: () {
                    // Flash default or custom
                    FlashRecipeDialog.show(
                      context,
                      recipe: PresetCatalog.presets.first,
                      bleService: bleService,
                      initialTargetSlot: slotIdx,
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
