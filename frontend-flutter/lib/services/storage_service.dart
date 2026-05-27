import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  late File _storageFile;
  Map<String, dynamic> _data = {};
  
  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _storageFile = File('${directory.path}/cards_data.json');
    
    if (await _storageFile.exists()) {
      final content = await _storageFile.readAsString();
      _data = jsonDecode(content);
      print('✅ Data loaded from: ${_storageFile.path}');
    } else {
      // Создаём начальные данные
      _data = {
        'cards': [],
        'transactions': [],
      };
      await _save();
      print('✅ New data file created at: ${_storageFile.path}');
    }
  }
  
  Future<void> _save() async {
    await _storageFile.writeAsString(jsonEncode(_data));
  }
  
  // ---- Работа с картами ----
  List<Map<String, dynamic>> get cards {
    return List<Map<String, dynamic>>.from(_data['cards'] ?? []);
  }
  
  Map<String, dynamic>? getCardByUid(String uid) {
    try {
      return cards.firstWhere((card) => card['uid'] == uid);
    } catch (e) {
      return null;
    }
  }
  
  Future<Map<String, dynamic>> addCard(String uid, String ownerName, {int initialBalance = 500, int keyId = 1}) async {
    final newCard = {
      'uid': uid,
      'ownerName': ownerName,
      'balance': initialBalance,
      'status': 'active',
      'keyId': keyId,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _data['cards'].add(newCard);
    await _save();
    return newCard;
  }
  
  Future<int?> getBalance(String uid) async {
    final card = getCardByUid(uid);
    return card?['balance'] as int?;
  }
  
  Future<bool> updateBalance(String uid, int newBalance) async {
    final index = cards.indexWhere((card) => card['uid'] == uid);
    if (index == -1) return false;
    
    _data['cards'][index]['balance'] = newBalance;
    await _save();
    return true;
  }
  
  Future<bool> updateCardStatus(String uid, String status) async {
    final index = cards.indexWhere((card) => card['uid'] == uid);
    if (index == -1) return false;
    
    _data['cards'][index]['status'] = status;
    await _save();
    return true;
  }
  
  // ---- Работа с транзакциями ----
  Future<void> addTransaction({
    required String cardUid,
    required int amount,
    required String type, // 'payment' или 'recharge'
    required bool success,
    required int balanceAfter,
  }) async {
    final transaction = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'cardUid': cardUid,
      'amount': amount,
      'type': type,
      'success': success,
      'balanceAfter': balanceAfter,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _data['transactions'].add(transaction);
    await _save();
  }
  
  List<Map<String, dynamic>> getTransactionsForCard(String uid) {
    return List<Map<String, dynamic>>.from(
      _data['transactions']?.where((tx) => tx['cardUid'] == uid) ?? []
    );
  }
  
  List<Map<String, dynamic>> getAllTransactions() {
    return List<Map<String, dynamic>>.from(_data['transactions'] ?? []);
  }
  
  // ---- Получение всех данных (для отладки) ----
  Map<String, dynamic> getAllData() {
    return Map.from(_data);
  }
}