import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/payment_provider.dart';
import 'providers/recharge_provider.dart';
import 'screens/terminal_screen.dart';
import 'screens/recharge_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация провайдеров
  final paymentProvider = PaymentProvider();
  await paymentProvider.init();
  
  final rechargeProvider = RechargeProvider();
  
  runApp(MyApp(
    paymentProvider: paymentProvider,
    rechargeProvider: rechargeProvider,
  ));
}

class MyApp extends StatelessWidget {
  final PaymentProvider paymentProvider;
  final RechargeProvider rechargeProvider;
  
  const MyApp({
    super.key,
    required this.paymentProvider,
    required this.rechargeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: paymentProvider),
        ChangeNotifierProvider.value(value: rechargeProvider),
      ],
      child: MaterialApp(
        title: 'Transport Terminal',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Terminal'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TerminalScreen()),
              ),
              icon: const Icon(Icons.payment),
              label: const Text('Pay 50 RUB'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RechargeScreen()),
              ),
              icon: const Icon(Icons.add_card),
              label: const Text('Recharge Card'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}