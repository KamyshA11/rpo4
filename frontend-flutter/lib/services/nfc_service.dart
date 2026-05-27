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
  final String _comPort = 'COM14';
  String? _cachedComPort;

  Future<String?> _findComPort() async {
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

  // ---- Чтение всего дампа карты во временный файл ----
  Future<File?> _dumpCardToFile(String uid, String key, String comPort) async {
    final tempDir = await getTemporaryDirectory();
    final dumpFile = File('${tempDir.path}/card_dump_${DateTime.now().millisecondsSinceEpoch}.bin');
    
    final result = await Process.run(
      _nfcMfClassicPath,
      ['r', uid, '4', key],
      environment: {'LIBNFC_DEVICE': 'pn532_uart:$comPort'},
      runInShell: true,
    );
    
    if (result.exitCode != 0) {
      _log.warning('Dump failed: ${result.stderr}');
      return null;
    }
    
    // Утилита создаёт файл с именем ключа (FFFFFFFFFFFF) в текущей папке
    // Нужно найти этот файл и переместить
    final generatedFile = File('FFFFFFFFFFF'); // имя файла по умолчанию
    
    // Проверяем разные возможные имена
    final possiblePaths = [
      'FFFFFFFFFFFF',
      'FFFFFFFFFFF',
      '${Directory.current.path}/FFFFFFFFFFFF',
      '${Directory.current.path}/FFFFFFFFFFF',
    ];
    
    File? sourceFile;
    for (final path in possiblePaths) {
      final f = File(path);
      if (await f.exists()) {
        sourceFile = f;
        break;
      }
    }
    
    if (sourceFile == null) {
      _log.warning('Dump file not found');
      return null;
    }
    
    // Копируем во временный файл
    await sourceFile.copy(dumpFile.path);
    await sourceFile.delete(); // удаляем оригинал
    
    return dumpFile;
  }

  // ---- Запись дампа на карту ----
  Future<bool> _writeDumpToCard(String uid, String key, String comPort, File dumpFile) async {
    final result = await Process.run(
      _nfcMfClassicPath,
      ['w', uid, '4', key, dumpFile.path],
      environment: {'LIBNFC_DEVICE': 'pn532_uart:$comPort'},
      runInShell: true,
    );
    
    if (result.exitCode != 0) {
      _log.warning('Write failed: ${result.stderr}');
      return false;
    }
    
    return true;
  }

  // ---- Чтение баланса из дампа ----
  Future<int?> readBalance(String uid, {int block = 4, String key = 'FFFFFFFFFFFF'}) async {
    _log.info('Reading balance from card UID: $uid');
    
    _cachedComPort ??= await _findComPort();
    if (_cachedComPort == null) {
      _log.severe('❌ COM port not configured');
      return null;
    }
    
    try {
      // 1. Создаём дамп карты
      final dumpFile = await _dumpCardToFile(uid, key, _cachedComPort!);
      if (dumpFile == null) {
        _log.warning('Failed to create card dump');
        return null;
      }
      
      // 2. Читаем файл
      final bytes = await dumpFile.readAsBytes();
      
      // 3. Удаляем временный файл
      await dumpFile.delete();
      
      // 4. Проверяем размер
      if (bytes.length < (block + 1) * 16) {
        _log.warning('Dump file too small: ${bytes.length} bytes');
        return null;
      }
      
      // 5. Берём нужный блок (смещение block * 16)
      final start = block * 16;
      final balanceBytes = bytes.sublist(start, start + 4);
      
      // 6. Парсим little-endian
      final balance = balanceBytes[0] | 
                      (balanceBytes[1] << 8) | 
                      (balanceBytes[2] << 16) | 
                      (balanceBytes[3] << 24);
      
      _log.info('✅ Balance read: $balance RUB');
      return balance;
    } catch (e) {
      _log.severe('Error reading balance: $e');
      return null;
    }
  }

  // ---- Запись баланса на карту (через дамп) ----
  Future<bool> writeBalance(String uid, int newBalance, {int block = 4, String key = 'FFFFFFFFFFFF'}) async {
    _log.info('Writing balance $newBalance to card UID: $uid');
    
    _cachedComPort ??= await _findComPort();
    if (_cachedComPort == null) {
      _log.severe('❌ COM port not configured');
      return false;
    }
    
    try {
      // 1. Создаём дамп карты
      final dumpFile = await _dumpCardToFile(uid, key, _cachedComPort!);
      if (dumpFile == null) {
        _log.warning('Failed to create card dump');
        return false;
      }
      
      // 2. Читаем текущий дамп
      final bytes = await dumpFile.readAsBytes();
      
      // 3. Обновляем баланс в нужном блоке
      final start = block * 16;
      bytes[start] = newBalance & 0xFF;
      bytes[start + 1] = (newBalance >> 8) & 0xFF;
      bytes[start + 2] = (newBalance >> 16) & 0xFF;
      bytes[start + 3] = (newBalance >> 24) & 0xFF;
      
      // 4. Сохраняем изменённый дамп
      await dumpFile.writeAsBytes(bytes);
      
      // 5. Записываем дамп обратно на карту
      final success = await _writeDumpToCard(uid, key, _cachedComPort!, dumpFile);
      
      // 6. Удаляем временный файл
      await dumpFile.delete();
      
      if (success) {
        _log.info('✅ Balance written successfully: $newBalance RUB');
      } else {
        _log.warning('Failed to write balance to card');
      }
      
      return success;
    } catch (e) {
      _log.severe('Error writing balance: $e');
      return false;
    }
  }

  // ---- Парсинг UID из вывода nfc-list ----
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