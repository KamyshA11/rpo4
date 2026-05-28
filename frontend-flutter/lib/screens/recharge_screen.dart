import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recharge_provider.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final TextEditingController _amountController = TextEditingController();
  
  // Список быстрых сумм для пополнения
  final List<int> quickAmounts = [50, 100, 200, 500, 1000, 2500];
  
  @override
  void initState() {
    super.initState();
    // При создании экрана очищаем поле
    _amountController.clear();
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RechargeProvider>();
    
    // Синхронизируем контроллер с провайдером
    if (provider.amountController.text != _amountController.text) {
      _amountController.text = provider.amountController.text;
    }
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade800,
              Colors.green.shade500,
              Colors.teal.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        // При уходе с экрана очищаем поле
                        provider.amountController.clear();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Spacer(),
                    const Text(
                      'Пополнение',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              
              // Баланс
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Текущий баланс:',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                    Text(
                      '${provider.balance} ₽',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Поле ввода суммы
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  onChanged: (value) {
                    provider.amountController.text = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'Сумма пополнения (₽)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'Введите сумму или выберите ниже',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.currency_ruble, color: Colors.white, size: 20),
                  ),
                ),
              ),
              
              // Быстрые кнопки
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Быстрое пополнение:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Используем Wrap с фиксированной шириной
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: quickAmounts.map((amount) {
                        // Вычисляем ширину кнопки в зависимости от экрана
                        final screenWidth = MediaQuery.of(context).size.width;
                        final buttonWidth = (screenWidth - 64) / 3; // 3 кнопки в строке с отступами
                        
                        return SizedBox(
                          width: buttonWidth,
                          child: ElevatedButton(
                            onPressed: provider.isProcessing ? null : () {
                              _amountController.text = amount.toString();
                              provider.amountController.text = amount.toString();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: Colors.white.withOpacity(0.5)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(
                              '+$amount ₽',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Статус процесса
              if (provider.statusMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      if (provider.statusMessage.contains('успешно'))
                        Icon(Icons.check_circle, color: Colors.green, size: 20)
                      else if (provider.statusMessage.contains('Ошибка') || provider.statusMessage.contains('ошибка'))
                        Icon(Icons.error, color: Colors.red, size: 20)
                      else if (provider.statusMessage.contains('Поиск') || 
                               provider.statusMessage.contains('Приложите') || 
                               provider.statusMessage.contains('Чтение') ||
                               provider.statusMessage.contains('Запись'))
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(Icons.info, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.statusMessage,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Кнопка пополнения
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: provider.isProcessing ? null : () async {
                    await provider.recharge(context);
                    // После успешной операции очищаем поле
                    if (provider.lastSuccess == true) {
                      _amountController.clear();
                      provider.amountController.clear();
                    }
                  },
                  icon: Icon(Icons.add_card, size: 20),
                  label: const Text('Пополнить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade700,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
              
              // Сообщение
              if (provider.lastMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (provider.lastSuccess ? Colors.green : Colors.red).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          provider.lastSuccess ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.lastMessage!,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}