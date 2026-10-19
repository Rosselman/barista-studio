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
  /// Byte 1 is an unshifted state index (0..7):
  /// 0 = Standby, 1 = Ready, 2 = Executing, 3 = Settings Mode,
  /// 4 = Error, 5 = Overheated, 6 = First Setup, 7 = Paused.
  static MachineState fromByte(int byte1) {
    final code = byte1 & 0x0F;
    switch (code) {
      case 0:
        return MachineState.standby;
      case 1:
        return MachineState.ready;
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
      case 7:
        return MachineState.recipePaused;
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
