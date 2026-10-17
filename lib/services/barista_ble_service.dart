import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/machine_telemetry.dart';
import '../models/phase.dart';
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

  void _log(String message) {
    debugPrint('[BaristaBLE] $message');
    _logController.add(message);
  }

  BaristaBleService({required this.storageService});

  bool get isConnected => _telemetry.isConnected;

  // ===========================================================================
  // 1. Scanning & Connection Management
  // ===========================================================================

  Future<void> startScan() async {
    if (_telemetry.isScanning) return;
    _updateTelemetry(_telemetry.copyWith(isScanning: true));
    _log('Scanning for Nespresso Barista W545...');

    try {
      // Listen to scan results
      final sub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.device.platformName;
          final advName = r.advertisementData.advName;
          if (name.contains('Barista') ||
              advName.contains('Barista') ||
              r.device.remoteId.str == storageService.getLastConnectedMac()) {
            _log('Found Barista device: $name (${r.device.remoteId.str})');
            stopScan();
            connect(r.device);
            break;
          }
        }
      });

      await FlutterBluePlus.startScan(
        withServices: [Guid(BaristaBleConstants.deviceInfoService)],
        timeout: const Duration(seconds: 12),
      );

      // Auto stop scan after timeout
      Future.delayed(const Duration(seconds: 12), () {
        sub.cancel();
        if (_telemetry.isScanning) {
          _updateTelemetry(_telemetry.copyWith(isScanning: false));
          _log('Scan completed.');
        }
      });
    } catch (e) {
      _log('Scan error: $e');
      _updateTelemetry(_telemetry.copyWith(isScanning: false));
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _updateTelemetry(_telemetry.copyWith(isScanning: false));
  }

  Future<void> connect(BluetoothDevice device) async {
    await disconnect();
    _device = device;
    _log('Connecting to GATT: ${device.remoteId.str}...');

    _connSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.connected) {
        _log('Connected to ${device.remoteId.str}. Discovering services...');
        storageService.setLastConnectedMac(device.remoteId.str);
        _updateTelemetry(_telemetry.copyWith(
          isConnected: true,
          deviceName: device.platformName.isNotEmpty
              ? device.platformName
              : 'Nespresso Barista',
          macAddress: device.remoteId.str,
        ));
        _discoverAndSetupServices(device);
      } else if (state == BluetoothConnectionState.disconnected) {
        _log('Disconnected from Barista.');
        _handleDisconnection();
      }
    });

    try {
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );
    } catch (e) {
      _log('Connection failed: $e');
      _handleDisconnection();
    }
  }

  Future<void> disconnect() async {
    _slotTimeoutTimer?.cancel();
    _opQueue.clear();
    await _statusSub?.cancel();
    await _recipeResponseSub?.cancel();
    await _recipeSelectionSub?.cancel();
    await _connSub?.cancel();

    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (_) {}
      _device = null;
    }
    _handleDisconnection();
  }

  void _handleDisconnection() {
    _slotTimeoutTimer?.cancel();
    _opQueue.clear();
    _currentFetchingSlot = -1;
    _updateTelemetry(const MachineTelemetry());
  }

  // ===========================================================================
  // 2. Service Discovery & Characteristic Caching
  // ===========================================================================

  Future<void> _discoverAndSetupServices(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      for (final s in services) {
        final sUuid = s.uuid.str.toLowerCase();
        if (sUuid == BaristaBleConstants.deviceInfoService.toLowerCase()) {
          for (final c in s.characteristics) {
            final cUuid = c.uuid.str.toLowerCase();
            if (cUuid == BaristaBleConstants.charSerialNumber.toLowerCase()) {
              _charSerialNumber = c;
            } else if (cUuid == BaristaBleConstants.charCmid.toLowerCase()) {
              _charCmid = c;
            } else if (cUuid == BaristaBleConstants.charCmidType.toLowerCase()) {
              _charCmidType = c;
            } else if (cUuid ==
                BaristaBleConstants.charTxLevelRequest.toLowerCase()) {
              _charTxLevelRequest = c;
            }
          }
        } else if (sUuid ==
            BaristaBleConstants.statusControlService.toLowerCase()) {
          for (final c in s.characteristics) {
            final cUuid = c.uuid.str.toLowerCase();
            if (cUuid == BaristaBleConstants.charMachineStatus.toLowerCase()) {
              _charMachineStatus = c;
            } else if (cUuid ==
                BaristaBleConstants.charCommandReq.toLowerCase()) {
              _charCommandReq = c;
            }
          }
        } else if (sUuid == BaristaBleConstants.recipeService.toLowerCase()) {
          for (final c in s.characteristics) {
            final cUuid = c.uuid.str.toLowerCase();
            if (cUuid ==
                BaristaBleConstants.charRecipeSelection.toLowerCase()) {
              _charRecipeSelection = c;
            } else if (cUuid ==
                BaristaBleConstants.charRecipeCommand.toLowerCase()) {
              _charRecipeCommand = c;
            } else if (cUuid ==
                BaristaBleConstants.charRecipeResponse.toLowerCase()) {
              _charRecipeResponse = c;
            }
          }
        }
      }

      _log('GATT Characteristics cached. Enabling notifications & handshake...');
      await _setupNotificationsAndAuth();
    } catch (e) {
      _log('Service discovery error: $e');
    }
  }

  // ===========================================================================
  // 3. Notifications & CMID Authentication Handshake
  // ===========================================================================

  Future<void> _setupNotificationsAndAuth() async {
    // 1. Subscribe to MACHINE_STATUS
    if (_charMachineStatus != null) {
      try {
        await _charMachineStatus!.setNotifyValue(true);
        _statusSub = _charMachineStatus!.lastValueStream.listen(_handleMachineStatus);
        _log('MACHINE_STATUS notifications active.');
      } catch (e) {
        _log('Error setting MACHINE_STATUS notification: $e');
      }
    }

    // 2. Subscribe to RECIPE_RESPONSE
    if (_charRecipeResponse != null) {
      try {
        await _charRecipeResponse!.setNotifyValue(true);
        _recipeResponseSub = _charRecipeResponse!.lastValueStream.listen(_handleRecipeResponse);
        _log('RECIPE_RESPONSE notifications active.');
      } catch (e) {
        _log('Error setting RECIPE_RESPONSE notification: $e');
      }
    }

    // 3. Subscribe to RECIPE_SELECTION
    if (_charRecipeSelection != null) {
      try {
        await _charRecipeSelection!.setNotifyValue(true);
        _recipeSelectionSub = _charRecipeSelection!.lastValueStream.listen((val) {
          if (val.isNotEmpty) {
            final slot = val[0] & 0xFF;
            _updateTelemetry(_telemetry.copyWith(selectedSlot: slot));
            _log('Machine selected slot changed: Slot ${slot + 1}');
          }
        });
      } catch (e) {
        _log('Error setting RECIPE_SELECTION notification: $e');
      }
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
    _performPairingHandshake();
  }

  void _performPairingHandshake() {
    if (_charMachineStatus == null) return;

    _opQueue.enqueue(() async {
      try {
        final data = await _charMachineStatus!.read();
        if (data.length < 2) return false;
        final b0 = data[0] & 0xFF;
        final pairingCode = (b0 & 0x60) >> 5;
        _log('Current pairing code: $pairingCode (0=NONE, 1=TEMP, 2=FINAL)');

        // Step A: Only write TX_LEVEL_REQUEST (0x01) if NOT already FINAL
        if (pairingCode != 2 && _charTxLevelRequest != null) {
          _log('Sending TX_LEVEL_REQUEST (0x01)...');
          await _charTxLevelRequest!.write([0x01], withoutResponse: false);
        }

        // Step B: Write 8-byte CMID key to authenticate the connection session
        final cmidHex = storageService.getCmidKey();
        final cmidBytes = _hexToBytes(cmidHex);
        if (_charCmid != null) {
          _log('Writing 8-byte CMID to charCmid: $cmidHex');
          await _charCmid!.write(cmidBytes, withoutResponse: false);
        }

        // Step C: Verify CMID_TYPE confirmation
        if (_charCmidType != null) {
          final typeData = await _charCmidType!.read();
          if (typeData.isNotEmpty) {
            _log('CMID_TYPE response: 0x${typeData[0].toRadixString(16)}');
          }
        }

        _log('Pairing session authenticated. Scanning all 13 slots...');
        fetchAllSlots();
        return true;
      } catch (e) {
        _log('Pairing handshake error: $e');
        fetchAllSlots();
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

    final motorRunning = (b0 & 0x10) != 0;
    final heatingActive = (b0 & 0x20) != 0;
    final pairingCode = (b0 & 0x60) >> 5;
    final stateCode = (b1 & 0xFC) >> 2;

    final stateStr = (stateCode < BaristaBleConstants.machineStates.length)
        ? BaristaBleConstants.machineStates[stateCode]
        : 'UNKNOWN($stateCode)';

    final pStateStr = (pairingCode < BaristaBleConstants.pairingStates.length)
        ? BaristaBleConstants.pairingStates[pairingCode]
        : 'UNKNOWN';

    _updateTelemetry(_telemetry.copyWith(
      motorRunning: motorRunning,
      inductionHeatingActive: heatingActive,
      machineState: stateStr,
      pairingState: pStateStr,
    ));
  }

  // ===========================================================================
  // 5. Slot Scanning & Recipe Response Parser
  // ===========================================================================

  void fetchAllSlots() {
    _opQueue.enqueue(() async {
      for (int i = 0; i < 13; i++) {
        _fetchSlotInternal(i);
      }
      return true;
    }, description: 'Fetch All Slots');
  }

  void fetchSlot(int slot) {
    _opQueue.enqueue(() async {
      _fetchSlotInternal(slot);
      return true;
    }, description: 'Fetch Slot $slot');
  }

  void _fetchSlotInternal(int slot) {
    if (_charRecipeCommand == null) return;
    _currentFetchingSlot = slot;
    _slotIdBuffer.clear();

    final pos = slot + 1; // 1-based (1..13)
    final cmd = [BaristaBleConstants.cmdGetId, 0x01, pos & 0xFF];

    _slotTimeoutTimer?.cancel();
    _slotTimeoutTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_currentFetchingSlot == slot) {
        _log('Timeout querying Slot $pos.');
        _slots[slot] = SlotInfo(
          slotIndex: slot,
          isOccupied: false,
          recipeName: 'Slot $pos (Empty)',
        );
        _currentFetchingSlot = -1;
        notifyListeners();
      }
    });

    _charRecipeCommand!.write(cmd, withoutResponse: false).catchError((e) {
      _log('Error sending CMD_GET_ID for Slot $pos: $e');
    });
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
  Future<void> selectSlot(int slot) async {
    if (_charRecipeSelection == null) return;
    final payload = [slot & 0xFF];
    await _opQueue.enqueue(() async {
      try {
        await _charRecipeSelection!.write(payload, withoutResponse: false);
        _log('Slot ${slot + 1} selected on physical machine.');
        return true;
      } catch (e) {
        _log('Error selecting slot: $e');
        return false;
      }
    }, description: 'Select Slot $slot');
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

  static List<int> _hexToBytes(String hex) {
    final clean = hex.replaceAll(' ', '').trim();
    final bytes = <int>[];
    for (int i = 0; i < clean.length; i += 2) {
      bytes.add(int.parse(clean.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}
