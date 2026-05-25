class HexUtils {
  static String bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static List<int> hexToBytes(String hex) {
    if (hex.length % 2 != 0) throw ArgumentError('Hex string must have even length');
    return List.generate(hex.length ~/ 2, (i) => int.parse(hex.substring(i*2, i*2+2), radix: 16));
  }

  // Парсинг 4 байт little-endian из 16-байтового блока
  static int parseBalance(List<int> block) {
    if (block.length < 4) return 0;
    return block[0] | (block[1] << 8) | (block[2] << 16) | (block[3] << 24);
  }

  // Формирование 16-байтового блока для записи баланса
  static List<int> encodeBalance(int balance) {
    final block = List<int>.filled(16, 0);
    block[0] = balance & 0xFF;
    block[1] = (balance >> 8) & 0xFF;
    block[2] = (balance >> 16) & 0xFF;
    block[3] = (balance >> 24) & 0xFF;
    return block;
  }
}