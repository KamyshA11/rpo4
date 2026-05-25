import 'dart:async';
import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import '../services/api_service.dart';

class PaymentProvider extends ChangeNotifier {
  final NfcService nfc = NfcService();
  final ApiService api = ApiService();
  bool isWaiting = false;
  bool isProcessing = false;
  String? lastMessage;
  bool lastSuccess = false;

  Future<void> pay(BuildContext context) async {
    isProcessing = true;
    lastMessage = null;
    notifyListeners();

    try {
      // 1. Ожидание карты
      isWaiting = true;
      notifyListeners();
      final uid = await nfc.detectCardUID(timeout: Duration(seconds: 10));
      isWaiting = false;
      if (uid == null) {
        _setError('Card not detected. Please try again.');
        return;
      }

      // 2. Чтение баланса с карты (используем ключ по умолчанию, можно получить с сервера)
      const key = 'FFFFFFFFFFFF';
      final balance = await nfc.readBalance(uid, key, 4);
      if (balance == null) {
        _setError('Failed to read card balance');
        return;
      }

      if (balance < 50) {
        _setError('Insufficient funds. Balance: ${balance} RUB');
        return;
      }

      // 3. Списание с карты
      final newBalance = balance - 50;
      final success = await nfc.writeBalance(uid, key, 4, newBalance);
      if (!success) {
        _setError('Failed to update card balance');
        return;
      }

      // 4. Отправка транзакции на сервер (карта существует, передаём её номер)
      // Для простоты используем UID как номер карты. У вас может быть другое соответствие.
      await api.authorizeTransaction(uid, 50, 1); // terminalId = 1
      _setSuccess('Payment successful! New balance: ${newBalance} RUB');
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