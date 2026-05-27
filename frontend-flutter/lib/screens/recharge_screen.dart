import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recharge_provider.dart';

class RechargeScreen extends StatelessWidget {
  const RechargeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RechargeProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recharge Card'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Current balance: ${provider.balance} RUB',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: provider.amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (RUB)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (provider.isWaiting)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: provider.isProcessing ? null : () => provider.recharge(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text('Recharge', style: TextStyle(fontSize: 18, color: Colors.white)),
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
                ),
              ),
          ],
        ),
      ),
    );
  }
}