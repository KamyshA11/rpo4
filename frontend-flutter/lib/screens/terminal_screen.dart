import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';

class TerminalScreen extends StatelessWidget {
  const TerminalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Terminal'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Fixed fare: 50 RUB',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                'Current balance: ${provider.balance} RUB',
                style: const TextStyle(fontSize: 18, color: Colors.green),
              ),
              const SizedBox(height: 40),
              
              // Статус и прогресс
              if (provider.statusMessage.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (provider.statusMessage.contains('✅'))
                            const Icon(Icons.check_circle, color: Colors.green)
                          else if (provider.statusMessage.contains('❌'))
                            const Icon(Icons.error, color: Colors.red)
                          else if (provider.statusMessage.contains('💳') || 
                                   provider.statusMessage.contains('📖') || 
                                   provider.statusMessage.contains('✍️'))
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            const Icon(Icons.info, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              provider.statusMessage,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      if (provider.progress > 0 && provider.progress < 100) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: provider.progress / 100),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.progress.toInt()}%',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              if (!provider.isProcessing)
                ElevatedButton(
                  onPressed: () => provider.pay(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  ),
                  child: const Text('Pay 50 RUB', style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
              
              if (provider.lastMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    provider.lastMessage!,
                    style: TextStyle(
                      color: provider.lastSuccess ? Colors.green : Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}