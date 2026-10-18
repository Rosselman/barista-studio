enum MachineState {
  ready(0, 'Ready'),
  recipePaused(1, 'Paused (Press Button)'),
  recipeExecuting(2, 'Executing'),
  localSettingsMode(3, 'Settings Mode'),
  error(4, 'Error'),
  overheated(5, 'Overheated'),
  outOfTheBoxSettings(6, 'First Setup'),
  standby(8, 'Standby');

  final int code;
  final String label;
  const MachineState(this.code, this.label);

  /// Decodes MachineState from Byte 1 of CHAR_MACHINE_STATUS.
  /// Bits 2-7 contain the state code.
  /// CRITICAL: Operator precedence in Dart requires parentheses: (byte1 & 0xFC) >> 2
  static MachineState fromByte(int byte1) {
    final code = (byte1 & 0xFC) >> 2;
    switch (code) {
      case 0:
        return MachineState.ready;
      case 1:
      case 7:
        return MachineState.recipePaused;
      case 2:
        return MachineState.recipeExecuting;
      case 3:
        return MachineState.localSettingsMode;
      case 4:
        return MachineState.error;
      case 5:
        return MachineState.overheated;
      case 6:
        return MachineState.outOfTheBoxSettings;
      case 8:
        return MachineState.standby;
      default:
        return MachineState.standby;
    }
  }

  bool get isStandby => this == MachineState.standby;
  bool get isReady => this == MachineState.ready;
  bool get isExecuting => this == MachineState.recipeExecuting;
  bool get isLocalSettings => this == MachineState.localSettingsMode;
  bool get isError => this == MachineState.error;
  bool get isOverheated => this == MachineState.overheated;
  bool get isFirstSetup => this == MachineState.outOfTheBoxSettings;
  bool get isPaused => this == MachineState.recipePaused;

  @override
  String toString() => '$label ($code)';
}
