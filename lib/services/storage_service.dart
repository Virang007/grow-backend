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
            .toList();        // Keep ONLY Groww broker
        loaded.removeWhere((b) => b.id != 'groww');

        // Ensure Groww is present
        if (!loaded.any((b) => b.id == 'groww')) {
          loaded.add(_defaultGrowwBroker());
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

  static BrokerAccount _defaultGrowwBroker() {
    return BrokerAccount(
      id: 'groww',
      name: 'Groww Broker',
      logoSymbol: 'GW',
      description: 'Groww Stock Broker Trading API Portal.',
      apiKey: '',
      apiSecret: '',
      totpSecret: '',
      baseUrl: 'https://api.groww.in',
      status: BrokerStatus.disconnected,
      lastConnectedAt: null,
    );
  }

  /// Returns true if [s] is a valid Base32 string (RFC 4648).
  /// Only A–Z and 2–7 characters are allowed, with optional '=' padding.
  /// An empty string is considered invalid.
  static bool _isValidBase32(String s) {
    if (s.isEmpty) return false;
    final clean = s.replaceAll(RegExp(r'\s'), '').toUpperCase();
    for (final ch in clean.runes) {
      final isBase32 = (ch >= 65 && ch <= 90) || // A-Z
          (ch >= 50 && ch <= 55) || // 2-7
          ch == 61; // '='
      if (!isBase32) return false;
    }
    return true;
  }

  static List<BrokerAccount> _getDefaultBrokers() {
    return [_defaultGrowwBroker()];
  }
}
