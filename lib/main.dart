import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/broker.dart';
import 'services/storage_service.dart';
import 'views/stock_dashboard_page.dart';
import 'views/broker_settings_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D1117),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const StockRiskManagerApp());
}

class StockRiskManagerApp extends StatelessWidget {
  const StockRiskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock & Broker Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2563EB),
          surface: Color(0xFF161B22),
        ),
        fontFamily: 'Roboto',
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _connectedBrokersCount = 0;

  @override
  void initState() {
    super.initState();
    _checkBrokerConnections();
  }

  Future<void> _checkBrokerConnections() async {
    final brokers = await StorageService.getBrokers();
    setState(() {
      _connectedBrokersCount =
          brokers.where((b) => b.status == BrokerStatus.connected).length;
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      StockDashboardPage(
        onNavigateToBrokerSettings: () => _navigateToTab(1),
        connectedBrokersCount: _connectedBrokersCount,
      ),
      BrokerSettingsPage(
        onBrokersUpdated: _checkBrokerConnections,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF161B22),
          border: Border(
            top: BorderSide(color: Color(0xFF2A2E39), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _navigateToTab,
          backgroundColor: const Color(0xFF161B22),
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: Colors.grey[500],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.candlestick_chart),
              activeIcon: Icon(Icons.candlestick_chart, color: Color(0xFF2563EB)),
              label: 'Stock Tracker',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: _connectedBrokersCount > 0,
                backgroundColor: const Color(0xFF10B981),
                label: Text('$_connectedBrokersCount'),
                child: const Icon(Icons.account_balance_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: _connectedBrokersCount > 0,
                backgroundColor: const Color(0xFF10B981),
                label: Text('$_connectedBrokersCount'),
                child: const Icon(Icons.account_balance, color: Color(0xFF2563EB)),
              ),
              label: 'Connect Broker',
            ),
          ],
        ),
      ),
    );
  }
}
