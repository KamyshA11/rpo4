import 'dart:io';
import 'dart:async';
import 'package:logging/logging.dart';
import '../utils/hex_utils.dart';

class NfcService {
  final Logger _log = Logger('NfcService');
  
  // Абсолютные пути к утилитам (поправьте при необходимости)
  final String _nfcListPath = r'C:\Users\Admin\rpo4\rpo4\libs\libnfc\build\utils\nfc-list.exe';
  final String _nfcMfClassicPath = r'C:\Users\Admin\rpo4\rpo4\libs\libnfc\build\utils\nfc-mfclassic.exe';
  
  Future<void> init() async {
    // Проверяем, существуют ли нужные файлы
    if (!await File(_nfcListPath).exists()) {
      throw Exception('nfc-list.exe not found at $_nfcListPath');
    }
    if (!await File(_nfcMfClassicPath).exists()) {
      _log.warning('nfc-mf-classic.exe not found – read/write functions will fail');
    }
    _log.info('NFC service initialized');
  }

  Future<String?> detectCardUID({Duration timeout = const Duration(seconds: 10)}) async {
    _log.info('Waiting for card (${timeout.inSeconds}s)...');
    try {
      final result = await Process.run(_nfcListPath, ['-v']).timeout(timeout);
      if (result.exitCode != 0) {
        _log.warning('nfc-list error: ${result.stderr}');
        return null;
      }
      final output = result.stdout as String;
      final regex = RegExp(r'(([0-9A-F]{2}:){3}[0-9A-F]{2})', caseSensitive: false);
      final match = regex.firstMatch(output);
      if (match != null) {
        final uidWithColons = match.group(0)!;
        return uidWithColons.replaceAll(':', '');
      }
      return null;
    } on TimeoutException catch (_) {
      _log.warning('Card detection timed out after ${timeout.inSeconds}s');
      return null;
    } catch (e) {
      _log.severe('Error reading card: $e');
      return null;
    }
  }

  Future<int?> readBalance(String uid, String key, int block) async {
    try {
      final result = await Process.run(_nfcMfClassicPath, ['r', uid, block.toString(), key], runInShell: true);
      if (result.exitCode != 0) {
        _log.warning('Read failed: ${result.stderr}');
        return null;
      }
      final output = (result.stdout as String).trim();
      final hexBytes = output.split(RegExp(r'\s+'));
      if (hexBytes.length < 16) return null;
      final bytes = hexBytes.map((h) => int.parse(h, radix: 16)).toList();
      return HexUtils.parseBalance(bytes);
    } catch (e) {
      _log.severe('Error reading balance: $e');
      return null;
    }
  }

  Future<bool> writeBalance(String uid, String key, int block, int balance) async {
    final data = HexUtils.bytesToHex(HexUtils.encodeBalance(balance));
    try {
      final result = await Process.run(_nfcMfClassicPath, ['w', uid, block.toString(), key, data], runInShell: true);
      if (result.exitCode != 0) {
        _log.warning('Write failed: ${result.stderr}');
        return false;
      }
      return true;
    } catch (e) {
      _log.severe('Error writing balance: $e');
      return false;
    }
  }
}