import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/machine_telemetry.dart';
import '../../protocol/barista_ble_constants.dart';
import '../../services/barista_ble_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class DeveloperDialog extends StatefulWidget {
  final BaristaBleService bleService;
  final StorageService storageService;

  const DeveloperDialog({
    super.key,
    required this.bleService,
    required this.storageService,
  });

  static void show(
    BuildContext context, {
    required BaristaBleService bleService,
    required StorageService storageService,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeveloperDialog(
        bleService: bleService,
        storageService: storageService,
      ),
    );
  }

  @override
  State<DeveloperDialog> createState() => _DeveloperDialogState();
}

class _DeveloperDialogState extends State<DeveloperDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _logs = [];
  StreamSubscription<String>? _logSub;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _logSub = widget.bleService.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.add(log);
          if (_logs.length > 500) _logs.removeAt(0);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.bleService,
      builder: (context, _) {
        final t = widget.bleService.telemetry;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppTheme.borderSubtle, width: 1.5),
            ),
          ),
          child: Column(
            children: [
              // Sheet Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.terminal, color: AppTheme.goldPrimary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'DEVELOPER & DIAGNOSTICS',
                        style: TextStyle(
                          color: AppTheme.crema,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.goldPrimary,
                labelColor: AppTheme.goldPrimary,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'BLE Telemetry & State'),
                  Tab(text: 'Live Protocol Logs'),
                ],
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: State & Diagnostics
                    _buildTelemetryTab(t),
                    // Tab 2: Live Protocol Logs
                    _buildLogsTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTelemetryTab(MachineTelemetry t) {
    final cmid = widget.storageService.getCmidKey();
    final lastMac = widget.storageService.getLastConnectedMac() ?? 'None (Auto-Discovery)';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection & Hardware Info
          _buildSectionHeader('GATT Hardware Connection'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceInput,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              children: [
                _buildInfoRow('Connection Status', t.isConnected ? 'CONNECTED' : (t.isScanning ? 'SCANNING' : 'DISCONNECTED'),
                    color: t.isConnected ? AppTheme.emeraldSuccess : (t.isScanning ? AppTheme.amberHeat : AppTheme.rubyEmergency)),
                _buildInfoRow('Device Name', t.deviceName ?? 'Unknown'),
                _buildInfoRow('MAC Address', t.macAddress ?? lastMac),
                _buildInfoRow('Serial Number', t.serialNumber ?? 'Not Read'),
                _buildInfoRow('Machine State', t.machineState),
                _buildInfoRow('Pairing State', t.pairingState),
                _buildInfoRow('Active Dial Slot', t.selectedSlot != null ? 'Slot ${t.selectedSlot! + 1}' : 'Unknown'),
                _buildInfoRow('Motor Telemetry', t.motorRunning ? 'RUNNING' : 'STOPPED',
                    color: t.motorRunning ? AppTheme.goldPrimary : AppTheme.textMuted),
                _buildInfoRow('Induction Telemetry', t.inductionHeatingActive ? 'ACTIVE HEATING' : 'OFF',
                    color: t.inductionHeatingActive ? AppTheme.rubyEmergency : AppTheme.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // CMID Authentication Info
          _buildSectionHeader('CMID Authentication'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceInput,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              children: [
                _buildInfoRow('Stored CMID Key', cmid),
                _buildInfoRow('Default CMID', BaristaBleConstants.defaultPairedCmid),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: const BorderSide(color: AppTheme.borderSubtle),
                      ),
                      icon: const Icon(Icons.refresh, size: 14, color: AppTheme.crema),
                      label: const Text('Reset CMID to Default', style: TextStyle(color: AppTheme.crema, fontSize: 11)),
                      onPressed: () async {
                        await widget.storageService.setCmidKey(BaristaBleConstants.defaultPairedCmid);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Diagnostic Actions
          _buildSectionHeader('Diagnostic Commands'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Query All 13 Slots', style: TextStyle(fontSize: 12)),
                onPressed: () => widget.bleService.fetchAllSlots(),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.goldPrimary),
                ),
                icon: const Icon(Icons.bluetooth_searching, size: 16, color: AppTheme.goldPrimary),
                label: const Text('Trigger BLE Auto-Connect', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 12)),
                onPressed: () => widget.bleService.autoConnect(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTab() {
    return Column(
      children: [
        // Log Actions Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_logs.length} Log Entries',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16, color: AppTheme.goldLight),
                    tooltip: 'Copy Logs',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _logs.join(String.fromCharCode(10))));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logs copied to clipboard'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear_all, size: 18, color: AppTheme.rubyEmergency),
                    tooltip: 'Clear Logs',
                    onPressed: () => setState(() => _logs.clear()),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: AppTheme.borderSubtle, height: 1),

        // Log Console
        Expanded(
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.all(10),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                Color color = AppTheme.crema;
                if (log.contains('error') || log.contains('failed') || log.contains('Timeout')) {
                  color = AppTheme.rubyEmergency;
                } else if (log.contains('successfully') || log.contains('authenticated') || log.contains('Connected')) {
                  color = AppTheme.emeraldSuccess;
                } else if (log.contains('Slot') || log.contains('Flashing')) {
                  color = AppTheme.goldLight;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Text(
                    log,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.goldPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? AppTheme.crema,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
