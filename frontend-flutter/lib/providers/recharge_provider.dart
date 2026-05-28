import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import '../services/api_service.dart';
import 'package:logging/logging.dart';

class RechargeProvider extends ChangeNotifier {
  final Logger _log = Logger('RechargeProvider');
  final NfcService nfc = NfcService();
  final ApiService api = ApiService();
  final TextEditingController amountController = TextEditingController();
  
  bool isProcessing = false;
  String? lastMessage;
  bool lastSuccess = false;
  
  String _statusMessage = '';
  double _progress = 0;
  
  int _currentBalance = 0;
  String? _currentCardUid;

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

  Future<void> recharge(BuildContext context) async {
    final amount = int.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      _setError('Введите корректную сумму');
      return;
    }

    if (isProcessing) return;
    
    isProcessing = true;
    lastMessage = null;
    _updateStatus('Инициализация...', progressValue: 0);
    notifyListeners();

    try {
      _updateStatus('Поиск NFC устройства...', progressValue: 10);
      await Future.delayed(const Duration(milliseconds: 500));
      
      _updateStatus('Приложите карту к считывателю...', progressValue: 20);
      
      final uid = await nfc.detectCardUID(maxAttempts: 20);
      
      if (uid == null) {
        _updateStatus('Ошибка: карта не обнаружена', progressValue: 0);
        _setError('Карта не обнаружена');
        return;
      }
      
      _currentCardUid = uid;
      _updateStatus('Карта обнаружена (UID: $uid)', progressValue: 40);
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Проверка карты в системе
      _updateStatus('Проверка карты в системе...', progressValue: 45);
      final card = await api.getCardByUid(uid);

      if (card == null) {
        _updateStatus('Ошибка: карта не зарегистрирована', progressValue: 0);
        _setError('Карта не зарегистрирована в системе. Обратитесь в администрацию.');
        return;
      }

      if (card['blocked'] == true) {
        _updateStatus('Ошибка: карта заблокирована', progressValue: 0);
        _setError('Карта заблокирована. Обратитесь в администрацию.');
        return;
      }
      
      _updateStatus('Чтение текущего баланса...', progressValue: 50);
      
      int? currentBalance;
      int readAttempts = 0;
      while (currentBalance == null && readAttempts < 3) {
        readAttempts++;
        _updateStatus('Попытка чтения $readAttempts/3...', progressValue: 50 + (readAttempts * 5));
        currentBalance = await nfc.readBalance(uid);
        if (currentBalance == null && readAttempts < 3) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      if (currentBalance == null) {
        _updateStatus('Ошибка: не удалось прочитать баланс', progressValue: 0);
        _setError('Не удалось прочитать баланс');
        return;
      }
      
      _currentBalance = currentBalance;
      _updateStatus('Текущий баланс: $currentBalance ₽', progressValue: 65);
      await Future.delayed(const Duration(milliseconds: 500));
      
      final newBalance = currentBalance + amount;
      _updateStatus('Запись нового баланса ($newBalance ₽) на карту...', progressValue: 75);
      
      bool writeSuccess = false;
      int writeAttempts = 0;
      while (!writeSuccess && writeAttempts < 3) {
        writeAttempts++;
        _updateStatus('Попытка записи $writeAttempts/3...', progressValue: 75 + (writeAttempts * 5));
        writeSuccess = await nfc.writeBalance(uid, newBalance);
        if (!writeSuccess && writeAttempts < 3) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      if (!writeSuccess) {
        _updateStatus('Ошибка: не удалось записать баланс', progressValue: 0);
        _setError('Не удалось записать новый баланс');
        return;
      }
      
      _currentBalance = newBalance;

      // Отправка на бэкенд
      _updateStatus('Отправка данных на сервер...', progressValue: 95);
      try {
          await api.rechargeCard(uid, amount, 1);
          _log.info('Recharge sent to backend');
      } catch (e) {
          _log.warning('Failed to send to backend: $e');
      }

      // Синхронизация баланса
      _updateStatus('Синхронизация баланса...', progressValue: 98);
      try {
          await api.syncBalance(uid, newBalance);
          _log.info('Balance synced with backend');
      } catch (e) {
          _log.warning('Failed to sync balance: $e');
      }

      _updateStatus('Пополнение успешно завершено', progressValue: 100);
      _setSuccess('Пополнение успешно завершено!\nНовый баланс: $newBalance ₽');
      amountController.clear();
      
      await Future.delayed(const Duration(seconds: 3));
      _updateStatus('', progressValue: 0);
      
    } catch (e) {
      _updateStatus('Ошибка: $e', progressValue: 0);
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