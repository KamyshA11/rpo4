import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import '../services/storage_service.dart';
import 'package:logging/logging.dart';

class RechargeProvider extends ChangeNotifier {
  final Logger _log = Logger('RechargeProvider');
  final NfcService nfc = NfcService();
  final StorageService storage = StorageService();
  final TextEditingController amountController = TextEditingController();
  
  bool isWaiting = false;
  bool isProcessing = false;
  String? lastMessage;
  bool lastSuccess = false;
  
  int _currentBalance = 0;
  String? _currentCardUid;

  int get balance => _currentBalance;
  String? get cardUid => _currentCardUid;

  Future<void> recharge(BuildContext context) async {
    final amount = int.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      _setError('Enter valid amount');
      return;
    }

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
        _setError('Card not detected');
        return;
      }
      
      _currentCardUid = uid;
      
      // 2. Читаем текущий баланс с карты
      final currentBalance = await nfc.readBalance(uid);
      if (currentBalance == null) {
        _setError('Failed to read card balance');
        return;
      }
      
      _currentBalance = currentBalance;
      _log.info('Current balance: $currentBalance RUB');
      
      // 3. Пополняем карту
      final newBalance = currentBalance + amount;
      final success = await nfc.writeBalance(uid, newBalance);
      
      if (!success) {
        _setError('Failed to write new balance');
        return;
      }
      
      _currentBalance = newBalance;
      
      // 4. Сохраняем транзакцию в JSON (для истории)
      await storage.addTransaction(
        cardUid: uid,
        amount: amount,
        type: 'recharge',
        success: true,
        balanceAfter: newBalance,
      );
      
      // 5. Обновляем баланс в JSON (для быстрого доступа, опционально)
      await storage.updateBalance(uid, newBalance);
      
      _setSuccess('Recharged successfully!\nNew balance: $newBalance RUB');
      amountController.clear();
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