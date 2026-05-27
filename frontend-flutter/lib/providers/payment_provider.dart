import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import '../services/storage_service.dart';
import 'package:logging/logging.dart';

class PaymentProvider extends ChangeNotifier {
  final Logger _log = Logger('PaymentProvider');
  final NfcService nfc = NfcService();
  final StorageService storage = StorageService();
  
  bool isWaiting = false;
  bool isProcessing = false;
  String? lastMessage;
  bool lastSuccess = false;
  
  int _currentBalance = 0;
  String? _currentCardUid;

  int get balance => _currentBalance;
  String? get cardUid => _currentCardUid;

  Future<void> init() async {
    await storage.init();
  }

  Future<void> pay(BuildContext context) async {
    isProcessing = true;
    lastMessage = null;
    notifyListeners();

    try {
      // 1. Ожидание карты
      isWaiting = true;
      notifyListeners();
      final uid = await nfc.detectCardUID(maxAttempts: 30);
      isWaiting = false;
      
      if (uid == null) {
        _setError('Card not detected. Please try again.');
        return;
      }
      
      _currentCardUid = uid;
      
      // 2. Читаем баланс с карты
      final balance = await nfc.readBalance(uid);
      if (balance == null) {
        _setError('Failed to read card balance');
        return;
      }
      
      _currentBalance = balance;
      _log.info('Current balance: $balance RUB');
      
      // 3. Проверка баланса
      if (balance < 50) {
        _setError('Insufficient funds. Balance: $balance RUB');
        return;
      }
      
      // 4. Списываем деньги
      final newBalance = balance - 50;
      final success = await nfc.writeBalance(uid, newBalance);
      
      if (!success) {
        _setError('Failed to write new balance to card');
        return;
      }
      
      _currentBalance = newBalance;
      
      // 5. Сохраняем транзакцию в JSON (для истории)
      await storage.addTransaction(
        cardUid: uid,
        amount: 50,
        type: 'payment',
        success: true,
        balanceAfter: newBalance,
      );
      
      // 6. Обновляем баланс в JSON (для быстрого доступа, опционально)
      await storage.updateBalance(uid, newBalance);
      
      _setSuccess('Payment successful!\nNew balance: $newBalance RUB');
    } catch (e) {
      _setError('Error: $e');
    } finally {
      isWaiting = false;
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