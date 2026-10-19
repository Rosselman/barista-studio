import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../services/barista_ble_service.dart';
import '../../theme/app_theme.dart';

class FlashRecipeDialog extends StatefulWidget {
  final Recipe recipe;
  final BaristaBleService bleService;
  final int initialTargetSlot; // -1 for auto-append, 0..12 for specific slot

  const FlashRecipeDialog({
    super.key,
    required this.recipe,
    required this.bleService,
    this.initialTargetSlot = -1,
  });

  static Future<void> show(
    BuildContext context, {
    required Recipe recipe,
    required BaristaBleService bleService,
    int initialTargetSlot = -1,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => FlashRecipeDialog(
        recipe: recipe,
        bleService: bleService,
        initialTargetSlot: initialTargetSlot,
      ),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curve = Curves.easeOutCubic.transform(anim.value);
        return Transform.scale(
          scale: 0.94 + (0.06 * curve),
          child: Opacity(
            opacity: anim.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<FlashRecipeDialog> createState() => _FlashRecipeDialogState();
}

class _FlashRecipeDialogState extends State<FlashRecipeDialog> {
  late int _selectedSlot;
  bool _isFlashing = false;
  double _progress = 0.0;
  String _statusText = 'Ready to flash';
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final isMemoryFull = widget.bleService.slots.isNotEmpty &&
        widget.bleService.slots.every((s) => s.isOccupied);
    if (widget.initialTargetSlot >= 0 && widget.initialTargetSlot < 13) {
      _selectedSlot = widget.initialTargetSlot;
    } else if (isMemoryFull) {
      _selectedSlot = 0; // Default to Slot 1 for overwrite when memory is full
    } else {
      _selectedSlot = -1; // Auto-append
    }
  }

  void _startFlash() async {
    if (!widget.bleService.isConnected) {
      setState(() {
        _errorMessage = 'Machine is not connected. Please connect via Bluetooth first.';
      });
      return;
    }

    setState(() {
      _isFlashing = true;
      _progress = 0.0;
      _errorMessage = null;
      _statusText = 'Preparing binary packet...';
    });

    final success = await widget.bleService.flashRecipe(
      recipe: widget.recipe,
      targetSlot: _selectedSlot,
      onProgress: (p) {
        if (mounted) {
          setState(() {
            _progress = p;
            _statusText = widget.bleService.uploadStatusText ??
                'Sending BLE packet (${(p * 100).round()}%)...';
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isFlashing = false;
        if (success) {
          _isSuccess = true;
          _progress = 1.0;
          _statusText = 'Recipe added! Check your Barista.';
        } else {
          _errorMessage = widget.bleService.uploadStatusText ?? 'Flashing failed.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = widget.bleService.slots;
    final isMemoryFull = slots.isNotEmpty && slots.every((s) => s.isOccupied);

    // If memory is full and current selection is still auto-append, point to slot 0
    if (isMemoryFull && _selectedSlot < 0) {
      _selectedSlot = 0;
    }

    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(24),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bolt, color: AppTheme.goldPrimary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Flash to Barista',
                        style: TextStyle(
                          color: AppTheme.crema,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.recipe.name,
                        style: const TextStyle(
                          color: AppTheme.goldLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isFlashing)
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Target Slot Selector
            if (!_isFlashing && !_isSuccess) ...[
              if (isMemoryFull) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.amberHeat.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.amberHeat.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.amberHeat, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hardware memory full (13/13). Select an existing slot to overwrite.',
                          style: TextStyle(
                            color: AppTheme.amberHeat,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Text(
                isMemoryFull ? 'Select Slot to Overwrite' : 'Select Destination Slot',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedSlot,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceCard,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.goldPrimary),
                    items: [
                      if (!isMemoryFull)
                        const DropdownMenuItem<int>(
                          value: -1,
                          child: Text(
                            'Next Available Slot (Auto-Append)',
                            style: TextStyle(
                              color: AppTheme.goldLight,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      for (int i = 0; i < 13; i++)
                        DropdownMenuItem<int>(
                          value: i,
                          child: Text(
                            slots[i].isOccupied
                                ? 'Slot ${i + 1} (${slots[i].recipeName}) - Overwrite'
                                : 'Slot ${i + 1} (Empty)',
                            style: TextStyle(
                              color: slots[i].isOccupied
                                  ? AppTheme.crema
                                  : AppTheme.textMuted,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSlot = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Progress or Status Section
            if (_isFlashing || _isSuccess || _errorMessage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: AppTheme.surfaceInput,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _errorMessage != null
                        ? AppTheme.rubyEmergency
                        : _isSuccess
                            ? AppTheme.emeraldSuccess
                            : AppTheme.goldPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _errorMessage ?? _statusText,
                      style: TextStyle(
                        color: _errorMessage != null
                            ? AppTheme.rubyEmergency
                            : _isSuccess
                                ? AppTheme.emeraldSuccess
                                : AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_isFlashing)
                    Text(
                      '${(_progress * 100).round()}%',
                      style: const TextStyle(
                        color: AppTheme.goldPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_isFlashing)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      _isSuccess ? 'Close' : 'Cancel',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                if (!_isSuccess && !_isFlashing) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.flash_on, size: 16),
                      label: Text(
                        _selectedSlot == -1
                            ? 'Append Recipe'
                            : 'Overwrite Slot ${_selectedSlot + 1}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      onPressed: _startFlash,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}
