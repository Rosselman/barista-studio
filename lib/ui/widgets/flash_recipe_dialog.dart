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
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FlashRecipeDialog(
        recipe: recipe,
        bleService: bleService,
        initialTargetSlot: initialTargetSlot,
      ),
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
    _selectedSlot = widget.initialTargetSlot;
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

    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(24),
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
              const Text(
                'Select Destination Slot',
                style: TextStyle(
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
                                ? 'Slot ${i + 1} (${slots[i].recipeName})'
                                : 'Slot ${i + 1} (Empty)',
                            style: TextStyle(
                              color: slots[i].isOccupied
                                  ? AppTheme.crema
                                  : AppTheme.textMuted,
                              fontSize: 13,
                            ),
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
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.flash_on, size: 18),
                    label: Text(_selectedSlot == -1
                        ? 'Append Recipe'
                        : 'Overwrite Slot ${_selectedSlot + 1}'),
                    onPressed: _startFlash,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
