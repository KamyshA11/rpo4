import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/payment_provider.dart';
import 'providers/recharge_provider.dart';
import 'services/nfc_service.dart';
import 'screens/terminal_screen.dart';
import 'screens/recharge_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final nfc = NfcService();
  await nfc.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => RechargeProvider()),
      ],
      child: MaterialApp(
        title: 'Transport Terminal',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transport Terminal'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TerminalScreen())),
              icon: Icon(Icons.payment),
              label: Text('Pay 50 RUB'),
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RechargeScreen())),
              icon: Icon(Icons.add_card),
              label: Text('Recharge Card'),
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
            ),
          ],
        ),
      ),
    );
  }
}