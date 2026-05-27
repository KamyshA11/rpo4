import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080/api/v1', // Или https://localhost:8888/api/v1
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  String? _token;

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        print('🌐 Request: ${options.method} ${options.path}');
        print('📦 Data: ${options.data}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ Response: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('❌ Error: ${error.response?.statusCode} - ${error.message}');
        if (error.response != null) {
          print('Response data: ${error.response?.data}');
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> login(String username, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'login': username,
      'password': password,
    });
    _token = response.data['token'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ==================== РАБОТА С КАРТАМИ ====================

  // Проверка существования карты по UID
  Future<bool> cardExists(String uid) async {
    try {
      await _dio.get('/cards/by-uid/${uid.toUpperCase()}');
      return true;
    } catch (e) {
      print('Card not found by UID: ${uid.toUpperCase()}');
      return false;
    }
  }

  // Получение карты по UID
  Future<Map<String, dynamic>?> getCardByUid(String uid) async {
    try {
      final response = await _dio.get('/cards/by-uid/${uid.toUpperCase()}');
      return response.data;
    } catch (e) {
      print('Card not found by UID: ${uid.toUpperCase()}');
      return null;
    }
  }

  // Регистрация новой карты
  Future<Map<String, dynamic>> registerCard(String uid, String ownerName, int initialBalance) async {
    final response = await _dio.post('/cards/register', data: {
      'uid': uid,
      'owner_name': ownerName,
      'balance': initialBalance,
    });
    return response.data;
  }

  // ==================== ОПЛАТА И ПОПОЛНЕНИЕ ====================

  // Оплата (создание транзакции) — используем эндпоинт /cards/debit
  Future<void> pay(String uid, int amount, int terminalId) async {
    final response = await _dio.post('/cards/debit', data: {
      'uid': uid,
      'amount': amount,
      'terminal_id': terminalId,
    });
    print('Payment response: ${response.data}');
  }

  // Пополнение (создание транзакции) — используем эндпоинт /cards/recharge
  Future<void> rechargeCard(String uid, int amount) async {
    final response = await _dio.post('/cards/recharge', data: {
      'uid': uid,
      'amount': amount,
    });
    print('Recharge response: ${response.data}');
  }

  // Синхронизация баланса с бэкендом
  Future<void> syncBalance(String uid, int balance) async {
    try {
      final response = await _dio.put('/cards/sync-balance', data: {
        'uid': uid,
        'balance': balance,
      });
      print('Sync balance response: ${response.data}');
    } catch (e) {
      print('Sync balance error: $e');
      // Не прерываем выполнение, так как это не критично
    }
  }

  // ==================== СТАРЫЕ МЕТОДЫ (для совместимости) ====================

  Future<Map<String, dynamic>> getCardByNumber(String cardNumber) async {
    final response = await _dio.get('/cards/by-number/$cardNumber');
    return response.data;
  }

  Future<void> authorizeTransaction(String cardNumber, int amount, int terminalId) async {
    await _dio.post('/terminals/authorize', data: {
      'card_number': cardNumber,
      'amount': amount,
      'terminal_id': terminalId,
    });
  }
}