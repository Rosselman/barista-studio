import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/phase.dart';
import '../models/recipe_step.dart';
import 'crc16.dart';

class RecipePacketBuilder {
  /// Converts a standard 36-char UUID string into 16 raw bytes
  static List<int> uuidToBytes(String uuidStr) {
    try {
      final clean = uuidStr.replaceAll('-', '');
      if (clean.length == 32) {
        final bytes = <int>[];
        for (int i = 0; i < 32; i += 2) {
          bytes.add(int.parse(clean.substring(i, i + 2), radix: 16));
        }
        return bytes;
      }
    } catch (_) {}

    // Fallback: generate a valid random 16-byte UUID
    final raw = const Uuid().v4().replaceAll('-', '');
    final bytes = <int>[];
    for (int i = 0; i < 32; i += 2) {
      bytes.add(int.parse(raw.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  /// Converts 16 raw bytes back to standard UUID formatted string
  static String bytesToUuid(List<int> bytes) {
    if (bytes.length < 16) return '';
    final hex = bytes
        .take(16)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toLowerCase();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Builds the exact SDataWay binary recipe packet supporting single and multi-step recipes.
  ///
  /// Binary Packet Layout:
  /// [0x00]       : targetPos (1..13, 1-based, omitted if isAppend == true)
  /// [0x01..0x02] : CRC-16 CCITT (over all remaining payload bytes)
  /// [0x03..0x04] : Payload length (big-endian)
  /// [0x05..0x14] : 16-byte UUID
  /// [0x15]       : Recipe Name length (N)
  /// [0x16..]     : Recipe ASCII Name
  /// [1 byte]     : stepCount (e.g. 1 or 2)
  ///   -- For each Step (1 to stepCount) --
  ///   [1 byte]   : Step Name length (e.g. 6 for "STEP 1")
  ///   [M bytes]  : Step ASCII Name ("STEP 1", "STEP 2")
  ///   [1 byte]   : phaseCount (1 to 3)
  ///     -- For each Phase (6 bytes) --
  ///     [2 bytes]: speed RPM (300 to 4000, big-endian)
  ///     [2 bytes]: acceleration (50 to 2000, big-endian)
  ///     [1 byte] : temperature (0 to 70 °C, 0 = cold froth)
  ///     [1 byte] : duration (1 to 240 seconds)
  static List<int> buildPacket({
    required bool isAppend,
    required int targetPos, // 1-based (1..13)
    required String name,
    required String uuidStr,
    List<RecipeStep>? steps,
    List<Phase>? phases,
  }) {
    // 1. Sanitize Recipe Name (Max 16 ASCII bytes)
    final cleanName = name.trim().isEmpty ? 'Recipe' : name.trim();
    final asciiOnly = cleanName.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    final nameStr = asciiOnly.isEmpty ? 'Recipe' : asciiOnly;
    final nameBytes = ascii.encode(nameStr);
    final clampedNameBytes = nameBytes.take(16).toList();

    // 2. Resolve effective steps
    final effectiveSteps = (steps != null && steps.isNotEmpty)
        ? steps
        : [
            RecipeStep(
              name: 'STEP 1',
              phases: (phases != null && phases.isNotEmpty)
                  ? phases
                  : [Phase.clamped(speed: 3000, accel: 800, temp: 65, duration: 30)],
            ),
          ];

    // 3. Encode Steps Buffer
    final stepsBytes = <int>[];
    for (int i = 0; i < effectiveSteps.length; i++) {
      final s = effectiveSteps[i];
      final defaultName = 'STEP ${i + 1}';
      final rawName = s.name.trim().isEmpty ? defaultName : s.name.trim();
      final asciiName = rawName.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
      final stepNameStr = asciiName.isEmpty ? defaultName : asciiName;
      final stepNameBytes = ascii.encode(stepNameStr).take(16).toList();

      final activePhases = s.phases.where((p) => p.duration > 0).take(3).toList();
      final effectivePhases = activePhases.isEmpty
          ? [Phase.clamped(speed: 3000, accel: 800, temp: 65, duration: 30)]
          : activePhases;

      // [1 byte] Step Name length
      stepsBytes.add(stepNameBytes.length);
      // [M bytes] Step ASCII Name
      stepsBytes.addAll(stepNameBytes);
      // [1 byte] Phase count (1 to 3)
      stepsBytes.add(effectivePhases.length);
      // [6 bytes per Phase]
      for (final p in effectivePhases) {
        final speed = p.speed.clamp(300, 4000);
        final accel = p.accel.clamp(50, 2000);
        final temp = p.temp.clamp(0, 70);
        final dur = p.duration.clamp(1, 240);

        stepsBytes.add((speed >> 8) & 0xFF);
        stepsBytes.add(speed & 0xFF);
        stepsBytes.add((accel >> 8) & 0xFF);
        stepsBytes.add(accel & 0xFF);
        stepsBytes.add(temp & 0xFF);
        stepsBytes.add(dur & 0xFF);
      }
    }

    // 4. Calculate Payload Length
    // 16 (UUID) + 1 (NameLen) + nameBytes.length + 1 (StepCount) + stepsBytes.length
    final payloadLen = 16 + 1 + clampedNameBytes.length + 1 + stepsBytes.length;
    final totalPacketLen = (isAppend ? 4 : 5) + payloadLen;
    final packet = List<int>.filled(totalPacketLen, 0);
    int idx = 0;

    // Slot position (Only for INSERT / REPLACE, omitted for APPEND)
    if (!isAppend) {
      final pos = targetPos.clamp(1, 13);
      packet[idx++] = pos & 0xFF;
    }

    final crcPos = idx;
    packet[idx++] = 0; // CRC High placeholder
    packet[idx++] = 0; // CRC Low placeholder
    packet[idx++] = (payloadLen >> 8) & 0xFF;
    packet[idx++] = payloadLen & 0xFF;

    // 16-byte UUID
    final uidBytes = uuidToBytes(uuidStr);
    for (int b in uidBytes) {
      packet[idx++] = b;
    }

    // Name length & ASCII name
    packet[idx++] = clampedNameBytes.length;
    for (int b in clampedNameBytes) {
      packet[idx++] = b;
    }

    // Step count
    packet[idx++] = effectiveSteps.length;

    // Steps Bytes
    for (int b in stepsBytes) {
      packet[idx++] = b;
    }

    // 5. Compute CRC-16 CCITT over payload (from byte after CRC to end)
    final crcStart = isAppend ? 2 : 3;
    final crc = Crc16.compute(packet, crcStart, packet.length);
    packet[crcPos] = (crc >> 8) & 0xFF;
    packet[crcPos + 1] = crc & 0xFF;

    return packet;
  }

  /// Chunks the packet into 16-byte payload chunks with W545 control header
  static List<List<int>> buildChunks(int commandId, List<int> payload) {
    const chunkSize = 16;
    final totalLen = payload.length;
    final numChunks = (totalLen / chunkSize).ceil();
    final chunks = <List<int>>[];

    for (int i = 1; i <= numChunks; i++) {
      final offset = (i - 1) * chunkSize;
      final remaining = totalLen - offset;
      final len = remaining < chunkSize ? remaining : chunkSize;
      final hasNext = (i != numChunks);
      final toggle = (i % 2 == 0);

      int ctrl = len & 0x1F;
      if (toggle) ctrl |= 0x40;
      if (hasNext) ctrl |= 0x80;

      final chunk = List<int>.filled(2 + len, 0);
      chunk[0] = commandId & 0xFF;
      chunk[1] = ctrl & 0xFF;
      for (int k = 0; k < len; k++) {
        chunk[2 + k] = payload[offset + k];
      }
      chunks.add(chunk);
    }
    return chunks;
  }
}
