import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  String? _token;
  late HttpClient _client;

  ApiService() {
    _initClient();
  }

  Future<void> _initClient() async {
    try {
      final certData = await rootBundle.load('assets/cert.pem');
      final securityContext = SecurityContext();
      securityContext.setTrustedCertificatesBytes(certData.buffer.asUint8List());
      
      _client = HttpClient(context: securityContext);
      _client.badCertificateCallback = (cert, host, port) => host == 'localhost';
    } catch (e) {
      print('⚠️ Certificate not found, using default client');
      _client = HttpClient();
      _client.badCertificateCallback = (cert, host, port) => host == 'localhost';
    }
  }

  Future<Map<String, dynamic>?> _request(String method, String path, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('https://localhost:8888/api/v1$path');
      HttpClientRequest request;
      
      if (method == 'GET') {
        request = await _client.getUrl(uri);
      } else if (method == 'POST') {
        request = await _client.postUrl(uri);
      } else if (method == 'PUT') {
        request = await _client.putUrl(uri);
      } else {
        throw Exception('Unsupported method: $method');
      }
      
      if (_token != null) {
        request.headers.set('Authorization', 'Bearer $_token');
      }
      
      if (body != null) {
        request.headers.set('Content-Type', 'application/json');
        request.write(jsonEncode(body));
      }
      
      final response = await request.close();
      final data = await response.transform(utf8.decoder).join();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data.isNotEmpty) {
          return jsonDecode(data);
        }
        return {};
      }
      print('❌ ${method} $path failed: ${response.statusCode} - $data');
      return null;
    } catch (e) {
      print('❌ ${method} $path error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> get(String path) => _request('GET', path);
  Future<Map<String, dynamic>?> post(String path, Map<String, dynamic> body) => _request('POST', path, body: body);
  Future<Map<String, dynamic>?> put(String path, Map<String, dynamic> body) => _request('PUT', path, body: body);

  Future<void> login(String username, String password) async {
    final result = await post('/auth/login', {
      'login': username,
      'password': password,
    });
    if (result != null && result['token'] != null) {
      _token = result['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
    }
  }

  Future<bool> cardExists(String uid) async {
    final result = await get('/cards/by-uid/${uid.toUpperCase()}');
    return result != null;
  }

  Future<Map<String, dynamic>?> getCardByUid(String uid) async {
    return await get('/cards/by-uid/${uid.toUpperCase()}');
  }

  Future<void> pay(String uid, int amount, int terminalId) async {
    await post('/cards/debit', {
      'number': uid.toUpperCase(),
      'amount': amount,
      'terminal_id': terminalId,
    });
  }

  Future<void> debitCard(String number, int amount, int terminalId) async {
    await post('/cards/debit', {
      'number': number.toUpperCase(),
      'amount': amount,
      'terminal_id': terminalId,
    });
  }

  Future<void> rechargeCard(String number, int amount) async {
    await post('/cards/recharge', {
      'number': number.toUpperCase(),
      'amount': amount,
    });
  }

  Future<void> syncBalance(String number, int balance) async {
    await put('/cards/sync-balance', {
      'number': number.toUpperCase(),
      'balance': balance,
    });
  }
}