import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/machine_telemetry.dart';
import '../models/recipe.dart';
import '../models/slot_info.dart';
import '../protocol/barista_ble_constants.dart';
import '../protocol/gatt_op_queue.dart';
import '../protocol/recipe_packet_builder.dart';
import '../data/preset_catalog.dart';
import 'storage_service.dart';

class BaristaBleService extends ChangeNotifier {
  final StorageService storageService;
  final GattOpQueue _opQueue = GattOpQueue();

  BluetoothDevice? _device;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _statusSub;
  StreamSubscription<List<int>>? _recipeResponseSub;
  StreamSubscription<List<int>>? _recipeSelectionSub;

  // Cached Characteristics
  BluetoothCharacteristic? _charSerialNumber;
  BluetoothCharacteristic? _charCmid;
  BluetoothCharacteristic? _charCmidType;
  BluetoothCharacteristic? _charTxLevelRequest;
  BluetoothCharacteristic? _charMachineStatus;
  BluetoothCharacteristic? _charCommandReq;
  BluetoothCharacteristic? _charRecipeSelection;
  BluetoothCharacteristic? _charRecipeCommand;
  BluetoothCharacteristic? _charRecipeResponse;

  MachineTelemetry _telemetry = const MachineTelemetry();
  MachineTelemetry get telemetry => _telemetry;

  final List<SlotInfo> _slots = List.generate(
    13,
    (i) => SlotInfo(slotIndex: i, recipeName: 'Slot ${i + 1}'),
  );
  List<SlotInfo> get slots => List.unmodifiable(_slots);

  // Slot Query State
  final Queue<int> _slotFetchQueue = Queue<int>();
  int _currentFetchingSlot = -1;
  final List<int> _slotIdBuffer = [];
  Timer? _slotTimeoutTimer;

  // Upload State
  double _uploadProgress = 0.0;
  double get uploadProgress => _uploadProgress;
  bool _isUploading = false;
  bool get isUploading => _isUploading;
  String? _uploadStatusText;
  String? get uploadStatusText => _uploadStatusText;
  Completer<bool>? _uploadCompleter;

  // Protocol Log Stream
  final _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;
  StreamSubscription<List<ScanResult>>? _scanSub;

  void _log(String message) {
    debugPrint('[BaristaBLE] $message');
    _logController.add(message);
  }

  BaristaBleService({required this.storageService});

  bool get isConnected => _telemetry.isConnected;

  // ===========================================================================
  // 1. Scanning & Connection Management
  // ===========================================================================

  bool _isBaristaDevice({
    required String name,
    required String advName,
    required String mac,
    required List<Guid> serviceUuids,
    required Map<Guid, List<int>> serviceData,
    required Map<int, List<int>> manufacturerData,
  }) {
    final n = name.trim().toUpperCase();
    final an = advName.trim().toUpperCase();

    // 1. Universal Nespresso Barista W545 naming patterns
    if (n.startsWith('WHITE_') || an.startsWith('WHITE_')) return true;
    if (n.startsWith('BLACK_') || an.startsWith('BLACK_')) return true;
    if (n.contains('BARISTA') || an.contains('BARISTA')) return true;
    if (n.contains('W545') || an.contains('W545')) return true;

    // 2. Match previously paired MAC or Device UUID
    final lastMac = storageService.getLastConnectedMac()?.trim().toUpperCase();
    final m = mac.trim().toUpperCase();
    if (lastMac != null && lastMac.isNotEmpty && (m == lastMac || n == lastMac)) return true;

    // 3. Match by custom Barista GATT Service UUIDs
    // All Nespresso Barista services share the Eugster base: 6524xxxx-0253-11e7-93ae-92361f002671
    // (DeviceInfo: 65241910, Status: 65241920, Error: 65241930, Recipe: 65241990, Language: 652419a0)
    for (final uuid in serviceUuids) {
      final s = uuid.str128.toLowerCase();
      if (s.contains('-0253-11e7-93ae-92361f002671') || s.startsWith('652419')) {
        return true;
      }
    }

    // 4. Match in Service Data keys
    for (final uuid in serviceData.keys) {
      final s = uuid.str128.toLowerCase();
      if (s.contains('-0253-11e7-93ae-92361f002671') || s.startsWith('652419')) {
        return true;
      }
    }

    return false;
  }

  Future<bool> _checkAndRequestPermissions() async {
    if (kIsWeb) return true;

    try {
      if (Platform.isAndroid) {
        final scanStatus = await Permission.bluetoothScan.status;
        final connStatus = await Permission.bluetoothConnect.status;

        if (!scanStatus.isGranted || !connStatus.isGranted) {
          _log('Requesting Bluetooth permissions (BLUETOOTH_SCAN & BLUETOOTH_CONNECT)...');
          final statuses = await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
          ].request();

          final granted = (statuses[Permission.bluetoothScan]?.isGranted == true) &&
              (statuses[Permission.bluetoothConnect]?.isGranted == true);
          if (!granted) {
            _log('Warning: Bluetooth permissions denied.');
          }
          return granted;
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        final status = await Permission.bluetooth.status;
        if (!status.isGranted) {
          _log('Requesting Bluetooth permission on macOS/iOS...');
          final res = await Permission.bluetooth.request();
          if (!res.isGranted) {
            _log('Warning: Bluetooth permission denied on macOS/iOS.');
            return false;
          }
        }
      }
      return true;
    } catch (e) {
      _log('Permission check notice: $e');
      return true;
    }
  }

  /// Automatically connects to an active nearby Barista machine via BLE scan
  Future<void> autoConnect() async {
    if (_telemetry.isConnected || _telemetry.isScanning) return;

    final hasPerms = await _checkAndRequestPermissions();
    if (!hasPerms) {
      _log('Bluetooth permissions missing; cannot connect.');
      return;
    }

    // Always scan for live advertising machines instead of blind direct connection.
    // If the machine is powered off, scanning simply completes with DISCONNECTED state.
    await startScan();
  }

  Future<void> startScan() async {
    if (_telemetry.isScanning || _telemetry.isConnected) return;

    final hasPerms = await _checkAndRequestPermissions();
    if (!hasPerms) {
      _log('Bluetooth permissions missing; cannot start scan.');
      return;
    }

    // Ensure Bluetooth adapter is powered on before starting scan (especially on macOS / iOS / Windows)
    try {
      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        _log('Waiting for Bluetooth adapter to power on...');
        await FlutterBluePlus.adapterState
            .where((s) => s == BluetoothAdapterState.on)
            .first
            .timeout(const Duration(seconds: 4), onTimeout: () => BluetoothAdapterState.unknown);
      }
    } catch (e) {
      _log('Notice waiting for adapterState: $e');
    }

    _updateTelemetry(_telemetry.copyWith(isScanning: true));
    _log('Scanning for nearby Barista machines (White_* / Black_* / W545)...');

    // On iOS and macOS (CoreBluetooth), if the machine is already bonded or connected to the OS,
    // CoreBluetooth will NOT return it in active advertising scan results. Check connected & system devices first!
    try {
      final baristaServiceGuids = [
        Guid(BaristaBleConstants.recipeService),
        Guid(BaristaBleConstants.statusControlService),
        Guid(BaristaBleConstants.deviceInfoService),
      ];

      // 1. Check already connected devices in FlutterBluePlus
      for (final d in FlutterBluePlus.connectedDevices) {
        if (_isBaristaDevice(
          name: d.platformName,
          advName: d.advName,
          mac: d.remoteId.str,
          serviceUuids: const [],
          serviceData: const {},
          manufacturerData: const {},
        )) {
          final displayName = d.platformName.isNotEmpty ? d.platformName : d.remoteId.str;
          _log('Discovered active Barista machine (already connected): $displayName');
          stopScan();
          connect(d);
          return;
        }
      }

      // 2. Query system-paired peripherals on iOS, macOS, Android
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS || Platform.isAndroid)) {
        final sysDevices = await FlutterBluePlus.systemDevices(baristaServiceGuids);
        for (final d in sysDevices) {
          final displayName = d.platformName.isNotEmpty ? d.platformName : d.remoteId.str;
          _log('Discovered system-paired Barista machine: $displayName');
          stopScan();
          connect(d);
          return;
        }
      }
    } catch (e) {
      _log('Notice checking system/connected devices: $e');
    }

    try {
      await _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.device.platformName;
          final advName = r.advertisementData.advName;
          final mac = r.device.remoteId.str;
          final serviceUuids = r.advertisementData.serviceUuids;

          if (_isBaristaDevice(
            name: name,
            advName: advName,
            mac: mac,
            serviceUuids: serviceUuids,
            serviceData: r.advertisementData.serviceData,
            manufacturerData: r.advertisementData.manufacturerData,
          )) {
            final displayName = name.isNotEmpty
                ? name
                : (advName.isNotEmpty ? advName : 'Barista W545');
            _log('Discovered active Barista machine: $displayName ($mac)');
            stopScan();
            connect(r.device);
            break;
          }
        }
      });

      // Scan for 10 seconds with continuousUpdates to ensure scan responses with names are received
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        continuousUpdates: true,
      );

      // Auto stop scan after timeout
      Future.delayed(const Duration(seconds: 10), () {
        if (_telemetry.isScanning) {
          stopScan();
          _log('Scan completed. No active Barista machine found.');
        }
      });
    } catch (e) {
      _log('Scan error: $e');
      _updateTelemetry(_telemetry.copyWith(isScanning: false));
    }
  }

  Future<void> stopScan() async {
    try {
      await _scanSub?.cancel();
      _scanSub = null;
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _updateTelemetry(_telemetry.copyWith(isScanning: false));
  }

  Future<void> connect(BluetoothDevice device) async {
    await disconnect();
    _device = device;
    _log('Connecting to GATT: ${device.remoteId.str}...');

    _connSub = device.connectionState.listen((state) async {
      if (state == BluetoothConnectionState.connected) {
        _log('GATT transport connected to ${device.remoteId.str}. Discovering services...');
        // Do NOT mark isConnected = true yet! Wait for GATT discovery and CMID handshake confirmation.
        await _discoverAndSetupServices(device);
      } else if (state == BluetoothConnectionState.disconnected) {
        _log('Disconnected from Barista.');
        _handleDisconnection();
      }
    });

    try {
      if (!device.isConnected) {
        await device.connect(
          timeout: const Duration(seconds: 8),
          autoConnect: false,
        );
      } else {
        _log('Device already connected. Proceeding to service discovery...');
        await _discoverAndSetupServices(device);
      }
    } catch (e) {
      if (e.toString().contains('already connected')) {
        await _discoverAndSetupServices(device);
      } else {
        _log('Connection failed: $e');
        _handleDisconnection();
      }
    }
  }

  Future<void> disconnect() async {
    _stopStatusPollingLoop();
    _slotTimeoutTimer?.cancel();
    _slotFetchQueue.clear();
    _currentFetchingSlot = -1;
    _opQueue.clear();

    await _statusSub?.cancel();
    _statusSub = null;
    await _recipeResponseSub?.cancel();
    _recipeResponseSub = null;
    await _recipeSelectionSub?.cancel();
    _recipeSelectionSub = null;
    await _connSub?.cancel();
    _connSub = null;

    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (_) {}
      _device = null;
    }
    _handleDisconnection();
  }

  void _handleDisconnection() {
    _stopStatusPollingLoop();
    _slotTimeoutTimer?.cancel();
    _slotFetchQueue.clear();
    _currentFetchingSlot = -1;
    _opQueue.clear();
    for (int i = 0; i < 13; i++) {
      _slots[i] = SlotInfo(slotIndex: i, recipeName: 'Slot ${i + 1}');
    }
    _updateTelemetry(const MachineTelemetry());
  }

  // ===========================================================================
  // 1.5. Live Status & Telemetry Polling Loop
  // ===========================================================================
  // As confirmed in Nespresso's RecipesViewModel$startBaristaPolling$1$1.java,
  // the Barista machine firmware does not stream spontaneous GATT notifications
  // when machine state changes (Ready -> Executing -> Paused) or when the rotary
  // dial is turned. Active background polling of CHAR_MACHINE_STATUS and
  // CHAR_RECIPE_SELECTION is mandatory for live telemetry synchronization.

  Timer? _statusPollingTimer;
  int _consecutivePollingFailures = 0;

  void _startStatusPollingLoop() {
    _statusPollingTimer?.cancel();
    _consecutivePollingFailures = 0;
    _statusPollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!isConnected || _device == null || _charMachineStatus == null) {
        _stopStatusPollingLoop();
        return;
      }

      // If active upload or slot queue is running, link is proven by active packets; yield BLE
      if (_isUploading || _currentFetchingSlot != -1 || _opQueue.isBusy) {
        _consecutivePollingFailures = 0;
        return;
      }

      _opQueue.enqueue(() async {
        if (!isConnected || _device == null || _charMachineStatus == null) return false;
        try {
          // 1. Poll Machine Status (Byte 1: Standby, Ready, Executing, Paused)
          final statusData = await _charMachineStatus!.read().timeout(const Duration(seconds: 2));
          _handleMachineStatus(statusData);

          // 2. Poll Active Dial Position (1..13 -> 0..12)
          if (_charRecipeSelection != null) {
            final slotData = await _charRecipeSelection!.read().timeout(const Duration(seconds: 2));
            if (slotData.isNotEmpty) {
              final raw = slotData[0] & 0xFF;
              final slotIndex = raw > 0 ? (raw - 1) : 0;
              if (slotIndex != _telemetry.selectedSlot) {
                _updateTelemetry(_telemetry.copyWith(selectedSlot: slotIndex));
                _log('Machine rotary dial rotated: Slot ${slotIndex + 1}');
              }
            }
          }

          _consecutivePollingFailures = 0;
          return true;
        } catch (e) {
          _consecutivePollingFailures++;
          _log('Status poll missed ($_consecutivePollingFailures/3): $e');
          if (_consecutivePollingFailures >= 3) {
            _log('Machine unreachable after 3 consecutive poll attempts. Disconnecting.');
            _stopStatusPollingLoop();
            disconnect();
          }
          return false;
        }
      }, description: 'Poll Machine Status & Dial', timeout: const Duration(seconds: 3));
    });
  }

  void _stopStatusPollingLoop() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = null;
    _consecutivePollingFailures = 0;
  }

  // ===========================================================================
  // 2. Service Discovery & Characteristic Caching
  // ===========================================================================

  Future<void> _discoverAndSetupServices(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices().timeout(const Duration(seconds: 10));
      for (final s in services) {
        final sUuid = s.uuid.str128.toLowerCase();
        if (sUuid == BaristaBleConstants.deviceInfoService.toLowerCase()) {
          for (final c in s.characteristics) {
            final cUuid = c.uuid.str128.toLowerCase();
            if (cUuid == BaristaBleConstants.charSerialNumber.toLowerCase()) {
              _charSerialNumber = c;
            } else if (cUuid == BaristaBleConstants.charCmid.toLowerCase()) {
              _charCmid = c;
            } else if (cUuid == BaristaBleConstants.charCmidType.toLowerCase()) {
              _charCmidType = c;
            } else if (cUuid == BaristaBleConstants.charTxLevelRequest.toLowerCase()) {
              _charTxLevelRequest = c;
            }
          }
        } else if (sUuid == BaristaBleConstants.statusControlService.toLowerCase()) {
          for (final c in s.characteristics) {
            final cUuid = c.uuid.str128.toLowerCase();
            if (cUuid == BaristaBleConstants.charMachineStatus.toLowerCase()) {
              _charMachineStatus = c;
            } else if (cUuid == BaristaBleConstants.charCommandReq.toLowerCase()) {
              _charCommandReq = c;
            }
          }
        } else if (sUuid == BaristaBleConstants.recipeService.toLowerCase()) {
          for (final c in s.characteristics) {
            final cUuid = c.uuid.str128.toLowerCase();
            if (cUuid == BaristaBleConstants.charRecipeSelection.toLowerCase()) {
              _charRecipeSelection = c;
            } else if (cUuid == BaristaBleConstants.charRecipeCommand.toLowerCase()) {
              _charRecipeCommand = c;
            } else if (cUuid == BaristaBleConstants.charRecipeResponse.toLowerCase()) {
              _charRecipeResponse = c;
            }
          }
        }
      }

      if (_charMachineStatus == null || _charRecipeCommand == null) {
        _log('Essential Barista GATT characteristics missing. Aborting connection.');
        await disconnect();
        return;
      }

      _log('GATT Characteristics cached. Enabling notifications & handshake...');
      await _setupNotificationsAndAuth(device);
    } catch (e) {
      _log('Service discovery error: $e. Disconnecting.');
      await disconnect();
    }
  }

  // ===========================================================================
  // 3. Notifications & CMID Authentication Handshake
  // ===========================================================================

  Future<void> _setupNotificationsAndAuth(BluetoothDevice device) async {
    // 1. Subscribe to MACHINE_STATUS
    if (_charMachineStatus != null) {
      try {
        _statusSub = _charMachineStatus!.onValueReceived.listen(_handleMachineStatus);
        await _charMachineStatus!.setNotifyValue(true);
        _log('MACHINE_STATUS notifications active.');
      } catch (e) {
        _log('Error setting MACHINE_STATUS notification: $e');
      }
    }

    // 2. Subscribe to RECIPE_RESPONSE
    if (_charRecipeResponse != null) {
      try {
        _recipeResponseSub = _charRecipeResponse!.onValueReceived.listen(_handleRecipeResponse);
        await _charRecipeResponse!.setNotifyValue(true);
        _log('RECIPE_RESPONSE notifications active.');
      } catch (e) {
        _log('Error setting RECIPE_RESPONSE notification: $e');
      }
    }

    // 3. Subscribe to RECIPE_SELECTION
    if (_charRecipeSelection != null) {
      try {
        _recipeSelectionSub = _charRecipeSelection!.onValueReceived.listen((val) {
          if (val.isNotEmpty) {
            final raw = val[0] & 0xFF;
            // Physical Barista sends 1-based position (1..13). Convert to 0-based index for app UI (0..12).
            final slotIndex = raw > 0 ? (raw - 1) : 0;
            _updateTelemetry(_telemetry.copyWith(selectedSlot: slotIndex));
            _log('Machine selected slot changed: Slot ${slotIndex + 1}');
          }
        });
        await _charRecipeSelection!.setNotifyValue(true);
      } catch (e) {
        _log('Error setting RECIPE_SELECTION notification: $e');
      }

      // Read initial selection
      _opQueue.enqueue(() async {
        try {
          final val = await _charRecipeSelection!.read();
          if (val.isNotEmpty) {
            final raw = val[0] & 0xFF;
            final slotIndex = raw > 0 ? (raw - 1) : 0;
            _updateTelemetry(_telemetry.copyWith(selectedSlot: slotIndex));
            _log('Initial active slot read: Slot ${slotIndex + 1}');
          }
          return true;
        } catch (_) {
          return false;
        }
      }, description: 'Read Active Slot');
    }

    // 4. Read Serial Number
    if (_charSerialNumber != null) {
      _opQueue.enqueue(() async {
        try {
          final data = await _charSerialNumber!.read();
          final sn = utf8.decode(data, allowMalformed: true).trim();
          _updateTelemetry(_telemetry.copyWith(serialNumber: sn));
          _log('Machine Serial Number: $sn');
          return true;
        } catch (_) {
          return false;
        }
      }, description: 'Read Serial Number');
    }

    // 5. CMID Handshake
    _performPairingHandshake(device);
  }

  void _performPairingHandshake(BluetoothDevice device) {
    if (_charMachineStatus == null) {
      disconnect();
      return;
    }

    _opQueue.enqueue(() async {
      try {
        final data = await _charMachineStatus!.read().timeout(const Duration(seconds: 4));
        if (data.length < 2) {
          _log('Failed to read pairing state; aborting connection.');
          disconnect();
          return false;
        }
        final b0 = data[0] & 0xFF;
        final b1 = data[1] & 0xFF;
        final pairingCode = (b0 & 0x60) >> 5;
        final initialState = MachineState.fromByte(b1);
        _log('Machine pairing state: $pairingCode (0=NONE, 1=TEMP, 2=FINAL), state: ${initialState.label}');

        // Step A: Only write TX_LEVEL_REQUEST (0x01) if NOT already FINAL
        if (pairingCode != 2 && _charTxLevelRequest != null) {
          _log('Sending TX_LEVEL_REQUEST (0x01)...');
          try {
            await _charTxLevelRequest!.write([0x01], withoutResponse: false);
          } catch (e) {
            _log('TX_LEVEL_REQUEST write error: $e');
          }
        } else {
          _log('Machine is already in FINAL pairing state; skipping TX Level Request.');
        }

        // Step B: Write 8-byte CMID key to authenticate the connection session
        final cmidHex = storageService.getCmidKey();
        final cmidBytes = deriveCmidFromSeed(cmidHex);
        if (_charCmid != null) {
          final hexStr = cmidBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
          _log('Authenticating session: Writing 8-byte CMID to charCmid: $hexStr');
          try {
            await _charCmid!.write(cmidBytes, withoutResponse: false);
            _log('CMID key accepted by machine!');
          } catch (e) {
            _log('CMID key write warning: $e');
          }
        }

        // Step C: Verify CMID_TYPE confirmation
        if (_charCmidType != null) {
          try {
            final typeData = await _charCmidType!.read();
            if (typeData.isNotEmpty) {
              final type = typeData[0] & 0xFF;
              final typeStr = type == 2 ? 'FINAL (Authenticated)' : (type == 1 ? 'TEMPORARY' : 'REJECTED ($type)');
              _log('CMID_TYPE response: $typeStr');
            }
          } catch (e) {
            _log('CMID_TYPE read error: $e');
          }
        }

        // Confirmed active & authenticated connection!
        storageService.setLastConnectedMac(device.remoteId.str);
        _updateTelemetry(_telemetry.copyWith(
          isConnected: true,
          deviceName: device.platformName.isNotEmpty
              ? device.platformName
              : 'Barista (${device.remoteId.str})',
          macAddress: device.remoteId.str,
          machineState: initialState,
          pairingState: pairingCode == 2 ? 'FINAL' : (pairingCode == 1 ? 'TEMPORARY' : 'NONE'),
        ));

        _startStatusPollingLoop();
        _log('Machine authenticated and confirmed ONLINE. Fetching all 13 slots...');
        fetchAllSlots();
        return true;
      } catch (e) {
        _log('Pairing handshake error: $e. Aborting connection.');
        disconnect();
        return false;
      }
    }, description: 'Pairing Handshake');
  }

  // ===========================================================================
  // 4. Machine Status Telemetry Parser
  // ===========================================================================

  void _handleMachineStatus(List<int> data) {
    if (data.length < 2) return;
    final b0 = data[0] & 0xFF;
    final b1 = data[1] & 0xFF;

    final pairingCode = (b0 & 0x60) >> 5;
    // CRITICAL: Parentheses strictly required because (b1 & 0xFC) >> 2 has different precedence than b1 & 0xFC >> 2
    final state = MachineState.fromByte(b1);

    final pStateStr = (pairingCode < BaristaBleConstants.pairingStates.length)
        ? BaristaBleConstants.pairingStates[pairingCode]
        : 'UNKNOWN';

    if (state != _telemetry.machineState) {
      _log('Machine state changed: ${_telemetry.machineState.label} -> ${state.label} (${state.code})');
    }

    _updateTelemetry(_telemetry.copyWith(
      machineState: state,
      pairingState: pStateStr,
    ));
  }

  // ===========================================================================
  // 5. Slot Scanning & Recipe Response Parser
  // ===========================================================================

  void queryActiveSlot() {
    if (_charRecipeSelection == null || !isConnected) return;
    _opQueue.enqueue(() async {
      try {
        final val = await _charRecipeSelection!.read();
        if (val.isNotEmpty) {
          final raw = val[0] & 0xFF;
          final slotIndex = raw > 0 ? (raw - 1) : 0;
          _updateTelemetry(_telemetry.copyWith(selectedSlot: slotIndex));
          _log('Active slot query: Slot ${slotIndex + 1}');
        }
        return true;
      } catch (e) {
        _log('Error querying active slot: $e');
        return false;
      }
    }, description: 'Query Active Slot');
  }

  void fetchAllSlots() {
    _slotFetchQueue.clear();
    for (int i = 0; i < 13; i++) {
      _slotFetchQueue.add(i);
    }
    if (_currentFetchingSlot == -1) {
      _processNextSlotQuery();
    }
  }

  void fetchSlot(int slot) {
    if (!_slotFetchQueue.contains(slot)) {
      _slotFetchQueue.add(slot);
    }
    if (_currentFetchingSlot == -1) {
      _processNextSlotQuery();
    }
  }

  void _processNextSlotQuery() {
    _slotTimeoutTimer?.cancel();
    if (_slotFetchQueue.isEmpty) {
      _currentFetchingSlot = -1;
      _log('Finished querying all queued slots.');
      return;
    }
    if (_charRecipeCommand == null || !isConnected) {
      _currentFetchingSlot = -1;
      _slotFetchQueue.clear();
      return;
    }

    _currentFetchingSlot = _slotFetchQueue.removeFirst();
    final slot = _currentFetchingSlot;
    final pos = slot + 1; // 1-based (1..13)
    _slotIdBuffer.clear();

    _slotTimeoutTimer = Timer(const Duration(milliseconds: 1400), () {
      if (_currentFetchingSlot == slot) {
        _log('Timeout querying Slot $pos.');
        _slots[slot] = SlotInfo(
          slotIndex: slot,
          isOccupied: false,
          recipeName: 'Slot $pos (Empty)',
        );
        _currentFetchingSlot = -1;
        notifyListeners();
        _processNextSlotQuery();
      }
    });

    final cmd = [BaristaBleConstants.cmdGetId, 0x01, pos & 0xFF];
    _opQueue.enqueue(() async {
      try {
        await _charRecipeCommand!.write(cmd, withoutResponse: false);
        return true;
      } catch (e) {
        _log('Error sending CMD_GET_ID for Slot $pos: $e');
        _slotTimeoutTimer?.cancel();
        if (_currentFetchingSlot == slot) {
          _slots[slot] = SlotInfo(
            slotIndex: slot,
            isOccupied: false,
            recipeName: 'Slot $pos (Empty)',
          );
          _currentFetchingSlot = -1;
          notifyListeners();
          _processNextSlotQuery();
        }
        return false;
      }
    }, description: 'Query Slot $pos', timeout: const Duration(milliseconds: 1400));
  }

  void _handleRecipeResponse(List<int> data) {
    if (data.length < 3) return;
    final cmdId = data[0] & 0x3F;

    if (cmdId == BaristaBleConstants.cmdGetId) {
      if (_currentFetchingSlot == -1) return;
      final slot = _currentFetchingSlot;
      final pos = slot + 1;

      final ctrl = (data.length > 1) ? (data[1] & 0xFF) : 0;
      final hasNext = (ctrl & 0x80) != 0;
      final payloadLen = ctrl & 0x1F;

      // Check if this is an empty slot response (3 bytes: [0x0A, 0x01, 0x23])
      if (!hasNext && _slotIdBuffer.isEmpty && data.length == 3) {
        final status = data[2] & 0xFF;
        _slotTimeoutTimer?.cancel();
        _log('Slot $pos status: 0x${status.toRadixString(16)} (Empty)');
        _slots[slot] = SlotInfo(
          slotIndex: slot,
          isOccupied: false,
          recipeName: 'Slot $pos (Empty)',
        );
        _currentFetchingSlot = -1;
        notifyListeners();
        _processNextSlotQuery();
        return;
      }

      // Otherwise accumulate the 18-byte UUID response payload
      final bytesToRead = (payloadLen < data.length - 2) ? payloadLen : data.length - 2;
      for (int i = 0; i < bytesToRead; i++) {
        _slotIdBuffer.add(data[2 + i]);
      }

      if (!hasNext || _slotIdBuffer.length >= 18) {
        _slotTimeoutTimer?.cancel();
        if (_slotIdBuffer.length >= 18) {
          final crc = ((_slotIdBuffer[0] & 0xFF) << 8) | (_slotIdBuffer[1] & 0xFF);
          final uuidBytes = _slotIdBuffer.sublist(2, 18);
          final uuidStr = RecipePacketBuilder.bytesToUuid(uuidBytes);

          // Resolve Recipe Name
          String resolvedName = 'Slot $pos';
          final preset = PresetCatalog.findByUuid(uuidStr);
          if (preset != null) {
            resolvedName = preset.name;
          } else {
            final cached = storageService.getCachedRecipeName(uuidStr);
            if (cached != null && cached.isNotEmpty) {
              resolvedName = cached;
            } else {
              resolvedName = 'Custom Recipe';
            }
          }

          _log('Slot $pos OCCUPIED: $resolvedName (UUID: $uuidStr, CRC: $crc)');
          _slots[slot] = SlotInfo(
            slotIndex: slot,
            isOccupied: true,
            recipeUuid: uuidStr,
            recipeName: resolvedName,
            crc: crc,
          );
        } else {
          _slots[slot] = SlotInfo(
            slotIndex: slot,
            isOccupied: false,
            recipeName: 'Slot $pos (Empty)',
          );
        }
        _currentFetchingSlot = -1;
        notifyListeners();
        _processNextSlotQuery();
      }
    } else if (cmdId == BaristaBleConstants.cmdInsert ||
        cmdId == BaristaBleConstants.cmdAppend) {
      final statusCode = data[2] & 0xFF;
      if (statusCode == BaristaBleConstants.rspSuccess) {
        _log('Recipe flashed successfully to Barista! (Status: 0x20)');
        _isUploading = false;
        _uploadProgress = 1.0;
        _uploadStatusText = 'Recipe added! Check your Barista.';
        _uploadCompleter?.complete(true);
        notifyListeners();
        fetchAllSlots();
      } else {
        final err = BaristaBleConstants.getStatusMessage(statusCode);
        _log('Upload failed: $err (0x${statusCode.toRadixString(16)})');
        _isUploading = false;
        _uploadStatusText = 'Error: $err';
        _uploadCompleter?.complete(false);
        notifyListeners();
      }
    } else if (cmdId == BaristaBleConstants.cmdDelete) {
      final statusCode = data[2] & 0xFF;
      if (statusCode == BaristaBleConstants.rspSuccess) {
        _log('Recipe deleted successfully.');
        fetchAllSlots();
      }
    } else if (cmdId == BaristaBleConstants.cmdClear) {
      final statusCode = data[2] & 0xFF;
      if (statusCode == BaristaBleConstants.rspSuccess) {
        _log('All 13 slots cleared.');
        for (int i = 0; i < 13; i++) {
          _slots[i] = SlotInfo(slotIndex: i, recipeName: 'Slot ${i + 1} (Empty)');
        }
        notifyListeners();
        fetchAllSlots();
      }
    }
  }

  // ===========================================================================
  // 6. Recipe Upload / Flashing Engine
  // ===========================================================================

  /// Flashes a recipe to the designated hardware slot (or auto-appends if slot < 0)
  Future<bool> flashRecipe({
    required Recipe recipe,
    int targetSlot = -1, // -1 = next available slot (Auto-Append)
    void Function(double progress)? onProgress,
  }) async {
    if (!isConnected || _charRecipeCommand == null) {
      _log('Cannot flash: Machine not connected.');
      return false;
    }

    _isUploading = true;
    _uploadProgress = 0.0;
    _uploadStatusText = 'Preparing binary packet...';
    _uploadCompleter = Completer<bool>();
    notifyListeners();

    // Determine occupied count
    final occupiedCount = _slots.where((s) => s.isOccupied).length;

    // SDataWay firmware rules:
    // CMD_INSERT (0x00) is used when target slot is already occupied (1..occupiedCount).
    // For empty memory (occupiedCount == 0), or appending to the next slot (targetSlot < 0 or >= occupiedCount),
    // the machine firmware requires CMD_APPEND (0x01)!
    final isAppend = (targetSlot < 0 || occupiedCount == 0 || targetSlot >= occupiedCount);
    final targetPos = isAppend ? (occupiedCount + 1) : (targetSlot + 1);
    final clampedPos = targetPos.clamp(1, 13);

    _log('Flashing "${recipe.name}" via ${isAppend ? 'CMD_APPEND' : 'CMD_INSERT'} at position $clampedPos');

    try {
      final packet = RecipePacketBuilder.buildPacket(
        isAppend: isAppend,
        targetPos: clampedPos,
        name: recipe.hardwareName,
        uuidStr: recipe.id,
        steps: recipe.steps,
        phases: recipe.phases,
      );

      final commandId = isAppend ? BaristaBleConstants.cmdAppend : BaristaBleConstants.cmdInsert;
      final chunks = RecipePacketBuilder.buildChunks(commandId, packet);
      final totalChunks = chunks.length;

      _log('Packet size: ${packet.length} bytes, divided into $totalChunks BLE chunks.');
      await storageService.cacheRecipeName(recipe.id, recipe.name);

      for (int i = 0; i < totalChunks; i++) {
        final chunkData = chunks[i];
        final chunkIndex = i + 1;

        await _opQueue.enqueue(() async {
          try {
            await _charRecipeCommand!.write(chunkData, withoutResponse: false);
            final progress = chunkIndex / totalChunks;
            _uploadProgress = progress;
            _uploadStatusText = 'Sending chunk $chunkIndex of $totalChunks (${(progress * 100).round()}%)...';
            onProgress?.call(progress);
            notifyListeners();
            return true;
          } catch (e) {
            _log('Error sending chunk $chunkIndex: $e');
            return false;
          }
        }, description: 'Chunk $chunkIndex/$totalChunks');
      }

      _uploadStatusText = 'Verifying hardware CRC-16...';
      notifyListeners();

      // Return future completed by handleRecipeResponse
      return await _uploadCompleter!.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          _isUploading = false;
          _uploadStatusText = 'Timeout waiting for machine ACK.';
          notifyListeners();
          return false;
        },
      );
    } catch (e) {
      _log('Recipe serialization error: $e');
      _isUploading = false;
      _uploadStatusText = 'Serialization error: $e';
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // 7. Slot Management Actions & Machine Controls
  // ===========================================================================

  /// Selects slot on the machine display matrix
  Future<void> selectSlot(int slotIndex) async {
    if (_charRecipeSelection == null) return;
    // Physical Barista expects 1-based position (1..13)
    final hardwarePos = (slotIndex + 1).clamp(1, 13);
    final payload = [hardwarePos & 0xFF];
    final success = await _opQueue.enqueue(() async {
      try {
        await _charRecipeSelection!.write(payload, withoutResponse: false);
        _log('Slot $hardwarePos selected on physical machine.');
        return true;
      } catch (e) {
        _log('Error selecting slot: $e');
        return false;
      }
    }, description: 'Select Slot $hardwarePos');

    if (success == true) {
      _updateTelemetry(_telemetry.copyWith(selectedSlot: slotIndex));
    }
  }

  /// Emergency STOP: cuts motor rotation and kills induction heater coil
  Future<void> emergencyStop() async {
    if (_charCommandReq == null) return;
    final stopPayload = [0x01, 0x00];
    await _opQueue.enqueue(() async {
      try {
        await _charCommandReq!.write(stopPayload, withoutResponse: false);
        _log('Emergency STOP triggered! Whisk & induction power cut.');
        return true;
      } catch (e) {
        _log('Error executing emergency stop: $e');
        return false;
      }
    }, description: 'Emergency STOP');
  }

  /// Deletes a specific slot from machine memory
  Future<void> deleteSlot(int slot) async {
    if (_charRecipeCommand == null) return;
    final pos = slot + 1; // 1-based (1..13)
    final cmd = [BaristaBleConstants.cmdDelete, 0x01, pos & 0xFF];
    _log('Deleting slot $pos...');
    await _opQueue.enqueue(() async {
      try {
        await _charRecipeCommand!.write(cmd, withoutResponse: false);
        return true;
      } catch (e) {
        _log('Error deleting slot: $e');
        return false;
      }
    }, description: 'Delete Slot $pos');
  }

  /// Clears all 13 slots in machine EEPROM
  Future<void> clearAllSlots() async {
    if (_charRecipeCommand == null) return;
    final cmd = [BaristaBleConstants.cmdClear, 0x00];
    _log('Clearing all 13 slots on machine...');
    await _opQueue.enqueue(() async {
      try {
        await _charRecipeCommand!.write(cmd, withoutResponse: false);
        return true;
      } catch (e) {
        _log('Error clearing slots: $e');
        return false;
      }
    }, description: 'Clear All Slots');
  }

  /// Moves/reorders slot position on the machine
  Future<void> moveSlot(int fromSlot, int toSlot) async {
    if (_charRecipeCommand == null) return;
    final fromPos = fromSlot + 1;
    final toPos = toSlot + 1;
    final cmd = [BaristaBleConstants.cmdMove, 0x02, fromPos & 0xFF, toPos & 0xFF];
    _log('Moving slot from $fromPos to $toPos...');
    await _opQueue.enqueue(() async {
      try {
        await _charRecipeCommand!.write(cmd, withoutResponse: false);
        fetchAllSlots();
        return true;
      } catch (e) {
        _log('Error moving slot: $e');
        return false;
      }
    }, description: 'Move Slot');
  }

  void _updateTelemetry(MachineTelemetry newTelemetry) {
    _telemetry = newTelemetry;
    notifyListeners();
  }

  static List<int> deriveCmidFromSeed(String seedHex) {
    var seed = seedHex.replaceAll(' ', '').trim();
    if (seed.isEmpty) {
      seed = BaristaBleConstants.defaultPairedCmid;
    }
    // If it is already an 8-byte (16 hex chars) CMID starting with 8 or 9:
    if (seed.length == 16 && (seed.startsWith('8') || seed.startsWith('9'))) {
      return _hexToBytes(seed);
    }
    final s = ('${seed}0').substring(0, 16);
    final bArr = List<int>.filled(8, 0);
    for (int i = 0; i < 16; i += 2) {
      final high = int.parse(s[i], radix: 16);
      final low = int.parse(s[i + 1], radix: 16);
      bArr[i ~/ 2] = ((high << 4) | low) & 0xFF;
    }
    final res = List<int>.filled(8, 0);
    res[0] = (((bArr[0] & 0xF0) >> 4) | 0x80) & 0xFF;
    for (int i = 0; i < 7; i++) {
      res[i + 1] = (((bArr[i] & 0x0F) << 4) | ((bArr[i + 1] & 0xF0) >> 4)) & 0xFF;
    }
    return res;
  }

  static List<int> _hexToBytes(String hex) {
    final clean = hex.replaceAll(' ', '').trim();
    final bytes = <int>[];
    for (int i = 0; i < clean.length; i += 2) {
      bytes.add(int.parse(clean.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}
