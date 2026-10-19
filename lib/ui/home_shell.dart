import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../models/machine_telemetry.dart';
import '../models/recipe.dart';
import '../services/barista_ble_service.dart';
import '../services/recipe_share_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'tabs/custom_recipe_tab.dart';
import 'tabs/presets_tab.dart';
import 'tabs/slots_tab.dart';
import 'widgets/about_dialog.dart';
import 'widgets/developer_dialog.dart';
import 'widgets/recipe_detail_dialog.dart';
import 'widgets/step2_instruction_dialog.dart';

class HomeShell extends StatefulWidget {
  final BaristaBleService bleService;
  final StorageService storageService;

  const HomeShell({
    super.key,
    required this.bleService,
    required this.storageService,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  final GlobalKey<CustomRecipeTabState> _customRecipeKey = GlobalKey<CustomRecipeTabState>();

  Timer? _brewTicker;
  DateTime? _stepStartTime;
  int _currentStepNumber = 1;
  MachineState _lastMachineState = MachineState.standby;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.bleService.autoConnect();
    });
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) => _handleIncomingUri(uri),
      onError: (err) => debugPrint('Deep link stream error: $err'),
    );
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleIncomingUri(uri);
      }
    }).catchError((err) {
      debugPrint('Initial deep link error: $err');
    });
  }

  void _handleIncomingUri(Uri uri) {
    final recipe = RecipeShareService.decodeShareUrl(uri.toString());
    if (recipe != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        RecipeDetailDialog.show(
          context,
          recipe: recipe,
          bleService: widget.bleService,
          storageService: widget.storageService,
          isSharedImport: true,
          onCustomize: (customRecipe) {
            setState(() => _currentIndex = 1);
            _customRecipeKey.currentState?.setRecipe(customRecipe);
          },
          onSavedToMyRecipes: () {
            setState(() => _currentIndex = 0);
          },
        );
      });
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _brewTicker?.cancel();
    super.dispose();
  }

  void _syncBrewingState(MachineTelemetry telemetry) {
    final currentState = telemetry.machineState;
    if (currentState == _lastMachineState) return;

    if (currentState == MachineState.recipeExecuting) {
      if (_lastMachineState == MachineState.recipePaused) {
        _currentStepNumber++;
      } else {
        _currentStepNumber = 1;
      }
      _stepStartTime = DateTime.now();
      _startBrewTicker();
    } else if (currentState == MachineState.recipePaused) {
      _stopBrewTicker();
    } else if (currentState == MachineState.ready || currentState == MachineState.standby) {
      _stopBrewTicker();
      _currentStepNumber = 1;
      _stepStartTime = null;
    }

    _lastMachineState = currentState;
  }

  void _startBrewTicker() {
    _brewTicker?.cancel();
    _brewTicker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopBrewTicker() {
    _brewTicker?.cancel();
    _brewTicker = null;
  }

  Recipe? _resolveActiveRecipe(int? slotIdx) {
    if (slotIdx == null || slotIdx < 0 || slotIdx >= 13) return null;
    final slot = widget.bleService.slots[slotIdx];
    return widget.storageService.resolveRecipe(
      uuid: slot.recipeUuid,
      name: slot.recipeName,
    );
  }

  (String, double?) _buildBrewingStatus(
    MachineTelemetry telemetry,
    bool isConnected,
    bool isScanning,
  ) {
    if (!isConnected) {
      final text = isScanning
          ? 'SEARCHING FOR BARISTA W545...'
          : 'DISCONNECTED • TAP CONNECT TO PAIR';
      return (text, null);
    }

    final isPaused = telemetry.machineState.isPaused;
    final isExecuting = telemetry.machineState.isExecuting;
    final slotIdx = telemetry.selectedSlot;
    final slotNumStr = (slotIdx != null && slotIdx >= 0 && slotIdx < 13)
        ? 'Slot ${slotIdx + 1}'
        : '';

    if (isPaused) {
      final recipe = _resolveActiveRecipe(slotIdx);
      final recipeName = recipe?.name ??
          (slotIdx != null ? widget.bleService.slots[slotIdx].recipeName : '');
      final nameSuffix = recipeName.isNotEmpty ? ' • $recipeName' : '';
      return ('Barista connected • ⏸️ Paused (Press Dial for Step 2)$nameSuffix', 1.0);
    }

    if (isExecuting) {
      final recipe = _resolveActiveRecipe(slotIdx);
      final elapsed = _stepStartTime != null
          ? DateTime.now().difference(_stepStartTime!).inSeconds
          : 0;

      if (recipe != null) {
        if (recipe.isMultiStep && recipe.steps.isNotEmpty) {
          final stepIdx = (_currentStepNumber - 1).clamp(0, recipe.steps.length - 1);
          final activeStep = recipe.steps[stepIdx];
          final phases = activeStep.phases;
          final stepTotalSec = phases.fold<int>(0, (s, p) => s + p.duration);

          int currentPhase = 1;
          int phaseRemaining = phases.isNotEmpty ? phases[0].duration : 0;
          int acc = 0;
          for (int i = 0; i < phases.length; i++) {
            final pDuration = phases[i].duration;
            if (elapsed < acc + pDuration || i == phases.length - 1) {
              currentPhase = i + 1;
              phaseRemaining = ((acc + pDuration) - elapsed).clamp(0, pDuration);
              break;
            }
            acc += pDuration;
          }

          final prog = stepTotalSec > 0
              ? (elapsed / stepTotalSec).clamp(0.0, 1.0)
              : 0.0;
          final text =
              '🔄 Executing • Step $_currentStepNumber, Phase $currentPhase • ${phaseRemaining}s left • $slotNumStr (${recipe.name})';
          return (text, prog);
        } else {
          final phases = recipe.activePhases;
          final totalSec = recipe.totalDurationSeconds;

          int currentPhase = 1;
          int phaseRemaining = phases.isNotEmpty ? phases[0].duration : 0;
          int acc = 0;
          for (int i = 0; i < phases.length; i++) {
            final pDuration = phases[i].duration;
            if (elapsed < acc + pDuration || i == phases.length - 1) {
              currentPhase = i + 1;
              phaseRemaining = ((acc + pDuration) - elapsed).clamp(0, pDuration);
              break;
            }
            acc += pDuration;
          }

          final prog = totalSec > 0
              ? (elapsed / totalSec).clamp(0.0, 1.0)
              : 0.0;
          final phaseStr = phases.length > 1
              ? 'Phase $currentPhase of ${phases.length}'
              : 'Phase 1';
          final text =
              '🔄 Executing • $phaseStr • ${phaseRemaining}s left • $slotNumStr (${recipe.name})';
          return (text, prog);
        }
      } else {
        // Unknown recipe fallback
        final slotName = (slotIdx != null && slotIdx >= 0 && slotIdx < 13)
            ? widget.bleService.slots[slotIdx].recipeName
            : '';
        final nameStr = slotName.isNotEmpty ? ' ($slotName)' : '';
        final text = '🔄 Executing • $slotNumStr$nameStr • ${elapsed}s elapsed';
        return (text, null);
      }
    }

    // Idle states: Ready, Standby, Settings
    final slotStatus = slotNumStr.isNotEmpty ? ' • $slotNumStr' : '';
    final text = 'Barista connected • ${telemetry.machineState.label}$slotStatus';
    return (text, null);
  }

  void _onCustomizeRecipe(Recipe recipe) {
    setState(() {
      _currentIndex = 1; // switch to Tab 2
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _customRecipeKey.currentState?.setRecipe(recipe);
    });
  }

  void _onOpenBuilder() {
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.bleService,
      builder: (context, _) {
        final telemetry = widget.bleService.telemetry;
        final isConnected = telemetry.isConnected;
        final isScanning = telemetry.isScanning;

        _syncBrewingState(telemetry);
        final (statusText, brewProgress) =
            _buildBrewingStatus(telemetry, isConnected, isScanning);
        final activeRecipe = _resolveActiveRecipe(telemetry.selectedSlot);

        Color indicatorColor;
        if (!isConnected) {
          indicatorColor = isScanning ? AppTheme.amberHeat : AppTheme.textMuted;
        } else if (telemetry.machineState.isPaused) {
          indicatorColor = AppTheme.goldLight;
        } else if (telemetry.machineState.isExecuting) {
          indicatorColor = AppTheme.cyanCold;
        } else if (telemetry.machineState.isReady) {
          indicatorColor = AppTheme.emeraldSuccess;
        } else if (telemetry.machineState.isStandby) {
          indicatorColor = AppTheme.crema.withOpacity(0.65);
        } else {
          indicatorColor = AppTheme.amberHeat;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;

            final tabs = [
              RecipesTab(
                bleService: widget.bleService,
                storageService: widget.storageService,
                onCustomize: _onCustomizeRecipe,
                onOpenBuilder: _onOpenBuilder,
              ),
              CustomRecipeTab(
                key: _customRecipeKey,
                bleService: widget.bleService,
                storageService: widget.storageService,
              ),
              SlotsTab(
                bleService: widget.bleService,
                storageService: widget.storageService,
                onCustomize: _onCustomizeRecipe,
              ),
            ];

            return Scaffold(
              backgroundColor: AppTheme.bgDark,
              appBar: AppBar(
                titleSpacing: 14,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.coffee, color: AppTheme.goldPrimary, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'BARISTA STUDIO',
                      style: TextStyle(
                        color: AppTheme.crema,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Connect / Disconnect Action
                  if (!isConnected)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          minimumSize: const Size(60, 32),
                        ),
                        icon: isScanning
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.bluetooth, size: 15),
                        label: Text(
                          isScanning ? 'Scan...' : 'Connect',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        onPressed: isScanning
                            ? () => widget.bleService.stopScan()
                            : () => widget.bleService.autoConnect(),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          minimumSize: const Size(54, 32),
                          side: const BorderSide(color: AppTheme.borderSubtle),
                        ),
                        child: const Text('Disconnect', style: TextStyle(fontSize: 10, color: AppTheme.crema)),
                        onPressed: () => widget.bleService.disconnect(),
                      ),
                    ),
                  const SizedBox(width: 4),

                  // Overflow Menu (Developer Menu & About)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppTheme.crema, size: 22),
                      color: AppTheme.surfaceCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppTheme.borderSubtle),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'developer',
                          child: Row(
                            children: [
                              Icon(Icons.terminal, color: AppTheme.goldPrimary, size: 18),
                              SizedBox(width: 10),
                              Text('Developer Menu', style: TextStyle(color: AppTheme.crema, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'about',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: AppTheme.goldLight, size: 18),
                              SizedBox(width: 10),
                              Text('About Barista Studio', style: TextStyle(color: AppTheme.crema, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (val) {
                        if (val == 'developer') {
                          DeveloperDialog.show(
                            context,
                            bleService: widget.bleService,
                            storageService: widget.storageService,
                          );
                        } else if (val == 'about') {
                          AboutBaristaDialog.show(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  // Dedicated Machine Status HUD Strip
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceCard,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.borderSubtle, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: indicatorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: indicatorColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Step 2 Button for Multi-Step Recipes (at end of step 1 / paused, or preview during step 1)
                        if (activeRecipe != null &&
                            activeRecipe.isMultiStep &&
                            (telemetry.machineState.isPaused ||
                                (telemetry.machineState.isExecuting && _currentStepNumber == 1))) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              Step2InstructionDialog.show(
                                context,
                                recipe: activeRecipe,
                                bleService: widget.bleService,
                                onCustomize: _onCustomizeRecipe,
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: telemetry.machineState.isPaused ? 9 : 8,
                                vertical: telemetry.machineState.isPaused ? 3.5 : 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: telemetry.machineState.isPaused
                                    ? const LinearGradient(
                                        colors: [AppTheme.goldPrimary, AppTheme.amberHeat],
                                      )
                                    : null,
                                color: telemetry.machineState.isPaused
                                    ? null
                                    : AppTheme.goldPrimary.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: telemetry.machineState.isPaused
                                      ? AppTheme.goldLight
                                      : AppTheme.goldPrimary.withOpacity(0.5),
                                  width: telemetry.machineState.isPaused ? 1.2 : 0.8,
                                ),
                                boxShadow: telemetry.machineState.isPaused
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.amberHeat.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    telemetry.machineState.isPaused ? Icons.bolt : Icons.next_plan_outlined,
                                    size: 13,
                                    color: telemetry.machineState.isPaused ? Colors.black : AppTheme.goldLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    telemetry.machineState.isPaused ? "What's Step 2?" : 'Step 2 Prep',
                                    style: TextStyle(
                                      color: telemetry.machineState.isPaused ? Colors.black : AppTheme.goldLight,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if ((telemetry.machineState.isExecuting || telemetry.machineState.isPaused) &&
                            activeRecipe != null) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              RecipeDetailDialog.show(
                                context,
                                recipe: activeRecipe,
                                bleService: widget.bleService,
                                onCustomize: _onCustomizeRecipe,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: indicatorColor.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: indicatorColor.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.menu_book_outlined, size: 12, color: indicatorColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Guide',
                                    style: TextStyle(
                                      color: indicatorColor,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (telemetry.machineState.isExecuting && brewProgress != null)
                    LinearProgressIndicator(
                      value: brewProgress,
                      minHeight: 2.5,
                      backgroundColor: AppTheme.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.cyanCold),
                    ),

                  // Main View Area
                  Expanded(
                    child: Row(
                      children: [
                        // Wide Layout: NavigationRail
                        if (isWide)
                          NavigationRail(
                            selectedIndex: _currentIndex,
                            onDestinationSelected: (index) {
                              setState(() => _currentIndex = index);
                            },
                            labelType: NavigationRailLabelType.all,
                            destinations: const [
                              NavigationRailDestination(
                                icon: Icon(Icons.local_cafe_outlined),
                                selectedIcon: Icon(Icons.local_cafe),
                                label: Text('Recipes'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.tune_outlined),
                                selectedIcon: Icon(Icons.tune),
                                label: Text('Custom'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.memory_outlined),
                                selectedIcon: Icon(Icons.memory),
                                label: Text('Slots (13)'),
                              ),
                            ],
                          ),

                        // Content Area
                        Expanded(
                          child: IndexedStack(
                            index: _currentIndex,
                            children: tabs,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Compact Layout: NavigationBar
              bottomNavigationBar: isWide
                  ? null
                  : NavigationBar(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (index) {
                        setState(() => _currentIndex = index);
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.local_cafe_outlined),
                          selectedIcon: Icon(Icons.local_cafe),
                          label: 'Recipes',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.tune_outlined),
                          selectedIcon: Icon(Icons.tune),
                          label: 'Custom Recipe',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.memory_outlined),
                          selectedIcon: Icon(Icons.memory),
                          label: 'Slots',
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
