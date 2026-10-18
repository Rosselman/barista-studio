import 'machine_state.dart';
export 'machine_state.dart';

class MachineTelemetry {
  final bool isConnected;
  final bool isScanning;
  final String? deviceName;
  final String? macAddress;
  final String? serialNumber;
  final MachineState machineState;
  final String pairingState; // NONE, TEMPORARY, FINAL, UNDEFINED
  final int? selectedSlot; // 0..12

  const MachineTelemetry({
    this.isConnected = false,
    this.isScanning = false,
    this.deviceName,
    this.macAddress,
    this.serialNumber,
    this.machineState = MachineState.standby,
    this.pairingState = 'NONE',
    this.selectedSlot,
  });

  MachineTelemetry copyWith({
    bool? isConnected,
    bool? isScanning,
    String? deviceName,
    String? macAddress,
    String? serialNumber,
    MachineState? machineState,
    String? pairingState,
    int? selectedSlot,
  }) {
    return MachineTelemetry(
      isConnected: isConnected ?? this.isConnected,
      isScanning: isScanning ?? this.isScanning,
      deviceName: deviceName ?? this.deviceName,
      macAddress: macAddress ?? this.macAddress,
      serialNumber: serialNumber ?? this.serialNumber,
      machineState: machineState ?? this.machineState,
      pairingState: pairingState ?? this.pairingState,
      selectedSlot: selectedSlot ?? this.selectedSlot,
    );
  }
}
