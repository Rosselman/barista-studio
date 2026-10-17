import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/phase.dart';
import '../../models/recipe.dart';
import '../../protocol/crc16.dart';
import '../../protocol/recipe_packet_builder.dart';
import '../../services/barista_ble_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/flash_recipe_dialog.dart';
import '../widgets/whisk_visualizer.dart';

class CustomRecipeTab extends StatefulWidget {
  final BaristaBleService bleService;
  final StorageService storageService;
  final Recipe? initialRecipe;

  const CustomRecipeTab({
    super.key,
    required this.bleService,
    required this.storageService,
    this.initialRecipe,
  });

  @override
  State<CustomRecipeTab> createState() => CustomRecipeTabState();
}

class CustomRecipeTabState extends State<CustomRecipeTab> {
  late TextEditingController _nameController;
  late String _recipeId;
  int _activePhaseIndex = 0;

  late List<Phase> _phases;

  @override
  void initState() {
    super.initState();
    _loadRecipe(widget.initialRecipe);
  }

  void _loadRecipe(Recipe? recipe) {
    if (recipe != null) {
      _nameController = TextEditingController(text: recipe.hardwareName);
      _recipeId = recipe.id;
      _phases = List.generate(3, (i) {
        if (i < recipe.phases.length) {
          return recipe.phases[i];
        }
        return Phase.clamped(duration: 0); // inactive
      });
    } else {
      _nameController = TextEditingController(text: 'VELVET FOAM');
      _recipeId = const Uuid().v4();
      _phases = [
        Phase.clamped(speed: 3200, accel: 800, temp: 45, duration: 25),
        Phase.clamped(speed: 1200, accel: 600, temp: 65, duration: 15),
        Phase.clamped(speed: 800, accel: 400, temp: 65, duration: 0), // off by default
      ];
    }
  }

  void setRecipe(Recipe recipe) {
    setState(() {
      _nameController.text = recipe.hardwareName;
      _recipeId = recipe.id;
      _phases = List.generate(3, (i) {
        if (i < recipe.phases.length) {
          return recipe.phases[i];
        }
        return Phase.clamped(duration: 0);
      });
      _activePhaseIndex = 0;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Recipe _getCurrentRecipe() {
    return Recipe(
      id: _recipeId,
      name: _nameController.text.trim().isEmpty
          ? 'Custom Froth'
          : _nameController.text.trim(),
      description: 'Custom multi-phase Barista recipe created in Studio.',
      category: 'Specialty',
      phases: _phases.where((p) => p.duration > 0).toList(),
      isCustom: true,
    );
  }

  void _updateActivePhase(Phase newPhase) {
    setState(() {
      _phases[_activePhaseIndex] = newPhase;
    });
  }

  void _saveToLocal() async {
    final recipe = _getCurrentRecipe();
    await widget.storageService.saveCustomRecipe(recipe);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipe "${recipe.name}" saved to My Recipes.'),
          backgroundColor: AppTheme.surfaceElevated,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePhase = _phases[_activePhaseIndex];
    final currentRecipe = _getCurrentRecipe();

    // Compute live packet & CRC for inspector
    final packet = RecipePacketBuilder.buildPacket(
      isAppend: true,
      targetPos: 1,
      name: currentRecipe.hardwareName,
      uuidStr: currentRecipe.id,
      phases: currentRecipe.phases,
    );
    final crc = Crc16.compute(packet, 2, packet.length);
    final packetHex = packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Whisk & Induction Visualizer
            WhiskVisualizer(
              rpm: activePhase.speed,
              targetTemp: activePhase.temp,
              isRunning: activePhase.duration > 0,
              height: 170,
            ),
            const SizedBox(height: 18),

            // Recipe Name Input & Hardware UUID
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Machine Display Name',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_nameController.text.length}/16 Max ASCII',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceInput,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: TextField(
                      controller: _nameController,
                      maxLength: 16,
                      style: const TextStyle(
                        color: AppTheme.crema,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        hintText: 'e.g. ULTRA FOAM',
                        hintStyle: TextStyle(color: AppTheme.textMuted),
                      ),
                      onChanged: (val) {
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Multi-Phase Selector (Phase 1, 2, 3)
            Row(
              children: [
                _buildPhaseTab(0, 'Phase 1 (Whip)'),
                const SizedBox(width: 8),
                _buildPhaseTab(1, 'Phase 2 (Texture)'),
                const SizedBox(width: 8),
                _buildPhaseTab(2, 'Phase 3 (Polish)'),
              ],
            ),
            const SizedBox(height: 14),

            // Active Phase Sliders Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phase Header Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phase ${_activePhaseIndex + 1} Parameters',
                        style: const TextStyle(
                          color: AppTheme.crema,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: activePhase.duration == 0
                              ? AppTheme.surfaceElevated
                              : AppTheme.goldPrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: activePhase.duration == 0
                                ? AppTheme.borderSubtle
                                : AppTheme.goldPrimary.withOpacity(0.6),
                          ),
                        ),
                        child: Text(
                          activePhase.duration == 0
                              ? 'Phase Inactive (Skip)'
                              : '${activePhase.duration}s @ ${activePhase.speed} RPM, ${activePhase.temp}°C',
                          style: TextStyle(
                            color: activePhase.duration == 0
                                ? AppTheme.textMuted
                                : AppTheme.goldLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.borderSubtle, height: 24),

                  // 1. Motor Speed RPM Slider
                  _buildSliderHeader(
                    'Motor Speed (Whisk Rotation)',
                    '${activePhase.speed} RPM',
                    AppTheme.goldLight,
                  ),
                  Slider(
                    value: activePhase.speed.toDouble(),
                    min: 300,
                    max: 4000,
                    divisions: 74,
                    onChanged: (val) {
                      _updateActivePhase(activePhase.copyWith(speed: val.round()));
                    },
                  ),
                  _buildChipRow([
                    _PresetChip('Slow (800)', () => _updateActivePhase(activePhase.copyWith(speed: 800))),
                    _PresetChip('Med (1800)', () => _updateActivePhase(activePhase.copyWith(speed: 1800))),
                    _PresetChip('Dense (3200)', () => _updateActivePhase(activePhase.copyWith(speed: 3200))),
                    _PresetChip('Max (4000)', () => _updateActivePhase(activePhase.copyWith(speed: 4000))),
                  ]),
                  const SizedBox(height: 18),

                  // 2. Acceleration Slider
                  _buildSliderHeader(
                    'Motor Ramp Acceleration',
                    '${activePhase.accel}',
                    AppTheme.crema,
                  ),
                  Slider(
                    value: activePhase.accel.toDouble(),
                    min: 50,
                    max: 2000,
                    divisions: 78,
                    onChanged: (val) {
                      _updateActivePhase(activePhase.copyWith(accel: val.round()));
                    },
                  ),
                  _buildChipRow([
                    _PresetChip('Gentle (200)', () => _updateActivePhase(activePhase.copyWith(accel: 200))),
                    _PresetChip('Standard (800)', () => _updateActivePhase(activePhase.copyWith(accel: 800))),
                    _PresetChip('Rapid (1600)', () => _updateActivePhase(activePhase.copyWith(accel: 1600))),
                  ]),
                  const SizedBox(height: 18),

                  // 3. Induction Temperature Slider
                  _buildSliderHeader(
                    'Induction Heating Target',
                    activePhase.temp == 0 ? '0°C (Cold Foam)' : '${activePhase.temp}°C',
                    activePhase.temp == 0 ? AppTheme.cyanCold : AppTheme.amberHeat,
                  ),
                  Slider(
                    value: activePhase.temp.toDouble(),
                    min: 0,
                    max: 70,
                    divisions: 70,
                    activeColor: activePhase.temp == 0 ? AppTheme.cyanCold : AppTheme.amberHeat,
                    onChanged: (val) {
                      _updateActivePhase(activePhase.copyWith(temp: val.round()));
                    },
                  ),
                  _buildChipRow([
                    _PresetChip('0°C (Cold Foam - OFF)', () => _updateActivePhase(activePhase.copyWith(temp: 0)), color: AppTheme.cyanCold),
                    _PresetChip('45°C (Warm Silk)', () => _updateActivePhase(activePhase.copyWith(temp: 45))),
                    _PresetChip('65°C (Ideal Barista)', () => _updateActivePhase(activePhase.copyWith(temp: 65))),
                    _PresetChip('70°C (Hot Chocolate)', () => _updateActivePhase(activePhase.copyWith(temp: 70)), color: AppTheme.amberHeat),
                  ]),
                  const SizedBox(height: 18),

                  // 4. Phase Duration Slider
                  _buildSliderHeader(
                    'Phase Duration',
                    activePhase.duration == 0 ? '0s (Skip)' : '${activePhase.duration}s',
                    activePhase.duration == 0 ? AppTheme.textMuted : AppTheme.goldLight,
                  ),
                  Slider(
                    value: activePhase.duration.toDouble(),
                    min: 0,
                    max: 240,
                    divisions: 48,
                    onChanged: (val) {
                      _updateActivePhase(activePhase.copyWith(duration: val.round()));
                    },
                  ),
                  _buildChipRow([
                    _PresetChip('0s (Skip)', () => _updateActivePhase(activePhase.copyWith(duration: 0))),
                    _PresetChip('15s', () => _updateActivePhase(activePhase.copyWith(duration: 15))),
                    _PresetChip('30s', () => _updateActivePhase(activePhase.copyWith(duration: 30))),
                    _PresetChip('45s', () => _updateActivePhase(activePhase.copyWith(duration: 45))),
                    _PresetChip('60s', () => _updateActivePhase(activePhase.copyWith(duration: 60))),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Binary Inspector
            ExpansionTile(
              backgroundColor: AppTheme.surfaceCard,
              collapsedBackgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              title: const Text(
                'Live Binary Packet Inspector (CRC-16 & Hex)',
                style: TextStyle(
                  color: AppTheme.goldPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('CRC-16 CCITT: 0x${crc.toRadixString(16).toUpperCase()}',
                        style: const TextStyle(color: AppTheme.crema, fontSize: 12, fontFamily: 'monospace')),
                    Text('Packet Size: ${packet.length} bytes',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontFamily: 'monospace')),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  packetHex,
                  style: const TextStyle(
                    color: Color(0xFFA0C4FF),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Save & Flash Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: const Text('Save to My Recipes'),
                    onPressed: _saveToLocal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.flash_on, size: 18),
                    label: const Text('Flash to Machine'),
                    onPressed: () {
                      FlashRecipeDialog.show(
                        context,
                        recipe: currentRecipe,
                        bleService: widget.bleService,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseTab(int index, String title) {
    final isActive = _activePhaseIndex == index;
    final isConfigured = _phases[index].duration > 0;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activePhaseIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.goldPrimary.withOpacity(0.18) : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppTheme.goldPrimary : AppTheme.borderSubtle,
              width: isActive ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isActive ? AppTheme.goldLight : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isConfigured ? '${_phases[index].duration}s' : 'Off',
                style: TextStyle(
                  color: isConfigured ? AppTheme.crema : AppTheme.textMuted,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderHeader(String name, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildChipRow(List<_PresetChip> chips) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((c) {
          return Padding(
            padding: const EdgeInsets.only(right: 6, top: 4),
            child: ActionChip(
              label: Text(c.label),
              labelStyle: TextStyle(
                color: c.color ?? AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: AppTheme.surfaceElevated,
              side: const BorderSide(color: AppTheme.borderSubtle, width: 0.6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              onPressed: c.onTap,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PresetChip {
  final String label;
  final VoidCallback onTap;
  final Color? color;

  _PresetChip(this.label, this.onTap, {this.color});
}
