import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/broker.dart';

class StorageService {
  static const String _savedStocksKey = 'saved_stock_symbols';
  static const String _brokersKey = 'saved_brokers_data';

  // Save watchlist symbols
  static Future<bool> saveSavedStockSymbols(List<String> symbols) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setStringList(_savedStocksKey, symbols);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving stock symbols: $e');
      }
      return false;
    }
  }

  // Load watchlist symbols
  static Future<List<String>> getSavedStockSymbols() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? saved = prefs.getStringList(_savedStocksKey);
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading stock symbols: $e');
      }
    }
    return ['AAPL', 'NVDA', 'TSLA', 'AMZN', 'RELIANCE', 'BTC-USD'];
  }

  // Save broker configurations
  static Future<bool> saveBrokers(List<BrokerAccount> brokers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> encodedList =
          brokers.map((broker) => jsonEncode(broker.toJson())).toList();
      return await prefs.setStringList(_brokersKey, encodedList);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving brokers: $e');
      }
      return false;
    }
  }

  // Load broker configurations
  static Future<List<BrokerAccount>> getBrokers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? encodedList = prefs.getStringList(_brokersKey);
      if (encodedList != null && encodedList.isNotEmpty) {
        final loaded = encodedList
            .map((item) => BrokerAccount.fromJson(jsonDecode(item)))
            .toList();

        // Ensure Dhan Broker is present if missing from older state
        if (!loaded.any((b) => b.id == 'dhan')) {
          loaded.insert(
            1,
            BrokerAccount(
              id: 'dhan',
              name: 'Dhan HQ',
              logoSymbol: 'DH',
              description:
                  'Lightning-fast superfast stock & F&O trading REST API.',
            ),
          );
        }
        return loaded;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading brokers: $e');
      }
    }
    return _getDefaultBrokers();
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
        description:
            'Global market access API for equities, options & futures.',
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
