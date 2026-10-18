import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/barista_ble_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'tabs/custom_recipe_tab.dart';
import 'tabs/presets_tab.dart';
import 'tabs/slots_tab.dart';
import 'widgets/about_dialog.dart';
import 'widgets/developer_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.bleService.autoConnect();
    });
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
                    child: Builder(
                          builder: (context) {
                            final isPaused = telemetry.machineState.isPaused;
                            final isExecuting = telemetry.machineState.isExecuting;
                            final isReady = telemetry.machineState.isReady;
                            final isStandby = telemetry.machineState.isStandby;

                            Color indicatorColor;
                            if (!isConnected) {
                              indicatorColor = isScanning ? AppTheme.amberHeat : AppTheme.textMuted;
                            } else if (isPaused) {
                              indicatorColor = AppTheme.goldLight;
                            } else if (isExecuting) {
                              indicatorColor = AppTheme.cyanCold;
                            } else if (isReady) {
                              indicatorColor = AppTheme.emeraldSuccess;
                            } else if (isStandby) {
                              indicatorColor = AppTheme.crema.withOpacity(0.65);
                            } else {
                              indicatorColor = AppTheme.amberHeat;
                            }

                            final slot = telemetry.selectedSlot;
                            final slotStatus = (slot != null && slot >= 0 && slot < 13)
                                ? ' • Slot ${slot + 1}'
                                : '';

                            String statusText;
                            if (!isConnected) {
                              statusText = isScanning
                                  ? 'SEARCHING FOR BARISTA W545...'
                                  : 'DISCONNECTED • TAP CONNECT TO PAIR';
                            } else {
                              if (isPaused) {
                                statusText = 'Barista connected • ⏸️ Paused (Press Machine Dial)';
                              } else if (isExecuting) {
                                statusText = 'Barista connected • 🔄 Executing$slotStatus';
                              } else {
                                statusText = 'Barista connected • ${telemetry.machineState.label}$slotStatus';
                              }
                            }

                            return Row(
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
                              ],
                            );
                          },
                        ),
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
