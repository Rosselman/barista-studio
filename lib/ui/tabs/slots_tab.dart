import 'package:flutter/material.dart';
import '../../data/preset_catalog.dart';
import '../../services/barista_ble_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/flash_recipe_dialog.dart';

class SlotsTab extends StatelessWidget {
  final BaristaBleService bleService;

  const SlotsTab({
    super.key,
    required this.bleService,
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
                                '$occupiedCount of 13 Slots Occupied',
                                style: const TextStyle(
                                  color: AppTheme.goldPrimary,
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
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: isConnected ? AppTheme.goldLight : AppTheme.textMuted,
                          size: 22,
                        ),
                        tooltip: isConnected ? 'Refresh Slots' : 'Connect machine to refresh',
                        onPressed: isConnected ? () => bleService.fetchAllSlots() : null,
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

  Widget _buildSlotCard(BuildContext context, dynamic slot, bool isSelected) {
    final isOccupied = slot.isOccupied as bool;
    final slotNum = slot.displayNumber as int;
    final slotIdx = slot.slotIndex as int;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppTheme.goldPrimary
              : (isOccupied ? AppTheme.borderSubtle : AppTheme.surfaceElevated),
          width: isSelected ? 1.6 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.goldPrimary.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Slot Number Indicator
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.goldPrimary
                  : (isOccupied ? AppTheme.surfaceElevated : AppTheme.surfaceInput),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppTheme.goldLight : AppTheme.borderSubtle,
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
          const SizedBox(width: 10),

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
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.goldPrimary, width: 0.6),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: AppTheme.goldLight,
                            fontSize: 9,
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
            // Direct machine selection action
            IconButton(
              icon: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
              ),
              color: isSelected
                  ? AppTheme.goldPrimary
                  : (bleService.isConnected ? AppTheme.textSecondary : AppTheme.borderSubtle),
              tooltip: bleService.isConnected ? 'Select on Screen' : 'Machine offline',
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: bleService.isConnected ? () => bleService.selectSlot(slotIdx) : null,
            ),
            // Options overflow
            SizedBox(
              width: 32,
              height: 32,
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: bleService.isConnected ? AppTheme.textMuted : AppTheme.borderSubtle,
                ),
                color: AppTheme.surfaceCard,
                elevation: 8,
                tooltip: 'Slot Options',
                enabled: bleService.isConnected,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.borderSubtle),
                ),
                padding: EdgeInsets.zero,
                itemBuilder: (ctx) => [
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
                onSelected: (val) {
                  if (val == 'select') {
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
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = PresetCatalog.presets.where((r) {
              if (filter.isEmpty) return true;
              final q = filter.toLowerCase().trim();
              return r.name.toLowerCase().contains(q) ||
                  r.category.toLowerCase().contains(q) ||
                  r.tags.any((t) => t.toLowerCase().contains(q));
            }).toList();

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
                      hintText: 'Search 40+ recipes...',
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
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(color: AppTheme.borderSubtle, height: 1),
                      itemBuilder: (context, i) {
                        final recipe = filtered[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          title: Text(
                            recipe.name,
                            style: const TextStyle(color: AppTheme.crema, fontSize: 14, fontWeight: FontWeight.w600),
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
