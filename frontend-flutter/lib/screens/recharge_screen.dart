import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recharge_provider.dart';

class RechargeScreen extends StatelessWidget {
  const RechargeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RechargeProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('Recharge Card'), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: provider.amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (RUB)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            if (provider.isWaiting)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: provider.isProcessing ? null : () => provider.recharge(context),
                child: Text('Recharge', style: TextStyle(fontSize: 18)),
              ),
            if (provider.lastMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(provider.lastMessage!, style: TextStyle(color: provider.lastSuccess ? Colors.green : Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}