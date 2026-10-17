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

enum RecipeCraftMode { guided, manual }

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
  RecipeCraftMode _mode = RecipeCraftMode.guided;

  // Manual Mode State
  late TextEditingController _nameController;
  late String _recipeId;
  int _activePhaseIndex = 0;
  late List<Phase> _phases;

  // Guided Mode State
  String _guidedTemp = 'cold'; // 'cold', 'warm', 'hot'
  String _guidedBase = 'coffee'; // 'coffee', 'chocolate', 'tea', 'neutral'
  String _guidedLiquid = 'dairy'; // 'dairy', 'oat', 'almond', 'coconut', 'cream'
  String _guidedTexture = 'dense'; // 'dense', 'latteArt', 'chantilly', 'stir'
  String _guidedInclusion = 'none'; // 'none', 'syrup', 'powder'
  late TextEditingController _guidedNameController;

  @override
  void initState() {
    super.initState();
    _loadRecipe(widget.initialRecipe);
    _guidedNameController = TextEditingController(text: _deriveGuidedName());
  }

  void _loadRecipe(Recipe? recipe) {
    if (recipe != null) {
      _mode = RecipeCraftMode.manual;
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
        Phase.clamped(speed: 800, accel: 400, temp: 65, duration: 0),
      ];
    }
  }

  void setRecipe(Recipe recipe) {
    setState(() {
      _mode = RecipeCraftMode.manual;
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
    _guidedNameController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Guided Recipe Synthesis Algorithm
  // ===========================================================================

  String _deriveGuidedName() {
    // Generate an ASCII machine name clamped to 16 characters
    final prefix = _guidedTemp == 'cold' ? 'COLD' : (_guidedTemp == 'hot' ? 'HOT' : 'WARM');
    String baseWord;
    switch (_guidedBase) {
      case 'chocolate':
        baseWord = 'CHOCO';
        break;
      case 'tea':
        baseWord = 'MATCHA';
        break;
      case 'neutral':
        baseWord = _guidedLiquid == 'oat'
            ? 'OAT'
            : (_guidedLiquid == 'almond'
                ? 'ALMOND'
                : (_guidedLiquid == 'coconut' ? 'COCO' : (_guidedLiquid == 'cream' ? 'CREAM' : 'MILK')));
        break;
      case 'coffee':
      default:
        baseWord = _guidedLiquid == 'cream'
            ? 'CREMA'
            : (_guidedLiquid == 'oat'
                ? 'OAT'
                : (_guidedLiquid == 'coconut' ? 'COCO' : 'ESPR'));
        break;
    }

    String textureWord;
    switch (_guidedTexture) {
      case 'latteArt':
        textureWord = 'SILK';
        break;
      case 'chantilly':
        textureWord = 'VELVET';
        break;
      case 'stir':
        textureWord = 'MELT';
        break;
      case 'dense':
      default:
        textureWord = 'CLOUD';
        break;
    }

    final candidate = '$prefix $baseWord $textureWord'.toUpperCase();
    if (candidate.length <= 16) return candidate;
    return '$prefix $textureWord'.toUpperCase().substring(0, 16);
  }

  Recipe _synthesizeGuidedRecipe() {
    // 1. Target Temperature
    int temp = 0;
    if (_guidedTemp == 'warm') {
      switch (_guidedLiquid) {
        case 'oat':
          temp = 58;
          break;
        case 'almond':
          temp = 54;
          break;
        case 'coconut':
          temp = 56;
          break;
        case 'cream':
          temp = 60;
          break;
        case 'dairy':
        default:
          temp = 64;
          break;
      }
    } else if (_guidedTemp == 'hot') {
      switch (_guidedLiquid) {
        case 'oat':
          temp = 60; // oat burns if overheated
          break;
        case 'almond':
          temp = 56;
          break;
        case 'coconut':
          temp = 62;
          break;
        case 'cream':
          temp = 68;
          break;
        case 'dairy':
        default:
          temp = 70;
          break;
      }
    }

    // 2. Synthesize Phases
    List<Phase> phases = [];
    final hasPowder = _guidedInclusion == 'powder';
    final hasSyrup = _guidedInclusion == 'syrup';

    switch (_guidedTexture) {
      case 'dense': // Cloud foam
        final int whipSpeed = _guidedLiquid == 'cream'
            ? 3200
            : (_guidedLiquid == 'oat' || _guidedLiquid == 'almond' ? 3800 : 4000);
        final int whipDuration = hasPowder ? 32 : 26;
        phases.add(Phase.clamped(
          speed: whipSpeed,
          accel: 1400,
          temp: temp > 0 ? (temp - 15).clamp(25, 70) : 0,
          duration: whipDuration,
        ));
        phases.add(Phase.clamped(
          speed: 1200,
          accel: 400,
          temp: temp,
          duration: 14,
        ));
        break;

      case 'latteArt': // Silky microfoam
        final int aerateSpeed = _guidedLiquid == 'cream' ? 2400 : 3200;
        phases.add(Phase.clamped(
          speed: aerateSpeed,
          accel: 800,
          temp: temp > 0 ? (temp - 12).clamp(25, 70) : 0,
          duration: hasPowder ? 24 : 18,
        ));
        phases.add(Phase.clamped(
          speed: 1000,
          accel: 400,
          temp: temp,
          duration: 20,
        ));
        break;

      case 'chantilly': // Soft velvet cream
        final int whipSpeed = _guidedLiquid == 'cream' ? 2600 : 3400;
        phases.add(Phase.clamped(
          speed: whipSpeed,
          accel: 900,
          temp: temp > 0 ? (temp - 10).clamp(20, 70) : 0,
          duration: 22,
        ));
        phases.add(Phase.clamped(
          speed: 900,
          accel: 300,
          temp: temp,
          duration: 12,
        ));
        break;

      case 'stir': // Gentle dissolve & melt
      default:
        phases.add(Phase.clamped(
          speed: hasPowder ? 1800 : 1400,
          accel: 500,
          temp: temp > 0 ? (temp - 15).clamp(20, 70) : 0,
          duration: hasPowder ? 25 : 18,
        ));
        phases.add(Phase.clamped(
          speed: 1000,
          accel: 300,
          temp: temp,
          duration: 32,
        ));
        if (temp >= 65) {
          phases.add(Phase.clamped(
            speed: 600,
            accel: 200,
            temp: temp,
            duration: 15,
          ));
        }
        break;
    }

    final name = _guidedNameController.text.trim().isEmpty
        ? _deriveGuidedName()
        : _guidedNameController.text.trim();

    return Recipe(
      id: _recipeId,
      name: name,
      description: 'Guided formula: ${_guidedTemp.toUpperCase()} ${_guidedLiquid.toUpperCase()} with ${_guidedTexture.toUpperCase()} texture.',
      category: _guidedBase == 'coffee' ? 'Coffee' : 'Non-Coffee',
      phases: phases,
      isCustom: true,
      ingredients: [
        '100 ml Cold ${_guidedLiquid == 'dairy' ? 'whole milk' : (_guidedLiquid == 'oat' ? 'oat milk' : (_guidedLiquid == 'almond' ? 'almond milk' : (_guidedLiquid == 'coconut' ? 'coconut milk' : 'heavy cream')))}',
        if (_guidedBase == 'coffee') '1 Nespresso espresso shot (40 ml)',
        if (_guidedBase == 'chocolate') '15g Fine cocoa powder or chocolate squares',
        if (_guidedBase == 'tea') '2g Ceremonial matcha or concentrated tea',
        if (hasSyrup) '10 ml Flavored syrup or honey',
      ],
      instructions: [
        'Insert Barista whisk into jug.',
        'Add ingredients into the jug.',
        'Flash formula to machine slot and start cycle.',
      ],
    );
  }

  void _applyGuidedToManual() {
    final generated = _synthesizeGuidedRecipe();
    setState(() {
      _nameController.text = generated.hardwareName;
      _phases = List.generate(3, (i) {
        if (i < generated.phases.length) {
          return generated.phases[i];
        }
        return Phase.clamped(duration: 0);
      });
      _activePhaseIndex = 0;
      _mode = RecipeCraftMode.manual;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Guided formula transferred to Manual Sequencer.'),
        backgroundColor: AppTheme.surfaceElevated,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ===========================================================================
  // Manual Recipe State
  // ===========================================================================

  Recipe _getCurrentRecipe() {
    if (_mode == RecipeCraftMode.guided) {
      return _synthesizeGuidedRecipe();
    }
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
            // Mode Segmented Switcher
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      mode: RecipeCraftMode.guided,
                      title: 'Guided Barista',
                      icon: Icons.auto_awesome,
                      subtitle: 'Interactive Smart Formulator',
                    ),
                  ),
                  Expanded(
                    child: _buildModeTab(
                      mode: RecipeCraftMode.manual,
                      title: 'Manual Sequencer',
                      icon: Icons.tune,
                      subtitle: '3-Phase Granular Studio',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Content based on Mode
            if (_mode == RecipeCraftMode.guided)
              _buildGuidedView(currentRecipe)
            else
              _buildManualView(),

            const SizedBox(height: 18),

            // Live Binary Inspector (Shared by both modes with Wrap to prevent overflow)
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
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Text(
                      'CRC-16 CCITT: 0x${crc.toRadixString(16).toUpperCase()}',
                      style: const TextStyle(
                        color: AppTheme.crema,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'Packet Size: ${packet.length} bytes',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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

  // ===========================================================================
  // Guided Mode Widgets
  // ===========================================================================

  Widget _buildGuidedView(Recipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question 1: Temperature & Profile
        _buildGuidedCard(
          question: '1. Temperature & Thermal Profile',
          subtitle: 'Choose between cold foam, velvety warmth, or extra hot melt',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildGuidedChoice(
                label: '❄️ Cold Foam (0°C)',
                selected: _guidedTemp == 'cold',
                color: AppTheme.cyanCold,
                onTap: () {
                  setState(() {
                    _guidedTemp = 'cold';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '☕ Warm & Silky (~60°C)',
                selected: _guidedTemp == 'warm',
                color: AppTheme.goldPrimary,
                onTap: () {
                  setState(() {
                    _guidedTemp = 'warm';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '🔥 Extra Hot (70°C)',
                selected: _guidedTemp == 'hot',
                color: AppTheme.amberHeat,
                onTap: () {
                  setState(() {
                    _guidedTemp = 'hot';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Question 2: Base Beverage
        _buildGuidedCard(
          question: '2. Beverage Style',
          subtitle: 'What kind of drink are you crafting?',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildGuidedChoice(
                label: '☕ Coffee / Espresso',
                selected: _guidedBase == 'coffee',
                onTap: () {
                  setState(() {
                    _guidedBase = 'coffee';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '🍫 Cocoa / Chocolate',
                selected: _guidedBase == 'chocolate',
                onTap: () {
                  setState(() {
                    _guidedBase = 'chocolate';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '🍵 Matcha / Tea / Chai',
                selected: _guidedBase == 'tea',
                onTap: () {
                  setState(() {
                    _guidedBase = 'tea';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '🥛 Pure Foam / Steamer',
                selected: _guidedBase == 'neutral',
                onTap: () {
                  setState(() {
                    _guidedBase = 'neutral';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Question 3: Liquid & Dairy Type
        _buildGuidedCard(
          question: '3. Milk & Liquid Base',
          subtitle: 'Thermal ramps and whisk RPM are tuned specifically for your liquid',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildGuidedChoice(
                label: '🥛 Whole / Dairy Milk',
                selected: _guidedLiquid == 'dairy',
                onTap: () {
                  setState(() {
                    _guidedLiquid = 'dairy';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '🌾 Oat Milk (Barista)',
                selected: _guidedLiquid == 'oat',
                onTap: () {
                  setState(() {
                    _guidedLiquid = 'oat';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '🌰 Almond / Soy',
                selected: _guidedLiquid == 'almond',
                onTap: () {
                  setState(() {
                    _guidedLiquid = 'almond';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '🥥 Coconut Milk',
                selected: _guidedLiquid == 'coconut',
                onTap: () {
                  setState(() {
                    _guidedLiquid = 'coconut';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '🍦 Heavy Cream',
                selected: _guidedLiquid == 'cream',
                onTap: () {
                  setState(() {
                    _guidedLiquid = 'cream';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Question 4: Foam Texture
        _buildGuidedCard(
          question: '4. Foam Texture & Consistency',
          subtitle: 'Select your preferred micro-bubble density and mouthfeel',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildGuidedChoice(
                label: '☁️ Dense Cloud Foam',
                selected: _guidedTexture == 'dense',
                onTap: () {
                  setState(() {
                    _guidedTexture = 'dense';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '🌊 Silky Latte Art',
                selected: _guidedTexture == 'latteArt',
                onTap: () {
                  setState(() {
                    _guidedTexture = 'latteArt';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '🍦 Soft Whipped Velvet',
                selected: _guidedTexture == 'chantilly',
                onTap: () {
                  setState(() {
                    _guidedTexture = 'chantilly';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '🌀 Gentle Melt & Stir',
                selected: _guidedTexture == 'stir',
                onTap: () {
                  setState(() {
                    _guidedTexture = 'stir';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Question 5: Inclusions / Add-ins
        _buildGuidedCard(
          question: '5. Sweetener & Inclusions',
          subtitle: 'Adds early dispersion phases for dissolve and extraction',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildGuidedChoice(
                label: '🚫 None / Plain',
                selected: _guidedInclusion == 'none',
                onTap: () => setState(() => _guidedInclusion = 'none'),
              ),
              _buildGuidedChoice(
                label: '🍯 Syrup / Honey / Sugar',
                selected: _guidedInclusion == 'syrup',
                onTap: () => setState(() => _guidedInclusion = 'syrup'),
              ),
              _buildGuidedChoice(
                label: '🍫 Cocoa / Matcha Powder',
                selected: _guidedInclusion == 'powder',
                onTap: () => setState(() => _guidedInclusion = 'powder'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Formulated Recipe Preview Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.goldPrimary, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldPrimary.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.goldPrimary, size: 17),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Formulated Recipe',
                      style: TextStyle(
                        color: AppTheme.goldLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.tune, size: 13, color: AppTheme.goldPrimary),
                    label: const Text(
                      'Tune in Manual',
                      style: TextStyle(color: AppTheme.goldPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _applyGuidedToManual,
                  ),
                ],
              ),
              const Divider(color: AppTheme.borderSubtle, height: 20),

              // Machine Display Name Field
              Row(
                children: [
                  const Text('Hardware Name: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  Expanded(
                    child: TextField(
                      controller: _guidedNameController,
                      maxLength: 16,
                      style: const TextStyle(
                        color: AppTheme.crema,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        counterText: '',
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Visual Phase Breakdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: recipe.phases.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final p = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$idx',
                            style: const TextStyle(color: AppTheme.goldLight, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${p.duration}s  •  ${p.speed} RPM  •  ${p.temp == 0 ? "Cold (0°C)" : "${p.temp}°C"}',
                            style: const TextStyle(
                              color: AppTheme.crema,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuidedCard({
    required String question,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: AppTheme.crema,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildGuidedChoice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? AppTheme.goldPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.18) : AppTheme.surfaceInput,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? activeColor : AppTheme.borderSubtle,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? (color ?? AppTheme.goldLight) : AppTheme.textSecondary,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Manual Mode Widgets
  // ===========================================================================

  Widget _buildManualView() {
    final activePhase = _phases[_activePhaseIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            _buildPhaseTab(0, 'Phase 1', 'Whip'),
            const SizedBox(width: 8),
            _buildPhaseTab(1, 'Phase 2', 'Texture'),
            const SizedBox(width: 8),
            _buildPhaseTab(2, 'Phase 3', 'Polish'),
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
      ],
    );
  }

  Widget _buildModeTab({
    required RecipeCraftMode mode,
    required String title,
    required IconData icon,
    required String subtitle,
  }) {
    final isSelected = _mode == mode;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.goldPrimary.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.goldPrimary : Colors.transparent,
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? AppTheme.goldLight : AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? AppTheme.goldLight : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? AppTheme.crema : AppTheme.textMuted,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseTab(int index, String title, String subtitle) {
    final isActive = _activePhaseIndex == index;
    final isConfigured = _phases[index].duration > 0;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activePhaseIndex = index),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isActive ? AppTheme.goldLight : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                isConfigured ? '${_phases[index].duration}s ($subtitle)' : 'Off ($subtitle)',
                style: TextStyle(
                  color: isConfigured ? AppTheme.crema : AppTheme.textMuted,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips.map((c) {
        return ActionChip(
          label: Text(c.label),
          labelStyle: TextStyle(
            color: c.color ?? AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: AppTheme.surfaceElevated,
          side: const BorderSide(color: AppTheme.borderSubtle, width: 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          onPressed: c.onTap,
        );
      }).toList(),
    );
  }
}

class _PresetChip {
  final String label;
  final VoidCallback onTap;
  final Color? color;

  _PresetChip(this.label, this.onTap, {this.color});
}
