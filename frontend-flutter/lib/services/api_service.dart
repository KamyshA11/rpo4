import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
  String? _token;

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) options.headers['Authorization'] = 'Bearer $_token';
        return handler.next(options);
      },
    ));
  }

  Future<void> login(String username, String password) async {
    final response = await _dio.post('/auth/login', data: {'login': username, 'password': password});
    _token = response.data['token'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
  }

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

  Future<void> rechargeCard(String cardNumber, int amount) async {
    await _dio.post('/terminals/recharge', data: {
      'card_number': cardNumber,
      'amount': amount,
    });
  }
}