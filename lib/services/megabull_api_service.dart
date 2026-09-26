import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import '../models/instrument_model.dart';
import '../models/order_model.dart';
import '../models/holding_model.dart';

class MegaBullApiService {
  static String baseUrl = 'https://api.megabull.in';
  static String apiKey = 'd35a226d-5b3a-44d7-a954-2db87bd069a7';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'api-key': apiKey,
        'User-Agent': 'MegaBullPaperTrader/1.0',
      };

  static List<Instrument>? _cachedCsvInstruments;

  /// Fetch instruments catalog from MegaBull S3 CSV
  static Future<List<Instrument>> fetchInstruments() async {
    if (_cachedCsvInstruments != null && _cachedCsvInstruments!.isNotEmpty) {
      return _cachedCsvInstruments!;
    }

    final url = '$baseUrl/api/marketwatch/instruments';
    print('==================================================');
    print('[MEGABULL API] Fetching instrument master from: $url');
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 6));

      print('[MEGABULL API] Instruments master response code: ${response.statusCode}');
      print('[MEGABULL API] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? downloadUrl = (data is Map)
            ? (data['downloadUrl'] ?? data['url'] ?? data['data']?['downloadUrl'])
            : null;

        if (downloadUrl != null && downloadUrl.isNotEmpty) {
          print('[MEGABULL CSV DOWNLOAD URL]: $downloadUrl');
          final csvResponse = await http
              .get(Uri.parse(downloadUrl))
              .timeout(const Duration(seconds: 10));

          print('[MEGABULL CSV STATUS CODE]: ${csvResponse.statusCode}');
          if (csvResponse.statusCode == 200) {
            final parsed = _parseInstrumentCsv(csvResponse.body);
            _cachedCsvInstruments = parsed;
            print('[MEGABULL API] Successfully downloaded and parsed ${parsed.length} CSV instruments.');
            return parsed;
          } else {
            print('[MEGABULL CSV ERROR] Failed to download CSV from $downloadUrl (HTTP ${csvResponse.statusCode})');
          }
        } else if (data is List) {
          final parsed = data.map((item) => Instrument.fromJson(item)).toList();
          _cachedCsvInstruments = parsed;
          return parsed;
        }
      } else {
        print('[MEGABULL API ERROR] Fetch instruments failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('[MEGABULL API EXCEPTION] fetchInstruments error: $e');
      print('StackTrace:\n$stackTrace');
    }

    return _cachedCsvInstruments ?? [];
  }

  /// Parse MegaBull CSV string into List<Instrument>
  static List<Instrument> _parseInstrumentCsv(String csvContent) {
    final List<Instrument> list = [];
    final lines = const LineSplitter().convert(csvContent);
    if (lines.isEmpty) return list;

    print('[MEGABULL CSV HEADER LINE]: ${lines[0]}');
    if (lines.length > 1) {
      print('[MEGABULL CSV SAMPLE ROW 1]: ${lines[1]}');
    }

    final headerLine = lines[0].toLowerCase().replaceAll('"', '').replaceAll("'", '');
    final headers = headerLine.split(',').map((h) => h.trim()).toList();

    int tokenIdx = headers.indexWhere((h) => h.contains('token') || h.contains('id') || h.contains('script'));
    int symbolIdx = headers.indexWhere((h) => h.contains('symbol') || h.contains('name') || h.contains('ticker'));
    int nameIdx = headers.indexWhere((h) => h.contains('name') || h.contains('company') || h.contains('title'));
    int exchangeIdx = headers.indexWhere((h) => h.contains('exchange') || h.contains('segment'));
    int priceIdx = headers.indexWhere((h) => h.contains('price') || h.contains('last') || h.contains('close'));

    if (tokenIdx == -1) tokenIdx = 0;
    if (symbolIdx == -1) symbolIdx = 1 < headers.length ? 1 : 0;
    if (nameIdx == -1) nameIdx = symbolIdx;
    if (exchangeIdx == -1) exchangeIdx = 2 < headers.length ? 2 : 0;
    if (priceIdx == -1) priceIdx = 3 < headers.length ? 3 : 0;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(',');

      if (parts.length > tokenIdx && parts.length > symbolIdx) {
        final token = parts[tokenIdx].replaceAll('"', '').replaceAll("'", '').trim();
        final symbol = parts[symbolIdx].replaceAll('"', '').replaceAll("'", '').trim();
        final name = parts.length > nameIdx ? parts[nameIdx].replaceAll('"', '').replaceAll("'", '').trim() : symbol;
        final ex = parts.length > exchangeIdx ? parts[exchangeIdx].replaceAll('"', '').replaceAll("'", '').trim() : 'NSE';
        final priceStr = parts.length > priceIdx ? parts[priceIdx].replaceAll('"', '').replaceAll("'", '').trim() : '0.0';
        final price = double.tryParse(priceStr) ?? 0.0;

        if (token.isNotEmpty && symbol.isNotEmpty) {
          final cleanSym = symbol.replaceAll('.NS', '').replaceAll('.BO', '').replaceAll('-EQ', '').replaceAll('NSE:', '').toUpperCase().trim();
          if (cleanSym.contains('TCS') || token.toUpperCase().contains('TCS')) {
            print('[MEGABULL TCS MATCH] CSV Row $i: $line');
            print('Resolved MegaBull instrumentToken: $token, symbol: $symbol');
          }

          list.add(
            Instrument(
              instrumentToken: token,
              symbol: symbol,
              name: name.isNotEmpty ? name : symbol,
              exchange: ex.toUpperCase().contains('BSE') ? 'BSE' : 'NSE',
              price: price,
              change: 0.0,
              percentChange: 0.0,
              open: price,
              high: price * 1.01,
              low: price * 0.99,
              marketCap: '₹1,50,000 Cr',
              peRatio: 24.5,
              volume: 1000000.0,
              chartData: [price * 0.99, price, price * 1.01],
            ),
          );
        }
      }
    }
    return list;
  }

  /// Search instruments matching query
  static Future<List<Instrument>> searchInstruments(String query) async {
    final q = query.trim().toUpperCase();
    if (q.isEmpty) return [];

    final all = await fetchInstruments();
    return all.where((inst) {
      final sym = inst.symbol.toUpperCase();
      final name = inst.name.toUpperCase();
      return sym.contains(q) || name.contains(q);
    }).toList();
  }

  /// Place Paper BUY / SELL order on MegaBull API `/api/order/buysell`
  static Future<Map<String, dynamic>> placePaperOrder({
    required String instrumentToken,
    required String symbol,
    required String name,
    required OrderTransactionType transactionType,
    required OrderType orderType,
    required int quantity,
    required double price,
    double triggerPrice = 0.0,
  }) async {
    final String cleanSym = symbol.replaceAll('.NS', '').replaceAll('.BO', '').trim().toUpperCase();
    String resolvedToken = instrumentToken;

    try {
      final mbInstruments = await fetchInstruments();
      if (mbInstruments.isNotEmpty) {
        final matched = mbInstruments.firstWhereOrNull((inst) {
          final sym = inst.symbol.replaceAll('.NS', '').replaceAll('.BO', '').trim().toUpperCase();
          return sym == cleanSym || inst.instrumentToken == instrumentToken;
        });
        if (matched != null) {
          resolvedToken = matched.instrumentToken;
        } else {
          return {
            'success': false,
            'message': '$cleanSym is not available for trading with MegaBull.',
          };
        }
      }
    } catch (_) {}

    final url = '$baseUrl/api/order/buysell';
    final int qtyInt = quantity > 0 ? quantity : 1;

    final bodyMap = {
      'instrumentToken': resolvedToken,
      'qty': qtyInt,
      'type': transactionType.name.toUpperCase(),
      'duration': 'MIS',
      'orderType': orderType.name.toUpperCase(),
      'price': price,
      'triggerPrice': triggerPrice > 0 ? triggerPrice : (price * 0.98),
    };
    final body = jsonEncode(bodyMap);

    print('--------------------------------------------------');
    print('[MEGABULL API] Placing Paper Order...');
    print('URL: $url');
    print('Payload: $body');
    print('--------------------------------------------------');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: body,
          )
          .timeout(const Duration(seconds: 5));

      print('[MEGABULL API] Response Status: ${response.statusCode}');
      print('[MEGABULL API] Response Body: ${response.body}');

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        print('[MEGABULL API] Response JSON Parse Error: $e');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final orderId = (data is Map && (data['orderId'] != null || data['id'] != null))
            ? (data['orderId'] ?? data['id']).toString()
            : 'ORD-${DateTime.now().millisecondsSinceEpoch}';
        final msg = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Paper ${transactionType.name} order executed successfully!';

        print('[MEGABULL API SUCCESS] $msg (Order ID: $orderId)');
        return {
          'success': true,
          'orderId': orderId,
          'message': msg,
        };
      } else {
        String errorMsg = 'API Error (${response.statusCode})';
        if (data is Map) {
          if (data['message'] != null) {
            final m = data['message'];
            errorMsg = m is List ? m.join(', ') : m.toString();
          } else if (data['error'] != null) {
            errorMsg = data['error'].toString();
          }
        }

        print('[MEGABULL API ERROR] $errorMsg');
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e, stackTrace) {
      print('==================================================');
      print('[MEGABULL API EXCEPTION] placePaperOrder Network Exception!');
      print('Error: $e');
      print('StackTrace:\n$stackTrace');
      print('==================================================');
      return {
        'success': false,
        'message': 'Network error: Unable to reach MegaBull API ($e).',
      };
    }
  }

  /// Fetch paper orders from MegaBull `/api/order/my`
  static Future<List<OrderItem>> fetchPaperOrders() async {
    final url = '$baseUrl/api/order/my';
    print('[MEGABULL API] Fetching paper orders from $url...');
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 4));

      print('[MEGABULL API] Fetch orders response code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // MegaBull returns { "open": [...], "executed": [...] }
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          final open = data['open'];
          final executed = data['executed'];
          final orders = data['data'] ?? data['orders'];
          if (open is List) list.addAll(open);
          if (executed is List) list.addAll(executed);
          if (orders is List && list.isEmpty) list = orders;
        }
        return list.map((item) => OrderItem.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        print('[MEGABULL API ERROR] Fetch orders failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('[MEGABULL API EXCEPTION] fetchPaperOrders error: $e');
    }
    return [];
  }

  /// Fetch holdings from MegaBull `/api/holding/my`
  static Future<List<HoldingItem>> fetchHoldings() async {
    final url = '$baseUrl/api/holding/my';
    print('[MEGABULL API] Fetching holdings from $url...');
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 4));

      print('[MEGABULL API] Fetch holdings response code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic>? list = data is List ? data : data['data'] ?? data['holdings'];
        if (list != null) {
          return list.map((item) => HoldingItem.fromJson(item)).toList();
        }
      } else {
        print('[MEGABULL API ERROR] Fetch holdings failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('[MEGABULL API EXCEPTION] fetchHoldings error: $e');
    }
    return [];
  }
}
