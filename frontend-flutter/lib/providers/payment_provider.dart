import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import '../services/api_service.dart';
import 'package:logging/logging.dart';

class PaymentProvider extends ChangeNotifier {
  final Logger _log = Logger('PaymentProvider');
  final NfcService nfc = NfcService();
  final ApiService api = ApiService();
  
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

  Future<void> init() async {
    // Инициализация не требуется, JSON удалён
  }

  Future<void> pay(BuildContext context) async {
    if (isProcessing) return;
    
    isProcessing = true;
    lastMessage = null;
    _updateStatus('🔄 Инициализация...', progressValue: 0);
    notifyListeners();

    try {
      _updateStatus('🔍 Поиск NFC устройства...', progressValue: 10);
      await Future.delayed(const Duration(milliseconds: 500));
      
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
      
      // ПРОВЕРКА: есть ли карта в системе и не заблокирована ли она
      _updateStatus('🔍 Проверка карты в системе...', progressValue: 45);
      final card = await api.getCardByUid(uid);

      if (card == null) {
        _updateStatus('❌ Карта не зарегистрирована в системе', progressValue: 0);
        _setError('Карта не зарегистрирована в системе. Обратитесь в администрацию.');
        return;
      }

      if (card['blocked'] == true) {
        _updateStatus('❌ Карта заблокирована', progressValue: 0);
        _setError('Карта заблокирована. Обратитесь в администрацию.');
        return;
      }
      
      _updateStatus('📖 Чтение баланса с карты...', progressValue: 50);
      
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
        _updateStatus('❌ Не удалось прочитать баланс с карты', progressValue: 0);
        _setError('Не удалось прочитать баланс с карты');
        return;
      }
      
      _currentBalance = balance;
      _updateStatus('💰 Текущий баланс: $balance ₽', progressValue: 65);
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (balance < 50) {
        _updateStatus('❌ Недостаточно средств', progressValue: 0);
        _setError('Недостаточно средств. Баланс: $balance ₽');
        return;
      }
      
      final newBalance = balance - 50;
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
        _setError('Не удалось записать новый баланс на карту');
        return;
      }
      
      // После успешной записи на карту
      _currentBalance = newBalance;

      // СОХРАНЕНИЕ ТРАНЗАКЦИИ В БД
      _updateStatus('💾 Сохранение транзакции...', progressValue: 90);
      try {
          await api.pay(uid, 50, 1);
          _log.info('Transaction saved to backend');
      } catch (e) {
          _log.warning('Failed to save transaction: $e');
      }

      // СИНХРОНИЗАЦИЯ БАЛАНСА С БЭКЕНДОМ
      _updateStatus('🔄 Синхронизация баланса...', progressValue: 95);
      try {
          await api.syncBalance(uid, newBalance);
          _log.info('Balance synced with backend');
      } catch (e) {
          _log.warning('Failed to sync balance: $e');
      }

      _updateStatus('✅ Оплата успешно завершена!', progressValue: 100);
      _setSuccess('Оплата успешно завершена!\nНовый баланс: $newBalance ₽');
      
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