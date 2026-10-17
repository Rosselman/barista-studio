# Barista Studio (barista_studio)

A clean, modern, ope source, standalone Flutter application for crafting, sequencing, and flashing custom recipes into the **Nespresso Barista Recipe Maker (Model W545)** via native Bluetooth Low Energy.

---

## 1. Overview & Highlights

**Barista Studio** provides direct, cloudless control over the Nespresso Barista Recipe Maker hardware:
- **Zero Proprietary Bytecode or Cloud Dependency**: Communicates directly with the machine's local GATT profile using standard BLE protocols. Does not require an internet connection, proprietary vendor clouds, or user accounts.
- **Full 13-Slot Hardware Memory Management**: Read, flash, reorder, or delete recipes across all 13 physical EEPROM slots on the machine.
- **3-Phase Custom Recipe Sequencer**: Fine-tuned control over motor speed (300–4000 RPM), ramp acceleration (50–2000), induction heating temperature (0–70°C, with 0°C cold froth toggle), and duration (0–240s).
- **Gourmet Preset Library**: A curated collection of tuned presets (Cappuccino, Flat White, Velvet Cortado, Iced Frappé, Nitro Cold Foam, Oat Microfoam at 58°C, Hot Chocolate, Matcha Silk, Golden Turmeric Elixir, and more) with step-by-step culinary preparation instructions.
- **Hardware Telemetry HUD & Emergency STOP**: Real-time monitoring of whisk motor activity, induction heating state, machine mode, and 1-tap emergency whisk cutoff and heater kill.

---

## 2. Architecture & Directory Layout

```
barista-studio/
├── android/                        # Android platform configuration & BLE permissions
│   ├── app/
│   │   ├── build.gradle            # minSdk 21, compileSdk 34
│   │   └── src/main/AndroidManifest.xml # BLUETOOTH_SCAN (neverForLocation), CONNECT
│   ├── build.gradle
│   └── settings.gradle
├── macos/                          # macOS platform configuration & entitlements
│   └── Runner/
│       ├── Info.plist              # NSBluetoothAlwaysUsageDescription
│       ├── DebugProfile.entitlements # com.apple.security.device.bluetooth
│       └── Release.entitlements    # com.apple.security.device.bluetooth
├── ios/                            # iOS platform configuration
│   └── Runner/Info.plist           # NSBluetoothAlwaysUsageDescription
├── lib/
│   ├── data/
│   │   └── preset_catalog.dart     # Curated gourmet recipes with ingredients & prep steps
│   ├── models/
│   │   ├── machine_telemetry.dart  # Hardware state (motor, heat, pairing, serial, mac)
│   │   ├── phase.dart              # Single phase (speed, accel, temp, duration)
│   │   ├── recipe.dart             # Recipe model with ASCII sanitization
│   │   └── slot_info.dart          # Representation of machine memory slots (1–13)
│   ├── protocol/
│   │   ├── barista_ble_constants.dart # GATT UUIDs, commands, status response codes
│   │   ├── crc16.dart              # Hardware-verified CRC-16 CCITT (0x1021) calculation
│   │   ├── gatt_op_queue.dart      # Sequential FIFO queue preventing BLE write collisions
│   │   └── recipe_packet_builder.dart # Binary serialization & chunking engine
│   ├── services/
│   │   ├── barista_ble_service.dart # Core BLE manager, CMID handshake, slot scanner
│   │   └── storage_service.dart    # SharedPreferences persistence (recipes, CMID, MAC)
│   ├── theme/
│   │   └── app_theme.dart          # Dark espresso/gold theme palette
│   ├── ui/
│   │   ├── home_shell.dart         # Adaptive shell (NavigationRail / NavigationBar)
│   │   ├── tabs/
│   │   │   ├── custom_recipe_tab.dart # 3-Phase sequencer, clamped sliders, CRC inspector
│   │   │   ├── presets_tab.dart    # Filterable categories, recipe cards, 1-tap flash
│   │   │   └── slots_tab.dart      # 13 hardware slots manager & selector
│   │   └── widgets/
│   │       ├── flash_recipe_dialog.dart # Destination slot picker & progress bar
│   │       ├── recipe_detail_dialog.dart # Detailed ingredients & preparation guide
│   │       └── whisk_visualizer.dart # Animated vortex & induction thermal glow
│   └── main.dart                   # Application entry point & permission handler
├── .gitignore
├── analysis_options.yaml
├── pubspec.yaml                    # flutter_blue_plus, uuid, shared_preferences, permission_handler
└── README.md
```

---

## 3. BLE Protocol & Packet Specification

### GATT Services & Characteristics

| Service | UUID | Key Characteristics |
|---|---|---|
| **Device Info** | `65241910-0253-11e7-93ae-92361f002671` | `CHAR_SERIAL_NUMBER` (`65243a31-...`)<br>`CHAR_CMID` (`65243a41-...`)<br>`CHAR_CMID_TYPE` (`65243a51-...`)<br>`CHAR_TX_LEVEL_REQUEST` (`65243a61-...`) |
| **Status & Control** | `65241920-0253-11e7-93ae-92361f002671` | `CHAR_MACHINE_STATUS` (`65243a12-...`)<br>`CHAR_COMMAND_REQ` (`65243a42-...`) |
| **Recipe Service** | `65241990-0253-11e7-93ae-92361f002671` | `CHAR_RECIPE_SELECTION` (`65243a19-...`)<br>`CHAR_RECIPE_COMMAND` (`65243a29-...`)<br>`CHAR_RECIPE_RESPONSE` (`65243a39-...`) |

### SDataWay CMID Pairing Handshake
1. App reads `CHAR_MACHINE_STATUS`.
2. Evaluates pairing status: `pairingCode = (byte[0] & 0x60) >> 5`.
3. If not `FINAL` (`pairingCode != 2`):
   - Writes `[0x01]` to `CHAR_TX_LEVEL_REQUEST`.
   - Generates and writes an 8-byte CMID authentication key with MSB bit 7 set (`0x80`) to `CHAR_CMID` (persisted in `shared_preferences`).
   - Reads `CHAR_CMID_TYPE` to confirm authorization status.

### Recipe Packet Layout
Binary payload formatted for the W545 microcontroller:

- **Appending to Next Slot (`CMD_APPEND = 0x01`)**:
  - `[0x00..0x01]`: CRC-16 CCITT (Big-Endian, calculated over bytes from index 2 to end)
  - `[0x02..0x03]`: Payload length (Big-Endian uint16)
  - `[0x04..0x13]`: 16-byte Recipe UUID
  - `[0x14]`: Recipe Name Length (N, max 16 bytes ASCII)
  - `[0x15..0x14+N]`: Recipe Name (ASCII)
  - `[0x15+N]`: Step count (`0x01`)
  - Step Header: Step name length (`0x06`), "STEP 1" (6 bytes), Phase count (1..3)
  - Per Phase (6 bytes each):
    - Motor Speed RPM (uint16 Big-Endian, 300 to 4000)
    - Acceleration (uint16 Big-Endian, 50 to 2000)
    - Temperature (°C uint8, 0 to 70: `0` disables heating for cold foam)
    - Duration (seconds uint8, 1 to 240)

- **Inserting into Occupied Slot (`CMD_INSERT = 0x00`)**:
  - `[0x00]`: Target Position (1-based: 1..13)
  - `[0x01..0x02]`: CRC-16 CCITT (calculated over bytes from index 3 to end)
  - `[0x03..0x04]`: Payload length
  - `[0x05..]`: Same payload structure as above.

### Transmission Chunking
Packets are partitioned into 16-byte chunks written to `CHAR_RECIPE_COMMAND`:
- **Byte 0**: Command ID (`0x01` for APPEND, `0x00` for INSERT).
- **Byte 1**: Control byte:
  - Bit 7 (`0x80`): `hasNext` (set if more chunks follow)
  - Bit 6 (`0x40`): `toggle` (`chunkIndex % 2 == 0`)
  - Bits 0..4 (`0x1F`): Chunk payload length (1..16)
- **Bytes 2..**: Chunk data payload.

A sequential FIFO operation queue (`GattOpQueue`) ensures each chunk is acknowledged before the next is transmitted, preventing BLE packet collisions.

---

## 4. Getting Started & Development

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>= 3.19.0)
- [Dart SDK](https://dart.dev/get-dart) (>= 3.3.0)
- Xcode (for macOS and iOS targets)
- Android Studio / Android SDK Platform-Tools (for Android targets)

### Setup & Dependencies
Run in this directory:
```bash
flutter pub get
```

### Running on Android
Ensure your device or emulator has Bluetooth Low Energy enabled:
```bash
flutter run -d android
```

### Running on macOS (Apple Silicon & Intel)
```bash
flutter run -d macos
```

### Building Release Artifacts
- **Android APK**:
  ```bash
  flutter build apk --release
  ```
- **macOS Bundle**:
  ```bash
  flutter build macos --release
  ```

---

## 5. Safety & Hardware Guidelines

- **Safe Temperature Limits**: The app strictly enforces the 0–70°C thermal limit in accordance with the induction coil safety specifications.
- **Cold Foam**: Setting the temperature slider to 0°C disables the induction coil completely, generating dense cold microfoam without heating.

---

## 6. License

This project is released under the MIT License for personal and consumer use. Nespresso® is a trademark of Société des Produits Nestlé S.A. This project is an independent third-party tool and is not affiliated with, endorsed by, or sponsored by Nestlé or Nespresso.