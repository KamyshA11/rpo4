import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nfc_service.dart';
import '../services/api_service.dart';
import '../providers/payment_provider.dart';

class TerminalScreen extends StatelessWidget {
  const TerminalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('Payment Terminal'), backgroundColor: Colors.blue),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Fixed fare: 50 RUB', style: TextStyle(fontSize: 24)),
            SizedBox(height: 40),
            if (provider.isWaiting)
              Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Place your card on reader...'),
                ],
              ),
            if (!provider.isWaiting)
              ElevatedButton(
                onPressed: provider.isProcessing ? null : () => provider.pay(context),
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
                child: Text('Pay 50 RUB', style: TextStyle(fontSize: 20)),
              ),
            if (provider.lastMessage != null)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(provider.lastMessage!, style: TextStyle(color: provider.lastSuccess ? Colors.green : Colors.red)),
              ),
            if (provider.cardUid != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Card UID: ${provider.cardUid}', style: TextStyle(fontSize: 12)),
                ),
          ],
        ),
      ),
    );
  }
}