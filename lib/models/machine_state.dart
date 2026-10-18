enum MachineState {
  standby(0, 'Standby'),
  ready(1, 'Ready'),
  recipeExecuting(2, 'Executing'),
  localSettingsMode(3, 'Settings Mode'),
  error(4, 'Error'),
  overheated(5, 'Overheated'),
  outOfTheBoxSettings(6, 'First Setup'),
  recipePaused(7, 'Paused (Press Button)');

  final int code;
  final String label;
  const MachineState(this.code, this.label);

  /// Decodes MachineState from Byte 1 of CHAR_MACHINE_STATUS.
  /// Bits 2-7 contain the state code.
  /// CRITICAL: Operator precedence in Dart requires parentheses: (byte1 & 0xFC) >> 2
  static MachineState fromByte(int byte1) {
    final code = (byte1 & 0xFC) >> 2;
    return MachineState.values.firstWhere(
      (s) => s.code == code,
      orElse: () => MachineState.standby,
    );
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
