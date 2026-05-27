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
              if (provider.isWaiting)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Place your card on reader...'),
                  ],
                ),
              if (!provider.isWaiting)
                ElevatedButton(
                  onPressed: provider.isProcessing ? null : () => provider.pay(context),
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