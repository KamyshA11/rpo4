import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';

class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();
  
  final Logger _log = Logger('NfcService');
  
  final String _nfcListPath = r'C:\Users\Admin\rpo4\rpo4\libs\libnfc\build\utils\nfc-list.exe';
  final String _nfcMfClassicPath = r'C:\Users\Admin\rpo4\rpo4\libs\libnfc\build\utils\nfc-mfclassic.exe';
  
  final String _comPort = 'COM11';
  String? _cachedComPort;

  Future<String?> _findComPort() async {
    _log.info('Using COM port: $_comPort');
    return _comPort;
  }

  // ---- Чтение UID карты ----
  Future<String?> detectCardUID({int maxAttempts = 30}) async {
    _log.info('Waiting for card...');
    
    _cachedComPort ??= await _findComPort();
    if (_cachedComPort == null) {
      _log.severe('❌ COM port not configured');
      return null;
    }
    
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final result = await Process.run(
          _nfcListPath,
          ['-v'],
          environment: {'LIBNFC_DEVICE': 'pn532_uart:$_cachedComPort'},
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          final output = result.stdout as String;
          final uid = _parseUid(output);
          if (uid != null) {
            _log.info('✅ Card detected! UID: $uid');
            return uid;
          }
        }
        await Future.delayed(Duration(seconds: 1));
      } catch (e) {
        _log.warning('NFC error: $e');
      }
    }
    return null;
  }

  // ---- Чтение баланса через дамп-файл (используем r a u) ----
  Future<int?> readBalance(String uid, {int block = 4, String key = 'FFFFFFFFFFFF'}) async {
    _log.info('Reading balance from card UID: $uid');
    
    _cachedComPort ??= await _findComPort();
    if (_cachedComPort == null) {
      _log.severe('❌ COM port not configured');
      return null;
    }
    
    try {
      // Используем команду r a u для создания дампа
      final tempFile = File('${(await getTemporaryDirectory()).path}/card_dump_${DateTime.now().millisecondsSinceEpoch}.bin');
      
      final result = await Process.run(
        _nfcMfClassicPath,
        ['r', 'a', 'u', tempFile.path],
        environment: {'LIBNFC_DEVICE': 'pn532_uart:$_cachedComPort'},
        runInShell: true,
      );
      
      if (result.exitCode != 0) {
        _log.warning('Read dump failed: ${result.stderr}');
        return null;
      }
      
      if (!await tempFile.exists()) {
        _log.warning('Dump file not created');
        return null;
      }
      
      final bytes = await tempFile.readAsBytes();
      await tempFile.delete();
      
      final start = block * 16;
      if (bytes.length < start + 4) return null;
      
      final balance = bytes[start] | 
                      (bytes[start + 1] << 8) | 
                      (bytes[start + 2] << 16) | 
                      (bytes[start + 3] << 24);
      
      _log.info('✅ Balance read: $balance RUB');
      return balance;
    } catch (e) {
      _log.severe('Error reading balance: $e');
      return null;
    }
  }

  // ---- Запись баланса (используем команду w a u) ----
  Future<bool> writeBalance(String uid, int newBalance, {int block = 4, String key = 'FFFFFFFFFFFF'}) async {
    _log.info('Writing balance $newBalance to card UID: $uid');
    
    _cachedComPort ??= await _findComPort();
    if (_cachedComPort == null) {
      _log.severe('❌ COM port not configured');
      return false;
    }
    
    try {
      final tempFile = File('${(await getTemporaryDirectory()).path}/card_dump_${DateTime.now().millisecondsSinceEpoch}.bin');
      
      // 1. Читаем текущий дамп карты
      final readResult = await Process.run(
        _nfcMfClassicPath,
        ['r', 'a', 'u', tempFile.path],
        environment: {'LIBNFC_DEVICE': 'pn532_uart:$_cachedComPort'},
        runInShell: true,
      );
      
      if (readResult.exitCode != 0) {
        _log.warning('Failed to read card dump: ${readResult.stderr}');
        return false;
      }
      
      if (!await tempFile.exists()) {
        _log.warning('Dump file not created');
        return false;
      }
      
      // 2. Модифицируем баланс в дампе
      final bytes = await tempFile.readAsBytes();
      final start = block * 16;
      bytes[start] = newBalance & 0xFF;
      bytes[start + 1] = (newBalance >> 8) & 0xFF;
      bytes[start + 2] = (newBalance >> 16) & 0xFF;
      bytes[start + 3] = (newBalance >> 24) & 0xFF;
      await tempFile.writeAsBytes(bytes);
      
      // 3. Записываем дамп обратно на карту (команда w a u)
      final writeResult = await Process.run(
        _nfcMfClassicPath,
        ['w', 'a', 'u', tempFile.path],
        environment: {'LIBNFC_DEVICE': 'pn532_uart:$_cachedComPort'},
        runInShell: true,
      );
      
      await tempFile.delete();
      
      if (writeResult.exitCode == 0) {
        _log.info('✅ Balance written successfully: $newBalance RUB');
        return true;
      } else {
        _log.warning('Write failed: ${writeResult.stderr}');
        return false;
      }
    } catch (e) {
      _log.severe('Error writing balance: $e');
      return false;
    }
  }

  String? _parseUid(String output) {
    final lines = output.split('\n');
    for (final line in lines) {
      if (line.contains('UID (NFCID1):')) {
        final match = RegExp(r'UID \(NFCID1\):\s*([A-F0-9\s]+)', caseSensitive: false)
            .firstMatch(line);
        if (match != null) {
          return match.group(1)?.replaceAll(' ', '');
        }
      }
    }
    return null;
  }
}