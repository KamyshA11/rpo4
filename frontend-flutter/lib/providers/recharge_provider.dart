import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import '../services/storage_service.dart';
import 'package:logging/logging.dart';

class RechargeProvider extends ChangeNotifier {
  final Logger _log = Logger('RechargeProvider');
  final NfcService nfc = NfcService();
  final StorageService storage = StorageService();
  final TextEditingController amountController = TextEditingController();
  
  bool isProcessing = false;
  String? lastMessage;
  bool lastSuccess = false;
  
  // Новые поля для статуса и прогресса
  String _statusMessage = '';
  double _progress = 0;
  
  int _currentBalance = 0;
  String? _currentCardUid;

  // Геттеры
  int get balance => _currentBalance;
  String? get cardUid => _currentCardUid;
  String get statusMessage => _statusMessage;
  double get progress => _progress;

  void _updateStatus(String message, {double progressValue = -1}) {
    _statusMessage = message;
    if (progressValue >= 0) {
      _progress = progressValue;
    }
    _log.info(message);
    notifyListeners();
  }

  Future<void> init() async {
    await storage.init();
  }

  Future<void> recharge(BuildContext context) async {
    final amount = int.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      _setError('Введите корректную сумму');
      return;
    }

    if (isProcessing) return;
    
    isProcessing = true;
    lastMessage = null;
    _updateStatus('🔄 Инициализация...', progressValue: 0);
    notifyListeners();

    try {
      // Шаг 1: Поиск устройства
      _updateStatus('🔍 Поиск NFC устройства...', progressValue: 10);
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Шаг 2: Ожидание карты
      _updateStatus('💳 Приложите карту к считывателю...', progressValue: 20);
      
      final uid = await nfc.detectCardUID(maxAttempts: 20);
      
      if (uid == null) {
        _updateStatus('❌ Карта не обнаружена', progressValue: 0);
        _setError('Карта не обнаружена. Пожалуйста, попробуйте ещё раз');
        return;
      }
      
      _currentCardUid = uid;
      _updateStatus('✅ Карта обнаружена! UID: $uid', progressValue: 40);
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Шаг 3: Чтение баланса
      _updateStatus('📖 Чтение текущего баланса...', progressValue: 50);
      
      int? balance;
      int readAttempts = 0;
      while (balance == null && readAttempts < 3) {
        readAttempts++;
        _updateStatus('📖 Попытка чтения $readAttempts/3...', progressValue: 50 + (readAttempts * 5));
        balance = await nfc.readBalance(uid);
        if (balance == null && readAttempts < 3) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      if (balance == null) {
        _updateStatus('❌ Не удалось прочитать баланс', progressValue: 0);
        _setError('Не удалось прочитать баланс. Пожалуйста, попробуйте ещё раз');
        return;
      }
      
      _currentBalance = balance;
      _updateStatus('💰 Текущий баланс: $balance ₽', progressValue: 65);
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Шаг 4: Запись нового баланса
      final newBalance = balance + amount;
      _updateStatus('✍️ Запись нового баланса ($newBalance ₽) на карту...', progressValue: 75);
      
      bool writeSuccess = false;
      int writeAttempts = 0;
      while (!writeSuccess && writeAttempts < 3) {
        writeAttempts++;
        _updateStatus('✍️ Попытка записи $writeAttempts/3...', progressValue: 75 + (writeAttempts * 5));
        writeSuccess = await nfc.writeBalance(uid, newBalance);
        if (!writeSuccess && writeAttempts < 3) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      if (!writeSuccess) {
        _updateStatus('❌ Не удалось записать данные на карту', progressValue: 0);
        _setError('Не удалось записать новый баланс. Пожалуйста, попробуйте ещё раз');
        return;
      }
      
      _currentBalance = newBalance;
      
      // Шаг 5: Сохранение транзакции
      _updateStatus('💾 Сохранение транзакции...', progressValue: 90);
      await storage.addTransaction(
        cardUid: uid,
        amount: amount,
        type: 'recharge',
        success: true,
        balanceAfter: newBalance,
      );
      await storage.updateBalance(uid, newBalance);
      
      _updateStatus('✅ Пополнение успешно завершено!', progressValue: 100);
      _setSuccess('Пополнение успешно завершено!\nНовый баланс: $newBalance ₽');
      amountController.clear();
      
      // Сброс прогресса через 3 секунды
      await Future.delayed(const Duration(seconds: 3));
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