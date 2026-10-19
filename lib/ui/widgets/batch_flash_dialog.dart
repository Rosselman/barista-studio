import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../models/wheel_loadout.dart';
import '../../services/barista_ble_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class BatchFlashDialog extends StatefulWidget {
  final WheelLoadout loadout;
  final BaristaBleService bleService;
  final StorageService storageService;

  const BatchFlashDialog({
    super.key,
    required this.loadout,
    required this.bleService,
    required this.storageService,
  });

  static Future<void> show(
    BuildContext context, {
    required WheelLoadout loadout,
    required BaristaBleService bleService,
    required StorageService storageService,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BatchFlashDialog(
        loadout: loadout,
        bleService: bleService,
        storageService: storageService,
      ),
    );
  }

  @override
  State<BatchFlashDialog> createState() => _BatchFlashDialogState();
}

enum _BatchState { confirm, running, success, failed }

class _BatchFlashItem {
  final int slotIndex;
  final Recipe recipe;
  const _BatchFlashItem({required this.slotIndex, required this.recipe});
}

class _BatchFlashDialogState extends State<BatchFlashDialog> {
  _BatchState _state = _BatchState.confirm;
  int _currentStep = 0;
  int _totalSteps = 0;
  String _currentStepName = '';
  double _stepProgress = 0.0;
  String? _errorMessage;

  late final List<Recipe?> _resolvedRecipes;
  late final List<_BatchFlashItem> _validItems;

  @override
  void initState() {
    super.initState();
    final custom = widget.storageService.getCustomRecipes();
    _resolvedRecipes = widget.loadout.resolveRecipes(custom);
    _validItems = <_BatchFlashItem>[];
    for (int i = 0; i < 13; i++) {
      final r = _resolvedRecipes[i];
      if (r != null) {
        _validItems.add(_BatchFlashItem(slotIndex: i, recipe: r));
      }
    }
    _totalSteps = _validItems.length;
  }

  Future<void> _startBatch() async {
    setState(() {
      _state = _BatchState.running;
      _currentStep = 0;
      _currentStepName = 'Erasing EEPROM memory...';
      _stepProgress = 0.0;
      _errorMessage = null;
    });

    final success = await widget.bleService.flashBatchLoadout(
      loadout: widget.loadout,
      customRecipes: widget.storageService.getCustomRecipes(),
      onProgress: (current, total, recipeName, prog) {
        if (!mounted) return;
        setState(() {
          _currentStep = current;
          _totalSteps = total;
          _currentStepName = recipeName;
          _stepProgress = prog;
        });
      },
    );

    if (!mounted) return;
    setState(() {
      if (success) {
        _state = _BatchState.success;
      } else {
        _state = _BatchState.failed;
        _errorMessage = 'Hardware communication failed during flash.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _state == _BatchState.success
                        ? AppTheme.emeraldSuccess.withOpacity(0.18)
                        : (_state == _BatchState.failed
                            ? AppTheme.rubyEmergency.withOpacity(0.18)
                            : AppTheme.goldPrimary.withOpacity(0.18)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _state == _BatchState.success
                        ? Icons.check_circle_outline
                        : (_state == _BatchState.failed
                            ? Icons.error_outline
                            : Icons.bolt),
                    color: _state == _BatchState.success
                        ? AppTheme.emeraldSuccess
                        : (_state == _BatchState.failed
                            ? AppTheme.rubyEmergency
                            : AppTheme.goldPrimary),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _state == _BatchState.success
                            ? 'Batch Flash Complete!'
                            : (_state == _BatchState.failed
                                ? 'Batch Flash Failed'
                                : (_state == _BatchState.running
                                    ? 'Flashing Loadout...'
                                    : 'Flash Wheel Loadout')),
                        style: const TextStyle(
                          color: AppTheme.crema,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.loadout.name,
                        style: const TextStyle(
                          color: AppTheme.goldLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content according to state
            if (_state == _BatchState.confirm) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 15, color: AppTheme.goldLight),
                        const SizedBox(width: 6),
                        Text(
                          '${_validItems.length} Recipes ready to flash',
                          style: const TextStyle(
                            color: AppTheme.crema,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This will erase the physical 13-slot EEPROM on your Barista and sequentially write all ${_validItems.length} recipes in this loadout.',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Preview list of slots
              const Text(
                'Slot Arrangement Preview:',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  itemCount: _validItems.length,
                  separatorBuilder: (_, __) => const Divider(color: AppTheme.borderSubtle, height: 1),
                  itemBuilder: (context, idx) {
                    final item = _validItems[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.slotIndex + 1}',
                              style: const TextStyle(
                                color: AppTheme.goldLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.recipe.name,
                              style: const TextStyle(
                                color: AppTheme.crema,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${item.recipe.totalDurationSeconds}s • ${item.recipe.peakRpm} RPM',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else if (_state == _BatchState.running) ...[
              // Total Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currentStep == 0
                        ? 'Preparing EEPROM...'
                        : 'Slot $_currentStep of $_totalSteps: $_currentStepName',
                    style: const TextStyle(
                      color: AppTheme.crema,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _totalSteps > 0 ? '${((_currentStep / _totalSteps) * 100).clamp(0, 100).toInt()}%' : '0%',
                    style: const TextStyle(
                      color: AppTheme.goldLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _totalSteps > 0 ? (_currentStep / _totalSteps).clamp(0.0, 1.0) : 0.0,
                  minHeight: 10,
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldPrimary),
                ),
              ),
              const SizedBox(height: 12),

              // Single-step Chunk Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recipe Packet Stream:',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  Text(
                    '${(_stepProgress * 100).toInt()}%',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _stepProgress.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldLight),
                ),
              ),
              const SizedBox(height: 14),

              // Slots progress ticker
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  itemCount: _validItems.length,
                  itemBuilder: (context, idx) {
                    final item = _validItems[idx];
                    final stepNum = idx + 1;
                    final isDone = _currentStep > stepNum;
                    final isCurrent = _currentStep == stepNum;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(
                            isDone
                                ? Icons.check_circle
                                : (isCurrent ? Icons.sync : Icons.radio_button_unchecked),
                            size: 14,
                            color: isDone
                                ? AppTheme.emeraldSuccess
                                : (isCurrent ? AppTheme.goldPrimary : AppTheme.textMuted),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Slot ${item.slotIndex + 1}: ${item.recipe.name}',
                              style: TextStyle(
                                color: isCurrent ? AppTheme.goldLight : (isDone ? AppTheme.crema : AppTheme.textMuted),
                                fontSize: 11.5,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrent)
                            const Text(
                              'Flashing...',
                              style: TextStyle(color: AppTheme.goldPrimary, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else if (_state == _BatchState.success) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldSuccess.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.emeraldSuccess.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.celebration, color: AppTheme.emeraldSuccess, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'All ${_validItems.length} slots flashed!',
                      style: const TextStyle(
                        color: AppTheme.emeraldSuccess,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Turn the rotary dial on your Barista to browse and run your new recipes.',
                      style: TextStyle(color: AppTheme.crema, fontSize: 11.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else if (_state == _BatchState.failed) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.rubyEmergency.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.rubyEmergency.withOpacity(0.4)),
                ),
                child: Text(
                  _errorMessage ?? 'Batch flash failed.',
                  style: const TextStyle(color: AppTheme.rubyEmergency, fontSize: 12),
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Dialog Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_state == _BatchState.confirm) ...[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.flash_on, size: 16),
                    label: Text(
                      'Flash All ${_validItems.length} Slots',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: _validItems.isEmpty ? null : _startBatch,
                  ),
                ] else if (_state == _BatchState.running) ...[
                  const Text(
                    'Do not turn off machine or phone...',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
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
