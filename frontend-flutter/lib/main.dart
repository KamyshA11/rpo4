import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/payment_provider.dart';
import 'providers/recharge_provider.dart';
import 'providers/balance_provider.dart';
import 'screens/terminal_screen.dart';
import 'screens/recharge_screen.dart';
import 'screens/balance_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final paymentProvider = PaymentProvider();
  await paymentProvider.init();
  
  final rechargeProvider = RechargeProvider();
  await rechargeProvider.init();
  
  final balanceProvider = BalanceProvider();
  await balanceProvider.init();
  
  runApp(MyApp(
    paymentProvider: paymentProvider,
    rechargeProvider: rechargeProvider,
    balanceProvider: balanceProvider,
  ));
}

class MyApp extends StatelessWidget {
  final PaymentProvider paymentProvider;
  final RechargeProvider rechargeProvider;
  final BalanceProvider balanceProvider;
  
  const MyApp({
    super.key,
    required this.paymentProvider,
    required this.rechargeProvider,
    required this.balanceProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: paymentProvider),
        ChangeNotifierProvider.value(value: rechargeProvider),
        ChangeNotifierProvider.value(value: balanceProvider),
      ],
      child: MaterialApp(
        title: 'Transport Terminal',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.cyan.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Text(
                'Transport Terminal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Система оплаты проезда',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Кнопка Оплата
                      _buildMenuButton(
                        context,
                        title: 'Оплата проезда',
                        subtitle: 'Списать 50 ₽',
                        icon: Icons.payment,
                        color: Colors.orange,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TerminalScreen()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Кнопка Пополнение
                      _buildMenuButton(
                        context,
                        title: 'Пополнение карты',
                        subtitle: 'Пополнить баланс',
                        icon: Icons.add_card,
                        color: Colors.green,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RechargeScreen()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Кнопка Баланс
                      _buildMenuButton(
                        context,
                        title: 'Баланс карты',
                        subtitle: 'Проверить баланс',
                        icon: Icons.account_balance_wallet,
                        color: Colors.purple,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BalanceScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMenuButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.9),
                color,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}