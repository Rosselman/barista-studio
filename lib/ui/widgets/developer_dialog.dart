import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/machine_telemetry.dart';
import '../../protocol/barista_ble_constants.dart';
import '../../services/barista_ble_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import 'app_toast.dart';

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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight: min(760, MediaQuery.of(ctx).size.height * 0.88),
          ),
          child: Material(
            color: Colors.transparent,
            child: DeveloperDialog(
              bleService: bleService,
              storageService: storageService,
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curve = Curves.easeOutCubic.transform(anim.value);
        return Transform.scale(
          scale: 0.94 + (0.06 * curve),
          child: Opacity(
            opacity: anim.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<DeveloperDialog> createState() => _DeveloperDialogState();
}

class _DeveloperDialogState extends State<DeveloperDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
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
                // Tab 1: State & Diagnostics (Listens to BLE service)
                ListenableBuilder(
                  listenable: widget.bleService,
                  builder: (context, _) => _buildTelemetryTab(widget.bleService.telemetry),
                ),
                // Tab 2: Live Protocol Logs (Isolated so logs don't trigger full modal rebuilds)
                _LiveLogsView(bleService: widget.bleService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryTab(MachineTelemetry t) {
    final cmid = widget.storageService.getCmidKey();
    final lastMac = widget.storageService.getLastConnectedMac();

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
                _buildInfoRow(
                  'Connection Status',
                  t.isConnected ? 'CONNECTED' : (t.isScanning ? 'SCANNING' : 'DISCONNECTED'),
                  color: t.isConnected
                      ? AppTheme.emeraldSuccess
                      : (t.isScanning ? AppTheme.amberHeat : AppTheme.rubyEmergency),
                ),
                _buildInfoRow('Device Name', t.deviceName ?? 'Unknown'),
                _buildInfoRow(
                  'MAC Address',
                  t.macAddress ?? (lastMac != null ? '$lastMac (Paired)' : 'Disconnected'),
                ),
                _buildInfoRow('Serial Number', t.serialNumber ?? 'Not Read'),
                _buildInfoRow(
                  'Active Dial Slot',
                  t.selectedSlot != null && t.selectedSlot! >= 0
                      ? 'Slot ${t.selectedSlot! + 1}'
                      : 'Unknown',
                ),
                _buildInfoRow(
                  'Machine State',
                  '${t.machineState.label} (${t.machineState.code})',
                  color: t.machineState.isPaused
                      ? AppTheme.goldLight
                      : (t.machineState.isExecuting
                          ? AppTheme.amberHeat
                          : (t.isConnected ? AppTheme.emeraldSuccess : AppTheme.textMuted)),
                ),
                _buildInfoRow('Pairing State', t.pairingState),
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
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Reset CMID to Factory', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.textMuted),
                      onPressed: () async {
                        await widget.storageService.setCmidKey(BaristaBleConstants.defaultPairedCmid);
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Manual BLE Diagnostics
          _buildSectionHeader('Manual BLE Control'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.bluetooth_searching, size: 16),
                label: const Text('Scan Devices'),
                onPressed: () => widget.bleService.startScan(),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Query Active Slot'),
                onPressed: t.isConnected ? () => widget.bleService.queryActiveSlot() : null,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.download, size: 16),
                label: Text(widget.bleService.isScanningSlots ? 'Scanning...' : 'Scan 13 Slots'),
                onPressed: (t.isConnected && !widget.bleService.isScanningSlots) ? () => widget.bleService.fetchAllSlots() : null,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.link_off, size: 16, color: AppTheme.rubyEmergency),
                label: const Text('Disconnect', style: TextStyle(color: AppTheme.rubyEmergency)),
                onPressed: t.isConnected ? () => widget.bleService.disconnect() : null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Developer Settings & Studio Toggles
          _buildSectionHeader('Developer Settings & Toggles'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceInput,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: AppTheme.goldPrimary,
              title: const Text(
                'Live Binary Packet Inspector',
                style: TextStyle(
                  color: AppTheme.crema,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Show raw CRC-16 & 16-byte hex packet inspector in Custom Recipe builder',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
              value: widget.storageService.isPacketInspectorEnabled(),
              onChanged: (val) async {
                await widget.storageService.setPacketInspectorEnabled(val);
                if (mounted) setState(() {});
              },
            ),
          ),
        ],
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: color ?? AppTheme.crema,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveLogsView extends StatefulWidget {
  final BaristaBleService bleService;

  const _LiveLogsView({required this.bleService});

  @override
  State<_LiveLogsView> createState() => _LiveLogsViewState();
}

class _LiveLogsViewState extends State<_LiveLogsView> {
  final List<String> _logs = [];
  StreamSubscription<String>? _logSub;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _logSub = widget.bleService.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.add(log);
          // Pre-cap visible log buffer to last 150 lines for smooth performance
          if (_logs.length > 150) {
            _logs.removeRange(0, _logs.length - 150);
          }
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
    _logSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Log Actions Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_logs.length} Log Entries (Capped at 150)',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16, color: AppTheme.goldLight),
                    tooltip: 'Copy Logs',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _logs.join('\n')));
                      AppToast.success(context, 'Diagnostic logs copied to clipboard');
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

        // Log Console with RepaintBoundary
        Expanded(
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.all(10),
            child: RepaintBoundary(
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
        ),
      ],
    );
  }
}
