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

  // Load watchlist symbols - Defaults to Indian Stock Tickers (NSE)
  static Future<List<String>> getSavedStockSymbols() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? saved = prefs.getStringList(_savedStocksKey);
      if (saved != null && saved.isNotEmpty) {
        // Filter out old crypto / US symbols if present
        final filtered = saved.where((s) {
          return !s.contains('BTC') &&
              !s.contains('AAPL') &&
              !s.contains('NVDA') &&
              !s.contains('TSLA') &&
              !s.contains('AMZN') &&
              !s.contains('MSFT') &&
              !s.contains('GOOGL') &&
              !s.contains('META');
        }).toList();

        if (filtered.isNotEmpty) return filtered;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading stock symbols: $e');
      }
    }
    // Return empty list — user must search and add real stocks
    return [];
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

        // Filter out US / International brokers if present
        loaded.removeWhere((b) => b.id == 'alpaca' || b.id == 'binance');

        // Ensure MegaBull Demo Broker is present and CONNECTED by default for testing
        final megabullIndex = loaded.indexWhere((b) => b.id == 'megabull');
        if (megabullIndex >= 0) {
          final existingMB = loaded[megabullIndex];
          existingMB.status = BrokerStatus.connected;
          if (existingMB.baseUrl.isEmpty) existingMB.baseUrl = 'https://api.megabull.in';
          if (existingMB.apiKey.isEmpty) existingMB.apiKey = 'd35a226d-5b3a-44d7-a954-2db87bd069a7';
          if (existingMB.apiSecret.isEmpty) existingMB.apiSecret = 'd35a226d-5b3a-44d7-a954-2db87bd069a7';
          if (existingMB.accountId.isEmpty) existingMB.accountId = 'MB-DEMO-99';
        } else {
          loaded.insert(
            0,
            BrokerAccount(
              id: 'megabull',
              name: 'MegaBull API (Demo)',
              logoSymbol: 'MB',
              description: 'Demo paper trading REST API (https://api.megabull.in)',
              baseUrl: 'https://api.megabull.in',
              apiKey: 'd35a226d-5b3a-44d7-a954-2db87bd069a7',
              apiSecret: 'd35a226d-5b3a-44d7-a954-2db87bd069a7',
              accountId: 'MB-DEMO-99',
              environment: 'Sandbox',
              status: BrokerStatus.connected,
              lastConnectedAt: DateTime.now(),
            ),
          );
        }

        // Ensure Dhan Broker is present
        if (!loaded.any((b) => b.id == 'dhan')) {
          loaded.insert(
            1,
            BrokerAccount(
              id: 'dhan',
              name: 'Dhan HQ Sandbox',
              logoSymbol: 'DH',
              description:
                  'Indian stock market REST & WebSocket API portal.',
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
        id: 'megabull',
        name: 'MegaBull API (Demo)',
        logoSymbol: 'MB',
        description: 'Demo paper trading REST API (https://api.megabull.in)',
        baseUrl: 'https://api.megabull.in',
        apiKey: 'd35a226d-5b3a-44d7-a954-2db87bd069a7',
        apiSecret: 'd35a226d-5b3a-44d7-a954-2db87bd069a7',
        accountId: 'MB-DEMO-99',
        environment: 'Sandbox',
        status: BrokerStatus.connected,
        lastConnectedAt: DateTime.now(),
      ),
      BrokerAccount(
        id: 'zerodha',
        name: 'Zerodha Kite Sandbox',
        logoSymbol: 'ZK',
        description: 'India\'s largest discount broker & API portal.',
      ),
      BrokerAccount(
        id: 'dhan',
        name: 'Dhan HQ Sandbox',
        logoSymbol: 'DH',
        description: 'Indian stock market REST & WebSocket API portal.',
      ),
      BrokerAccount(
        id: 'angelone',
        name: 'AngelOne SmartAPI',
        logoSymbol: 'AO',
        description: 'Indian stock broker API for NSE/BSE equities.',
      ),
      BrokerAccount(
        id: 'upstox',
        name: 'Upstox Developer API',
        logoSymbol: 'UP',
        description: 'REST API trading portal for Indian markets.',
      ),
    ];
  }
}
