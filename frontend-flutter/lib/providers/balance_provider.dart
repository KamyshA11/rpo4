import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import '../services/api_service.dart';
import 'package:logging/logging.dart';

class BalanceProvider extends ChangeNotifier {
  final Logger _log = Logger('BalanceProvider');
  final NfcService nfc = NfcService();
  final ApiService api = ApiService();
  
  bool isChecking = false;
  int _balance = 0;
  String? _cardUid;
  String _statusMessage = '';
  
  int get balance => _balance;
  String? get cardUid => _cardUid;
  String get statusMessage => _statusMessage;

  Future<void> checkBalance(BuildContext context) async {
    if (isChecking) return;
    
    isChecking = true;
    _statusMessage = '🔍 Поиск NFC устройства...';
    notifyListeners();

    try {
      _statusMessage = '💳 Приложите карту к считывателю...';
      notifyListeners();
      
      final uid = await nfc.detectCardUID(maxAttempts: 20);
      
      if (uid == null) {
        _statusMessage = '❌ Карта не обнаружена';
        _balance = 0;
        _cardUid = null;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 2));
        _statusMessage = '';
        notifyListeners();
        return;
      }
      
      _cardUid = uid;
      
      // ПРОВЕРКА: есть ли карта в системе
      _statusMessage = '🔍 Проверка карты в системе...';
      notifyListeners();

      final card = await api.getCardByUid(uid);
      if (card == null) {
        _statusMessage = '❌ Карта не зарегистрирована в системе';
        _balance = 0;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 2));
        _statusMessage = '';
        notifyListeners();
        return;
      }

      if (card['blocked'] == true) {
        _statusMessage = '❌ Карта заблокирована';
        _balance = 0;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 2));
        _statusMessage = '';
        notifyListeners();
        return;
      }
      
      _statusMessage = '📖 Чтение баланса с карты...';
      notifyListeners();
      
      final balance = await nfc.readBalance(uid);
      
      if (balance == null) {
        _statusMessage = '❌ Не удалось прочитать баланс';
        _balance = 0;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 2));
        _statusMessage = '';
        notifyListeners();
        return;
      }
      
      _balance = balance;
      _statusMessage = '✅ Баланс успешно считан!';
      notifyListeners();
      
      // Синхронизация с бэкендом (опционально)
      try {
        await api.syncBalance(uid, balance);
        _log.info('Balance synced with backend');
      } catch (e) {
        _log.warning('Failed to sync balance: $e');
      }
      
      await Future.delayed(const Duration(seconds: 2));
      _statusMessage = '';
      notifyListeners();
      
    } catch (e) {
      _statusMessage = '❌ Ошибка: $e';
      _balance = 0;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 2));
      _statusMessage = '';
      notifyListeners();
    } finally {
      isChecking = false;
      notifyListeners();
    }
  }
}