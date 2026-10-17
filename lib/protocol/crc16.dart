/// CRC-16/CCITT calculation matching the Barista W545 firmware
class Crc16 {
  /// Computes the 16-bit CRC over [data] from index [start] to [end] (exclusive)
  static int compute(List<int> data, int start, int end) {
    int crc = 0xFFFF;
    for (int i = start; i < end; i++) {
      crc ^= (data[i] & 0xFF) << 8;
      for (int bit = 0; bit < 8; bit++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc;
  }
}
