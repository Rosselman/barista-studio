import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/phase.dart';
import '../../models/recipe.dart';
import '../../models/recipe_step.dart';
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
  late TextEditingController _descriptionController;
  late String _recipeId;

  // Multi-Step State
  bool _isMultiStep = false;
  int _activeStepIndex = 0; // 0: Step 1, 1: Step 2
  int _activePhaseIndex = 0; // 0..2 within the active step
  late TextEditingController _step1NameController;
  late TextEditingController _step2NameController;
  late TextEditingController _step1PromptController;
  late TextEditingController _step2PromptController;
  late List<Phase> _step1Phases;
  late List<Phase> _step2Phases;

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
      _recipeId = recipe.id;
      _nameController = TextEditingController(text: recipe.hardwareName);
      _descriptionController = TextEditingController(text: recipe.description);
      _isMultiStep = recipe.isMultiStep;
      _activeStepIndex = 0;
      _activePhaseIndex = 0;

      final s1 = recipe.steps.isNotEmpty ? recipe.steps[0] : null;
      _step1NameController = TextEditingController(text: s1?.name ?? 'STEP 1');
      _step1PromptController = TextEditingController(text: s1?.instruction ?? '');
      _step1Phases = List.generate(3, (i) {
        if (s1 != null && i < s1.phases.length) {
          return s1.phases[i];
        }
        return Phase.clamped(duration: 0);
      });

      final s2 = recipe.steps.length > 1 ? recipe.steps[1] : null;
      _step2NameController = TextEditingController(text: s2?.name ?? 'STEP 2');
      _step2PromptController = TextEditingController(text: s2?.instruction ?? '');
      _step2Phases = List.generate(3, (i) {
        if (s2 != null && i < s2.phases.length) {
          return s2.phases[i];
        }
        return i == 0
            ? Phase.clamped(speed: 2400, accel: 800, temp: 65, duration: 35)
            : Phase.clamped(duration: 0);
      });
    } else {
      _recipeId = const Uuid().v4();
      _nameController = TextEditingController(text: 'VELVET FOAM');
      _descriptionController = TextEditingController(
          text: 'Artisanal microfoam profile created in Barista Studio.');
      _isMultiStep = false;
      _activeStepIndex = 0;
      _activePhaseIndex = 0;

      _step1NameController = TextEditingController(text: 'STEP 1');
      _step1PromptController = TextEditingController(text: 'Add coffee & ingredients');
      _step1Phases = [
        Phase.clamped(speed: 3200, accel: 800, temp: 45, duration: 25),
        Phase.clamped(speed: 1200, accel: 600, temp: 65, duration: 15),
        Phase.clamped(speed: 800, accel: 400, temp: 65, duration: 0),
      ];

      _step2NameController = TextEditingController(text: 'STEP 2');
      _step2PromptController =
          TextEditingController(text: 'Add cold milk & press dial to resume');
      _step2Phases = [
        Phase.clamped(speed: 2400, accel: 800, temp: 65, duration: 35),
        Phase.clamped(duration: 0),
        Phase.clamped(duration: 0),
      ];
    }
  }

  void setRecipe(Recipe recipe) {
    setState(() {
      _mode = RecipeCraftMode.manual;
      _recipeId = recipe.id;
      _nameController.text = recipe.hardwareName;
      _descriptionController.text = recipe.description;
      _isMultiStep = recipe.isMultiStep;
      _activeStepIndex = 0;
      _activePhaseIndex = 0;

      final s1 = recipe.steps.isNotEmpty ? recipe.steps[0] : null;
      _step1NameController.text = s1?.name ?? 'STEP 1';
      _step1PromptController.text = s1?.instruction ?? '';
      _step1Phases = List.generate(3, (i) {
        if (s1 != null && i < s1.phases.length) {
          return s1.phases[i];
        }
        return Phase.clamped(duration: 0);
      });

      final s2 = recipe.steps.length > 1 ? recipe.steps[1] : null;
      _step2NameController.text = s2?.name ?? 'STEP 2';
      _step2PromptController.text = s2?.instruction ?? '';
      _step2Phases = List.generate(3, (i) {
        if (s2 != null && i < s2.phases.length) {
          return s2.phases[i];
        }
        return i == 0
            ? Phase.clamped(speed: 2400, accel: 800, temp: 65, duration: 35)
            : Phase.clamped(duration: 0);
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _step1NameController.dispose();
    _step2NameController.dispose();
    _step1PromptController.dispose();
    _step2PromptController.dispose();
    _guidedNameController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Guided Recipe Synthesis Algorithm
  // ===========================================================================

  String _deriveGuidedName() {
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
          temp = 60;
          break;
        case 'almond':
          temp = 56;
          break;
        case 'coconut':
          temp = 58;
          break;
        case 'cream':
          temp = 62;
          break;
        case 'dairy':
        default:
          temp = 68;
          break;
      }
    }

    int p1Speed, p1Duration, p1Accel;
    int p2Speed, p2Duration, p2Accel;
    int p3Speed, p3Duration, p3Accel;

    switch (_guidedTexture) {
      case 'dense':
        p1Speed = 3400;
        p1Duration = 22;
        p1Accel = 900;
        p2Speed = 2200;
        p2Duration = 14;
        p2Accel = 600;
        p3Speed = 1000;
        p3Duration = 8;
        p3Accel = 400;
        break;
      case 'latteArt':
        p1Speed = 3000;
        p1Duration = 18;
        p1Accel = 750;
        p2Speed = 1200;
        p2Duration = 20;
        p2Accel = 400;
        p3Speed = 700;
        p3Duration = 10;
        p3Accel = 300;
        break;
      case 'chantilly':
        p1Speed = 3800;
        p1Duration = 25;
        p1Accel = 1000;
        p2Speed = 1600;
        p2Duration = 15;
        p2Accel = 500;
        p3Speed = 0;
        p3Duration = 0;
        p3Accel = 200;
        break;
      case 'stir':
      default:
        p1Speed = 1400;
        p1Duration = 30;
        p1Accel = 500;
        p2Speed = 800;
        p2Duration = 15;
        p2Accel = 300;
        p3Speed = 0;
        p3Duration = 0;
        p3Accel = 200;
        break;
    }

    if (_guidedInclusion == 'powder') {
      p1Speed = (p1Speed * 0.85).round().clamp(300, 4000);
      p1Duration += 5;
    } else if (_guidedInclusion == 'syrup') {
      p1Duration += 3;
    }

    final phases = <Phase>[
      Phase.clamped(speed: p1Speed, accel: p1Accel, temp: temp > 0 ? (temp - 10).clamp(0, 70) : 0, duration: p1Duration),
      Phase.clamped(speed: p2Speed, accel: p2Accel, temp: temp, duration: p2Duration),
    ];
    if (p3Duration > 0) {
      phases.add(Phase.clamped(speed: p3Speed, accel: p3Accel, temp: temp, duration: p3Duration));
    }

    final name = _guidedNameController.text.trim().isEmpty ? _deriveGuidedName() : _guidedNameController.text.trim();
    final clampedName = name.length > 16 ? name.substring(0, 16) : name;

    return Recipe(
      id: _recipeId,
      name: clampedName,
      description: 'Formulated $_guidedTemp $_guidedBase with $_guidedLiquid and $_guidedTexture texture.',
      category: _guidedTemp == 'cold' ? 'Iced & Cold Coffee' : 'Hot Coffee',
      tags: [
        _guidedTemp == 'cold' ? 'Iced & Cold Coffee' : 'Hot Coffee',
        _guidedLiquid == 'dairy' ? 'Dairy' : 'Non-Dairy',
        if (_guidedTexture == 'dense') 'Cold Foam & Textures',
      ],
      steps: [
        RecipeStep(
          name: 'STEP 1',
          phases: phases,
        ),
      ],
      isCustom: true,
    );
  }

  void _applyGuidedToManual() {
    final recipe = _synthesizeGuidedRecipe();
    setState(() {
      _nameController.text = recipe.hardwareName;
      _descriptionController.text = recipe.description;
      _isMultiStep = false;
      _activeStepIndex = 0;
      _step1Phases = List.generate(3, (i) {
        if (i < recipe.phases.length) {
          return recipe.phases[i];
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
    final name = _nameController.text.trim().isEmpty ? 'Custom Froth' : _nameController.text.trim();
    final desc = _descriptionController.text.trim().isEmpty
        ? (_isMultiStep
            ? 'Custom multi-step Barista recipe with hardware pause.'
            : 'Custom single-step Barista recipe created in Studio.')
        : _descriptionController.text.trim();

    if (_isMultiStep) {
      final s1Active = _step1Phases.where((p) => p.duration > 0).toList();
      final s2Active = _step2Phases.where((p) => p.duration > 0).toList();

      return Recipe(
        id: _recipeId,
        name: name,
        description: desc,
        category: 'Specialty',
        tags: const ['Multi-Step', 'Specialty'],
        steps: [
          RecipeStep(
            name: _step1NameController.text.trim().isEmpty ? 'STEP 1' : _step1NameController.text.trim(),
            phases: s1Active.isEmpty
                ? [Phase.clamped(speed: 3000, accel: 800, temp: 0, duration: 15)]
                : s1Active,
            instruction: _step1PromptController.text.trim().isEmpty ? null : _step1PromptController.text.trim(),
          ),
          RecipeStep(
            name: _step2NameController.text.trim().isEmpty ? 'STEP 2' : _step2NameController.text.trim(),
            phases: s2Active.isEmpty
                ? [Phase.clamped(speed: 2400, accel: 800, temp: 65, duration: 35)]
                : s2Active,
            instruction: _step2PromptController.text.trim().isEmpty ? null : _step2PromptController.text.trim(),
          ),
        ],
        isCustom: true,
      );
    }

    final s1Active = _step1Phases.where((p) => p.duration > 0).toList();
    return Recipe(
      id: _recipeId,
      name: name,
      description: desc,
      category: 'Specialty',
      steps: [
        RecipeStep(
          name: _step1NameController.text.trim().isEmpty ? 'STEP 1' : _step1NameController.text.trim(),
          phases: s1Active.isEmpty
              ? [Phase.clamped(speed: 3000, accel: 800, temp: 65, duration: 30)]
              : s1Active,
          instruction: _step1PromptController.text.trim().isEmpty ? null : _step1PromptController.text.trim(),
        ),
      ],
      isCustom: true,
    );
  }

  void _updateActivePhase(Phase newPhase) {
    setState(() {
      if (_isMultiStep && _activeStepIndex == 1) {
        _step2Phases[_activePhaseIndex] = newPhase;
      } else {
        _step1Phases[_activePhaseIndex] = newPhase;
      }
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
      steps: currentRecipe.steps,
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
                      subtitle: 'Multi-Step Granular Studio',
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
                      'Steps: ${currentRecipe.stepCount} (${currentRecipe.isMultiStep ? "Multi-Step ⏸️" : "Single-Step"})',
                      style: const TextStyle(
                        color: AppTheme.goldLight,
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
  // Guided Mode View
  // ===========================================================================

  Widget _buildGuidedView(Recipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question 1: Temperature Profile
        _buildGuidedCard(
          question: '1. Temperature Profile',
          subtitle: 'Determines whether induction heating triggers during the cycle',
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
                label: '🌤️ Warm & Silky (54-64°C)',
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
                label: '🔥 Piping Hot (60-68°C)',
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
          question: '2. Flavor & Base Essence',
          subtitle: 'Adjusts whisk acceleration and shear-thinning rate',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildGuidedChoice(
                label: '☕ Espresso / Coffee',
                selected: _guidedBase == 'coffee',
                onTap: () {
                  setState(() {
                    _guidedBase = 'coffee';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '🍫 Rich Chocolate / Cocoa',
                selected: _guidedBase == 'chocolate',
                onTap: () {
                  setState(() {
                    _guidedBase = 'chocolate';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '🍵 Matcha / Botanical Tea',
                selected: _guidedBase == 'tea',
                onTap: () {
                  setState(() {
                    _guidedBase = 'tea';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '🥛 Pure Foam (No Additives)',
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

        // Question 3: Liquid Medium / Milk
        _buildGuidedCard(
          question: '3. Milk & Plant Liquid Medium',
          subtitle: 'Selects denaturation temperature and protein aeration curve',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildGuidedChoice(
                label: '🐄 Whole / Semi Dairy Milk',
                selected: _guidedLiquid == 'dairy',
                onTap: () {
                  setState(() {
                    _guidedLiquid = 'dairy';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '🌾 Barista Oat Milk',
                selected: _guidedLiquid == 'oat',
                onTap: () {
                  setState(() {
                    _guidedLiquid = 'oat';
                    _guidedNameController.text = _deriveGuidedName();
                  });
                },
              ),
              _buildGuidedChoice(
                label: '🌰 Almond Milk',
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
                label: '🍦 Heavy Cream / Half & Half',
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
          question: '4. Desired Foam Texture & Density',
          subtitle: 'Calculates RPM milestones from silky pourable to stiff peaks',
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
    final currentPhases = (_isMultiStep && _activeStepIndex == 1) ? _step2Phases : _step1Phases;
    final activePhase = currentPhases[_activePhaseIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipe Name & Description Card
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
                  onChanged: (val) => setState(() {}),
                ),
              ),
              const SizedBox(height: 14),

              // Description & Notes Field
              const Text(
                'Recipe Description & Notes',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  maxLength: 240,
                  style: const TextStyle(
                    color: AppTheme.crema,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: 'Describe taste, milk ratio, or prep instructions...',
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Multi-Step Hardware Pause Toggle Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isMultiStep ? AppTheme.goldPrimary.withOpacity(0.10) : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isMultiStep ? AppTheme.goldPrimary.withOpacity(0.6) : AppTheme.borderSubtle,
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isMultiStep ? AppTheme.goldPrimary.withOpacity(0.25) : AppTheme.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.alt_route,
                      color: _isMultiStep ? AppTheme.goldLight : AppTheme.textMuted,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Multi-Step Recipe (Hardware Paused Execution)',
                          style: TextStyle(
                            color: AppTheme.crema,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isMultiStep
                              ? 'Step 1 runs -> Machine pauses motor/heat (RECIPE_PAUSED) -> Add milk -> Press dial -> Step 2 runs!'
                              : 'Single continuous step. Toggle on to create multi-stage recipes with mid-cycle pause.',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isMultiStep,
                    activeColor: AppTheme.goldPrimary,
                    onChanged: (val) {
                      setState(() {
                        _isMultiStep = val;
                        if (!val) _activeStepIndex = 0;
                      });
                    },
                  ),
                ],
              ),

              // When Multi-Step is enabled, show Step Selector & Step Details
              if (_isMultiStep) ...[
                const Divider(color: AppTheme.borderSubtle, height: 24),
                Row(
                  children: [
                    _buildStepSelectorTab(0, 'Step 1', 'Prep / Base'),
                    const SizedBox(width: 10),
                    _buildStepSelectorTab(1, 'Step 2', 'Froth & Finish'),
                  ],
                ),
                const SizedBox(height: 14),

                // Active Step Configuration Fields
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Step ${_activeStepIndex + 1} Name',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceInput,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: TextField(
                              controller: _activeStepIndex == 0 ? _step1NameController : _step2NameController,
                              maxLength: 16,
                              style: const TextStyle(color: AppTheme.crema, fontSize: 13, fontWeight: FontWeight.w700),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                                counterText: '',
                                border: InputBorder.none,
                              ),
                              onChanged: (val) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Step ${_activeStepIndex + 1} User Prompt / Action',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceInput,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: TextField(
                              controller: _activeStepIndex == 0 ? _step1PromptController : _step2PromptController,
                              style: const TextStyle(color: AppTheme.crema, fontSize: 12),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                border: InputBorder.none,
                                hintText: _activeStepIndex == 0 ? 'e.g. Add coffee & ice' : 'e.g. Add milk & press dial',
                                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              ),
                              onChanged: (val) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Phase Selector for active step (Phase 1, 2, 3)
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
                    _isMultiStep
                        ? 'Step ${_activeStepIndex + 1} • Phase ${_activePhaseIndex + 1} Parameters'
                        : 'Phase ${_activePhaseIndex + 1} Parameters',
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
                _PresetChip('Aggressive (1500)', () => _updateActivePhase(activePhase.copyWith(accel: 1500))),
              ]),
              const SizedBox(height: 18),

              // 3. Temperature Slider
              _buildSliderHeader(
                'Induction Heater Temperature',
                activePhase.temp == 0 ? 'Cold (Heater Off)' : '${activePhase.temp}°C',
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
                _PresetChip('Cold Froth (0°C)', () => _updateActivePhase(activePhase.copyWith(temp: 0)), color: AppTheme.cyanCold),
                _PresetChip('Warm (55°C)', () => _updateActivePhase(activePhase.copyWith(temp: 55))),
                _PresetChip('Hot (65°C)', () => _updateActivePhase(activePhase.copyWith(temp: 65)), color: AppTheme.amberHeat),
                _PresetChip('Max (70°C)', () => _updateActivePhase(activePhase.copyWith(temp: 70)), color: AppTheme.rubyEmergency),
              ]),
              const SizedBox(height: 18),

              // 4. Duration Slider
              _buildSliderHeader(
                'Phase Duration',
                activePhase.duration == 0 ? '0s (Phase Inactive)' : '${activePhase.duration} seconds',
                activePhase.duration == 0 ? AppTheme.textMuted : AppTheme.goldLight,
              ),
              Slider(
                value: activePhase.duration.toDouble(),
                min: 0,
                max: 120,
                divisions: 120,
                onChanged: (val) {
                  _updateActivePhase(activePhase.copyWith(duration: val.round()));
                },
              ),
              _buildChipRow([
                _PresetChip('Skip (0s)', () => _updateActivePhase(activePhase.copyWith(duration: 0)), color: AppTheme.textMuted),
                _PresetChip('Flash (10s)', () => _updateActivePhase(activePhase.copyWith(duration: 10))),
                _PresetChip('Standard (25s)', () => _updateActivePhase(activePhase.copyWith(duration: 25))),
                _PresetChip('Long (45s)', () => _updateActivePhase(activePhase.copyWith(duration: 45))),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Step Execution Overview Card
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
                    'Sequence Architecture Overview',
                    style: TextStyle(
                      color: AppTheme.crema,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _isMultiStep ? '2 Stages • Dual Whisk' : '1 Stage • Single Cycle',
                    style: const TextStyle(
                      color: AppTheme.goldLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Divider(color: AppTheme.borderSubtle, height: 18),

              // Step 1 Phases
              _buildStepSummaryRow(
                stepName: _step1NameController.text.isEmpty ? 'STEP 1' : _step1NameController.text,
                phases: _step1Phases,
                instruction: _step1PromptController.text,
              ),

              if (_isMultiStep) ...[
                // Pause Marker
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.35)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.pause_circle_outline, color: AppTheme.goldLight, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⏸️ Machine Firmware Pauses: Add milk/ingredients & press center button to resume',
                          style: TextStyle(color: AppTheme.goldLight, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                // Step 2 Phases
                _buildStepSummaryRow(
                  stepName: _step2NameController.text.isEmpty ? 'STEP 2' : _step2NameController.text,
                  phases: _step2Phases,
                  instruction: _step2PromptController.text,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepSelectorTab(int index, String title, String subtitle) {
    final isSelected = _activeStepIndex == index;
    final phases = index == 0 ? _step1Phases : _step2Phases;
    final activeCount = phases.where((p) => p.duration > 0).length;
    final totalDur = phases.where((p) => p.duration > 0).fold(0, (acc, p) => acc + p.duration);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _activeStepIndex = index;
          _activePhaseIndex = 0;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.goldPrimary.withOpacity(0.18) : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.goldPrimary : AppTheme.borderSubtle,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppTheme.goldLight : AppTheme.crema,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${totalDur}s',
                      style: const TextStyle(
                        color: AppTheme.goldLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '$activeCount active phase${activeCount == 1 ? "" : "s"} • $subtitle',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10.5,
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

  Widget _buildStepSummaryRow({
    required String stepName,
    required List<Phase> phases,
    required String instruction,
  }) {
    final active = phases.where((p) => p.duration > 0).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              stepName,
              style: const TextStyle(
                color: AppTheme.crema,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (instruction.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '($instruction)',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        if (active.isEmpty)
          const Text('No active phases', style: TextStyle(color: AppTheme.textMuted, fontSize: 11))
        else
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: active.asMap().entries.map((e) {
              final idx = e.key + 1;
              final p = e.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceInput,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Text(
                  'P$idx: ${p.duration}s @ ${p.speed} RPM (${p.temp == 0 ? "Cold" : "${p.temp}°C"})',
                  style: const TextStyle(color: AppTheme.crema, fontSize: 10.5, fontFamily: 'monospace'),
                ),
              );
            }).toList(),
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
    final currentPhases = (_isMultiStep && _activeStepIndex == 1) ? _step2Phases : _step1Phases;
    final isConfigured = currentPhases[index].duration > 0;

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
                isConfigured ? '${currentPhases[index].duration}s ($subtitle)' : 'Off ($subtitle)',
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
