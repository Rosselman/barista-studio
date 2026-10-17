class MachineTelemetry {
  final bool isConnected;
  final bool isScanning;
  final String? deviceName;
  final String? macAddress;
  final String? serialNumber;
  final String machineState; // STANDBY, READY, RECIPE_EXECUTING, etc.
  final String pairingState; // NONE, TEMPORARY, FINAL, UNDEFINED
  final int? selectedSlot; // 0..12

  const MachineTelemetry({
    this.isConnected = false,
    this.isScanning = false,
    this.deviceName,
    this.macAddress,
    this.serialNumber,
    this.machineState = 'DISCONNECTED',
    this.pairingState = 'NONE',
    this.selectedSlot,
  });

  MachineTelemetry copyWith({
    bool? isConnected,
    bool? isScanning,
    String? deviceName,
    String? macAddress,
    String? serialNumber,
    String? machineState,
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
