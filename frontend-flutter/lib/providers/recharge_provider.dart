import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import '../services/api_service.dart';

class RechargeProvider extends ChangeNotifier {
  final NfcService nfc = NfcService();
  final ApiService api = ApiService();
  final TextEditingController amountController = TextEditingController();
  bool isWaiting = false;
  bool isProcessing = false;
  String? lastMessage;
  bool lastSuccess = false;

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
      isWaiting = true;
      notifyListeners();
      final uid = await nfc.detectCardUID(timeout: Duration(seconds: 10));
      isWaiting = false;
      if (uid == null) {
        _setError('Card not detected');
        return;
      }

      const key = 'FFFFFFFFFFFF';
      final currentBalance = await nfc.readBalance(uid, key, 4);
      if (currentBalance == null) {
        _setError('Failed to read card balance');
        return;
      }

      final newBalance = currentBalance + amount;
      final success = await nfc.writeBalance(uid, key, 4, newBalance);
      if (!success) {
        _setError('Failed to write new balance');
        return;
      }

      await api.rechargeCard(uid, amount); // вызов API для логирования
      _setSuccess('Recharged successfully! New balance: ${newBalance} RUB');
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