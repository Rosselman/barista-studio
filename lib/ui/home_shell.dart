import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/barista_ble_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'tabs/custom_recipe_tab.dart';
import 'tabs/presets_tab.dart';
import 'tabs/slots_tab.dart';

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

  void _onCustomizeRecipe(Recipe recipe) {
    setState(() {
      _currentIndex = 1; // switch to Tab 2
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _customRecipeKey.currentState?.setRecipe(recipe);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.bleService,
      builder: (context, _) {
        final telemetry = widget.bleService.telemetry;
        final isConnected = telemetry.isConnected;
        final isScanning = telemetry.isScanning;
        final isMotorRunning = telemetry.motorRunning;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;

            final tabs = [
              PresetsTab(
                bleService: widget.bleService,
                onCustomize: _onCustomizeRecipe,
              ),
              CustomRecipeTab(
                key: _customRecipeKey,
                bleService: widget.bleService,
                storageService: widget.storageService,
              ),
              SlotsTab(
                bleService: widget.bleService,
              ),
            ];

            return Scaffold(
              backgroundColor: AppTheme.bgDark,
              appBar: AppBar(
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.coffee, color: AppTheme.goldPrimary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BARISTA STUDIO',
                          style: TextStyle(
                            color: AppTheme.crema,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'W545 Recipe Engine',
                          style: TextStyle(
                            color: AppTheme.goldLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  // Status Badge
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? AppTheme.emeraldSuccess.withOpacity(0.12)
                          : (isScanning
                              ? AppTheme.amberHeat.withOpacity(0.12)
                              : AppTheme.surfaceElevated),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isConnected
                            ? AppTheme.emeraldSuccess
                            : (isScanning ? AppTheme.amberHeat : AppTheme.borderSubtle),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isConnected
                                ? AppTheme.emeraldSuccess
                                : (isScanning ? AppTheme.amberHeat : AppTheme.textMuted),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isConnected
                              ? telemetry.machineState
                              : (isScanning ? 'SCANNING...' : 'DISCONNECTED'),
                          style: TextStyle(
                            color: isConnected
                                ? AppTheme.emeraldSuccess
                                : (isScanning ? AppTheme.amberHeat : AppTheme.textMuted),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Connect / Disconnect Action
                  if (!isConnected)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          : const Icon(Icons.bluetooth, size: 16),
                      label: Text(
                        isScanning ? 'Scanning' : 'Connect',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: isScanning
                          ? () => widget.bleService.stopScan()
                          : () => widget.bleService.startScan(),
                    )
                  else
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: const BorderSide(color: AppTheme.borderSubtle),
                      ),
                      child: const Text('Disconnect', style: TextStyle(fontSize: 11)),
                      onPressed: () => widget.bleService.disconnect(),
                    ),
                  const SizedBox(width: 8),

                  // Emergency STOP Button
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMotorRunning
                            ? AppTheme.rubyEmergency
                            : const Color(0xFF8B1E1E),
                        foregroundColor: Colors.white,
                        elevation: isMotorRunning ? 4 : 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        side: isMotorRunning
                            ? const BorderSide(color: Colors.white, width: 1.5)
                            : BorderSide.none,
                      ),
                      icon: const Icon(Icons.stop_circle, size: 18),
                      label: const Text(
                        'STOP',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      onPressed: () => widget.bleService.emergencyStop(),
                    ),
                  ),
                ],
              ),
              body: Row(
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
                          label: Text('Presets'),
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
                          label: 'Presets',
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
