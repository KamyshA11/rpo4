import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import '../services/storage_service.dart';
import 'package:logging/logging.dart';

class PaymentProvider extends ChangeNotifier {
  final Logger _log = Logger('PaymentProvider');
  final NfcService nfc = NfcService();
  final StorageService storage = StorageService();
  
  bool isProcessing = false;
  String? lastMessage;
  bool lastSuccess = false;
  
  // Статусы процесса
  String _statusMessage = '';
  String get statusMessage => _statusMessage;
  
  // Прогресс (0-100)
  double _progress = 0;
  double get progress => _progress;
  
  int _currentBalance = 0;
  String? _currentCardUid;

  int get balance => _currentBalance;
  String? get cardUid => _currentCardUid;

  Future<void> init() async {
    await storage.init();
  }

  void _updateStatus(String message, {double progressValue = -1}) {
    _statusMessage = message;
    if (progressValue >= 0) {
      _progress = progressValue;
    }
    _log.info(message);
    notifyListeners();
  }

  Future<void> pay(BuildContext context) async {
    if (isProcessing) {
      _log.warning('Already processing');
      return;
    }
    
    isProcessing = true;
    lastMessage = null;
    _updateStatus('🔄 Инициализация...', progressValue: 0);
    notifyListeners();

    try {
      // Шаг 1: Поиск NFC устройства
      _updateStatus('🔍 Поиск NFC устройства...', progressValue: 10);
      await Future.delayed(Duration(milliseconds: 500)); // даём время на инициализацию
      
      // Шаг 2: Ожидание карты
      _updateStatus('💳 Жду карту... Пожалуйста, приложите карту к считывателю', progressValue: 20);
      
      final uid = await nfc.detectCardUID(maxAttempts: 20); // увеличил попытки
      
      if (uid == null) {
        _updateStatus('❌ Не удалось обнаружить карту. Пожалуйста, попробуйте ещё раз', progressValue: 0);
        _setError('Карта не обнаружена. Убедитесь, что карта приложена к считывателю');
        return;
      }
      
      _currentCardUid = uid;
      _updateStatus('✅ Карта обнаружена! UID: $uid', progressValue: 40);
      await Future.delayed(Duration(milliseconds: 500));
      
      // Шаг 3: Чтение баланса с карты
      _updateStatus('📖 Чтение баланса с карты...', progressValue: 50);
      
      // Пробуем несколько раз прочитать баланс
      int? balance;
      int readAttempts = 0;
      while (balance == null && readAttempts < 3) {
        readAttempts++;
        _updateStatus('📖 Попытка чтения $readAttempts/3...', progressValue: 50 + (readAttempts * 5));
        balance = await nfc.readBalance(uid);
        if (balance == null && readAttempts < 3) {
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
      
      if (balance == null) {
        _updateStatus('❌ Не удалось прочитать баланс с карты', progressValue: 0);
        _setError('Не удалось прочитать баланс. Пожалуйста, попробуйте ещё раз');
        return;
      }
      
      _currentBalance = balance;
      _updateStatus('💰 Текущий баланс: $balance RUB', progressValue: 65);
      await Future.delayed(Duration(milliseconds: 500));
      
      // Шаг 4: Проверка баланса
      if (balance < 50) {
        _updateStatus('❌ Недостаточно средств. Баланс: $balance RUB', progressValue: 0);
        _setError('Недостаточно средств. Баланс: $balance RUB');
        return;
      }
      
      // Шаг 5: Запись нового баланса
      final newBalance = balance - 50;
      _updateStatus('✍️ Запись нового баланса ($newBalance RUB) на карту...', progressValue: 75);
      
      // Пробуем несколько раз записать
      bool writeSuccess = false;
      int writeAttempts = 0;
      while (!writeSuccess && writeAttempts < 3) {
        writeAttempts++;
        _updateStatus('✍️ Попытка записи $writeAttempts/3...', progressValue: 75 + (writeAttempts * 5));
        writeSuccess = await nfc.writeBalance(uid, newBalance);
        if (!writeSuccess && writeAttempts < 3) {
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
      
      if (!writeSuccess) {
        _updateStatus('❌ Не удалось записать данные на карту', progressValue: 0);
        _setError('Не удалось записать новый баланс. Пожалуйста, попробуйте ещё раз');
        return;
      }
      
      _currentBalance = newBalance;
      
      // Шаг 6: Сохранение транзакции
      _updateStatus('💾 Сохранение транзакции...', progressValue: 90);
      await storage.addTransaction(
        cardUid: uid,
        amount: 50,
        type: 'payment',
        success: true,
        balanceAfter: newBalance,
      );
      await storage.updateBalance(uid, newBalance);
      
      _updateStatus('✅ Оплата успешно завершена!', progressValue: 100);
      _setSuccess('Оплата успешно завершена!\nНовый баланс: $newBalance RUB');
      
      // Сброс прогресса через 3 секунды
      await Future.delayed(Duration(seconds: 3));
      _updateStatus('', progressValue: 0);
      
    } catch (e) {
      _updateStatus('❌ Ошибка: $e', progressValue: 0);
      _setError('Ошибка: $e');
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  void _setError(String msg) {
    lastMessage = msg;
    lastSuccess = false;
  }

  void _setSuccess(String msg) {
    lastMessage = msg;
    lastSuccess = true;
  }
}