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

        // Keep ONLY Groww broker
        loaded.removeWhere((b) => b.id != 'groww');

        // Ensure Groww is present
        if (!loaded.any((b) => b.id == 'groww')) {
          loaded.add(_defaultGrowwBroker());
        } else {
          final groww = loaded.firstWhere((b) => b.id == 'groww');
          // Always apply latest credentials (new API key + correct TOTP secret).
          _ensureGrowwDefaults(groww);
          // Persist any updates immediately so the app always runs with fresh creds.
          await saveBrokers(loaded);
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

  /// Fills in any missing critical fields for a Groww broker with safe defaults.
  static void _ensureGrowwDefaults(BrokerAccount groww) {
    // Latest Groww API Key JWT (role: auth-totp) — update when regenerated from Groww portal.
    const defaultApiKey =
        'eyJraWQiOiJaTUtjVXciLCJhbGciOiJFUzI1NiJ9.eyJleHAiOjI1NzkwNzMwMTMsImlhdCI6MTc5MDY3MzAxMywibmJmIjoxNzkwNjczMDEzLCJzdWIiOiJ7XCJ0b2tlblJlZklkXCI6XCJlMDQwM2NlZS0wZDQ5LTQ5NmYtOTc5My00ODRhNTkzNmNiYTVcIixcInZlbmRvckludGVncmF0aW9uS2V5XCI6XCJlMzFmZjIzYjA4NmI0MDZjODg3NGIyZjZkODQ5NTMxM1wiLFwidXNlckFjY291bnRJZFwiOlwiYWFiY2Y2NzAtYzFhNy00ZDY3LWFlMWItMDRlOWJiNWQ5YzRjXCIsXCJkZXZpY2VJZFwiOlwiM2MyZjBjZmItNGE3ZC01N2ZiLWFhMzctOGNjNzAzNDdkNDZlXCIsXCJzZXNzaW9uSWRcIjpcIjg4ZGVjZjQ1LWE5ZTYtNDZlZi04Y2YyLWEyNmVmODE2MWJiY1wiLFwiYWRkaXRpb25hbERhdGFcIjpcIno1NC9NZzltdjE2WXdmb0gvS0EwYkV2V3lsaUNHbWQwcFFUVG1FM1REZnhSTkczdTlLa2pWZDNoWjU1ZStNZERhWXBOVi9UOUxIRmtQejFFQisybTdRPT1cIixcInJvbGVcIjpcImF1dGgtdG90cFwiLFwic291cmNlSXBBZGRyZXNzXCI6XCIyNDA5OjQwYzE6NDAxZjo2ZTk2OjVjMDA6MTExZToyYmM5Ojk0OWUsMTcyLjY5Ljk0LjE1MCwzNS4yNDEuMjMuMTIzXCIsXCJ0d29GYUV4cGlyeVRzXCI6MjU3OTA3MzAxMzUwOSxcInZlbmRvck5hbWVcIjpcImdyb3d3QXBpXCJ9IiwiaXNzIjoiYXBleC1hdXRoLXByb2QtYXBwIn0.PWAub0A-AhxzF_IKgfLYjyJAPPomIevg2AZbYKg4R9bTIeHY0qM3D3BdDUn90mA0-Ue_Xdcbpqv4hqkEbXX7Jw';
    // Groww API Secret — HMAC-SHA256 key for Approval flow checksum.
    const defaultApiSecret = ')msR3J0Ppt4-eX612InuNgLEHt-Mef)1';
    // Real Base32 TOTP scan secret from Groww API Portal.
    const defaultTotpSecret = 'IAPZSHQBFE57HWAHUROFAFMT72S5TIB5';

    // Always override to latest API key — old stale JWTs cause HTTP 400.
    groww.apiKey = defaultApiKey;
    // Always set the API secret for HMAC checksum generation.
    groww.apiSecret = defaultApiSecret;
    if (groww.baseUrl.isEmpty) groww.baseUrl = 'https://api.groww.in';
    // Always ensure the real Base32 TOTP scan secret is set.
    if (groww.totpSecret.isEmpty || !_isValidBase32(groww.totpSecret)) {
      groww.totpSecret = defaultTotpSecret;
    }
    if (groww.status != BrokerStatus.connected) {
      groww.status = BrokerStatus.connected;
      groww.lastConnectedAt = DateTime.now();
    }
  }

  static BrokerAccount _defaultGrowwBroker() {
    // Latest Groww API Key JWT (role: auth-totp) — update when regenerated from Groww portal.
    const defaultApiKey =
        'eyJraWQiOiJaTUtjVXciLCJhbGciOiJFUzI1NiJ9.eyJleHAiOjI1NzkwNzMwMTMsImlhdCI6MTc5MDY3MzAxMywibmJmIjoxNzkwNjczMDEzLCJzdWIiOiJ7XCJ0b2tlblJlZklkXCI6XCJlMDQwM2NlZS0wZDQ5LTQ5NmYtOTc5My00ODRhNTkzNmNiYTVcIixcInZlbmRvckludGVncmF0aW9uS2V5XCI6XCJlMzFmZjIzYjA4NmI0MDZjODg3NGIyZjZkODQ5NTMxM1wiLFwidXNlckFjY291bnRJZFwiOlwiYWFiY2Y2NzAtYzFhNy00ZDY3LWFlMWItMDRlOWJiNWQ5YzRjXCIsXCJkZXZpY2VJZFwiOlwiM2MyZjBjZmItNGE3ZC01N2ZiLWFhMzctOGNjNzAzNDdkNDZlXCIsXCJzZXNzaW9uSWRcIjpcIjg4ZGVjZjQ1LWE5ZTYtNDZlZi04Y2YyLWEyNmVmODE2MWJiY1wiLFwiYWRkaXRpb25hbERhdGFcIjpcIno1NC9NZzltdjE2WXdmb0gvS0EwYkV2V3lsaUNHbWQwcFFUVG1FM1REZnhSTkczdTlLa2pWZDNoWjU1ZStNZERhWXBOVi9UOUxIRmtQejFFQisybTdRPT1cIixcInJvbGVcIjpcImF1dGgtdG90cFwiLFwic291cmNlSXBBZGRyZXNzXCI6XCIyNDA5OjQwYzE6NDAxZjo2ZTk2OjVjMDA6MTExZToyYmM5Ojk0OWUsMTcyLjY5Ljk0LjE1MCwzNS4yNDEuMjMuMTIzXCIsXCJ0d29GYUV4cGlyeVRzXCI6MjU3OTA3MzAxMzUwOSxcInZlbmRvck5hbWVcIjpcImdyb3d3QXBpXCJ9IiwiaXNzIjoiYXBleC1hdXRoLXByb2QtYXBwIn0.PWAub0A-AhxzF_IKgfLYjyJAPPomIevg2AZbYKg4R9bTIeHY0qM3D3BdDUn90mA0-Ue_Xdcbpqv4hqkEbXX7Jw';
    // Groww API Secret — HMAC-SHA256 key for Approval flow checksum.
    const defaultApiSecret = ')msR3J0Ppt4-eX612InuNgLEHt-Mef)1';
    // Real Base32 TOTP scan secret from Groww API Portal.
    const defaultTotpSecret = 'IAPZSHQBFE57HWAHUROFAFMT72S5TIB5';

    return BrokerAccount(
      id: 'groww',
      name: 'Groww Broker',
      logoSymbol: 'GW',
      description: 'Groww Stock Broker Trading API Portal.',
      apiKey: defaultApiKey,
      apiSecret: defaultApiSecret,
      totpSecret: defaultTotpSecret,
      baseUrl: 'https://api.groww.in',
      status: BrokerStatus.connected,
      lastConnectedAt: DateTime.now(),
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
