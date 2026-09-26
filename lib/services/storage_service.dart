import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/broker.dart';

class StorageService {
  static const String _savedStocksKey = 'saved_stock_symbols';
  static const String _brokersKey = 'saved_brokers_data';

  // Save watchlist symbols
  static Future<void> saveSavedStockSymbols(List<String> symbols) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedStocksKey, symbols);
  }

  // Load watchlist symbols
  static Future<List<String>> getSavedStockSymbols() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_savedStocksKey) ?? ['AAPL', 'NVDA', 'TSLA', 'AMZN'];
  }

  // Save broker configurations
  static Future<void> saveBrokers(List<BrokerAccount> brokers) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedList =
        brokers.map((broker) => jsonEncode(broker.toJson())).toList();
    await prefs.setStringList(_brokersKey, encodedList);
  }

  // Load broker configurations
  static Future<List<BrokerAccount>> getBrokers() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? encodedList = prefs.getStringList(_brokersKey);
    if (encodedList == null || encodedList.isEmpty) {
      return _getDefaultBrokers();
    }
    try {
      final loaded = encodedList
          .map((item) => BrokerAccount.fromJson(jsonDecode(item)))
          .toList();
      
      // Ensure Dhan Broker is present if missing from older saved state
      if (!loaded.any((b) => b.id == 'dhan')) {
        loaded.insert(1, BrokerAccount(
          id: 'dhan',
          name: 'Dhan HQ',
          logoSymbol: 'DH',
          description: 'Lightning-fast superfast stock & F&O trading REST API.',
        ));
      }
      return loaded;
    } catch (_) {
      return _getDefaultBrokers();
    }
  }

  static List<BrokerAccount> _getDefaultBrokers() {
    return [
      BrokerAccount(
        id: 'zerodha',
        name: 'Zerodha Kite',
        logoSymbol: 'ZK',
        description: 'India\'s largest discount broker & API portal.',
      ),
      BrokerAccount(
        id: 'dhan',
        name: 'Dhan HQ',
        logoSymbol: 'DH',
        description: 'Lightning-fast superfast stock & F&O trading REST API.',
      ),
      BrokerAccount(
        id: 'alpaca',
        name: 'Alpaca Trading',
        logoSymbol: 'AP',
        description: 'Commission-free stock & crypto REST / WebSocket API.',
      ),
      BrokerAccount(
        id: 'ibkr',
        name: 'Interactive Brokers',
        logoSymbol: 'IB',
        description: 'Global market access API for equities, options & futures.',
      ),
      BrokerAccount(
        id: 'binance',
        name: 'Binance Global',
        logoSymbol: 'BN',
        description: 'Leading global spot & futures trading platform API.',
      ),
      BrokerAccount(
        id: 'robinhood',
        name: 'Robinhood Connect',
        logoSymbol: 'RH',
        description: 'Retail trading REST API integration with OAuth 2.0.',
      ),
    ];
  }
}
