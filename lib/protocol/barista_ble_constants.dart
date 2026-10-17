class BaristaBleConstants {
  // GATT Service UUIDs
  static const String deviceInfoService =
      '65241910-0253-11e7-93ae-92361f002671';
  static const String statusControlService =
      '65241920-0253-11e7-93ae-92361f002671';
  static const String recipeService =
      '65241990-0253-11e7-93ae-92361f002671';
  static const String languageService =
      '652419a0-0253-11e7-93ae-92361f002671';
  static const String errorService =
      '65241930-0253-11e7-93ae-92361f002671';

  // Characteristic UUIDs
  static const String charProfileVersion =
      '65243a11-0253-11e7-93ae-92361f002671';
  static const String charMachineInfo =
      '65243a21-0253-11e7-93ae-92361f002671';
  static const String charSerialNumber =
      '65243a31-0253-11e7-93ae-92361f002671';
  static const String charCmid =
      '65243a41-0253-11e7-93ae-92361f002671';
  static const String charCmidType =
      '65243a51-0253-11e7-93ae-92361f002671';
  static const String charTxLevelRequest =
      '65243a61-0253-11e7-93ae-92361f002671';

  static const String charMachineStatus =
      '65243a12-0253-11e7-93ae-92361f002671';
  static const String charMachineParams =
      '65243a22-0253-11e7-93ae-92361f002671';
  static const String charCommandReq =
      '65243a42-0253-11e7-93ae-92361f002671';
  static const String charCommandRsp =
      '65243a52-0253-11e7-93ae-92361f002671';

  static const String charRecipeSelection =
      '65243a19-0253-11e7-93ae-92361f002671';
  static const String charRecipeCommand =
      '65243a29-0253-11e7-93ae-92361f002671';
  static const String charRecipeResponse =
      '65243a39-0253-11e7-93ae-92361f002671';
  static const String charRecipeInfo =
      '65243a49-0253-11e7-93ae-92361f002671';

  // Recipe Command IDs
  static const int cmdInsert = 0x00;
  static const int cmdAppend = 0x01;
  static const int cmdReplace = 0x02;
  static const int cmdDelete = 0x03;
  static const int cmdMove = 0x04;
  static const int cmdClear = 0x06;
  static const int cmdGetId = 0x0A; // 10

  // Response Codes
  static const int rspSuccess = 0x20; // 32
  static const int rspFailed = 0x21; // 33
  static const int rspInvalidState = 0x22; // 34
  static const int rspOutOfRange = 0x23; // 35
  static const int rspWrongCrc = 0x24; // 36
  static const int rspFormatError = 0x25; // 37
  static const int rspNotSupported = 0x26; // 38
  static const int rspMemoryFull = 0x27; // 39

  // Default Paired CMID key
  static const String defaultPairedCmid = '82C15F832A864437';

  // Machine States
  static const List<String> machineStates = [
    'STANDBY',
    'READY',
    'RECIPE_EXECUTING',
    'LOCAL_SETTINGS',
    'ERROR',
    'OVERHEATED',
    'OOBE',
    'RECIPE_PAUSED',
  ];

  // Pairing States
  static const List<String> pairingStates = [
    'NONE',
    'TEMPORARY',
    'FINAL',
    'UNDEFINED',
  ];

  static String getStatusMessage(int code) {
    switch (code) {
      case rspSuccess:
        return 'Success';
      case rspFailed:
        return 'Command Failed';
      case rspInvalidState:
        return 'Invalid State';
      case rspOutOfRange:
        return 'Out of Range (Empty Slot)';
      case rspWrongCrc:
        return 'Checksum Mismatch';
      case rspFormatError:
        return 'Recipe Format Error';
      case rspNotSupported:
        return 'Not Supported';
      case rspMemoryFull:
        return 'Memory Full (Max 13 Recipes)';
      default:
        return 'Status Code 0x${code.toRadixString(16).toUpperCase()}';
    }
  }
}
