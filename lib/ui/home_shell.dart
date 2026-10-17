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
                  const SizedBox(width: 6),

                  // Emergency STOP Button
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMotorRunning
                            ? AppTheme.rubyEmergency
                            : const Color(0xFF8B1E1E),
                        foregroundColor: Colors.white,
                        elevation: isMotorRunning ? 4 : 0,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: const Size(54, 32),
                        side: isMotorRunning
                            ? const BorderSide(color: Colors.white, width: 1.5)
                            : BorderSide.none,
                      ),
                      icon: const Icon(Icons.stop_circle, size: 15),
                      label: const Text(
                        'STOP',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                      onPressed: () => widget.bleService.emergencyStop(),
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
                            color: isConnected
                                ? AppTheme.emeraldSuccess
                                : (isScanning ? AppTheme.amberHeat : AppTheme.textMuted),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isConnected
                                ? '${(telemetry.deviceName != null && telemetry.deviceName!.isNotEmpty) ? telemetry.deviceName : "Barista"} • ${telemetry.machineState}'
                                : (isScanning ? 'SEARCHING FOR BARISTA W545...' : 'DISCONNECTED • TAP CONNECT TO PAIR'),
                            style: TextStyle(
                              color: isConnected
                                  ? AppTheme.emeraldSuccess
                                  : (isScanning ? AppTheme.amberHeat : AppTheme.textMuted),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isConnected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isMotorRunning
                                  ? AppTheme.emeraldSuccess.withOpacity(0.18)
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isMotorRunning ? AppTheme.emeraldSuccess : AppTheme.borderSubtle,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              isMotorRunning ? 'MOTOR ON' : 'MOTOR OFF',
                              style: TextStyle(
                                color: isMotorRunning ? AppTheme.emeraldSuccess : AppTheme.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: telemetry.inductionHeatingActive
                                  ? AppTheme.amberHeat.withOpacity(0.18)
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: telemetry.inductionHeatingActive ? AppTheme.amberHeat : AppTheme.borderSubtle,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              telemetry.inductionHeatingActive ? 'HEAT ON' : 'HEAT OFF',
                              style: TextStyle(
                                color: telemetry.inductionHeatingActive ? AppTheme.amberHeat : AppTheme.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
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
