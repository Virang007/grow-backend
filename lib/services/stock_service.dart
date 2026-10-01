import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/stock_model.dart';

class StockService {
  static final Map<String, Stock> _cache = {};

  // Default watchlist symbols - Top Indian Stocks (NSE)
  static final List<String> defaultWatchlistSymbols = [
    'RELIANCE.NS',
    'TCS.NS',
    'INFY.NS',
    'HDFCBANK.NS',
    'ICICIBANK.NS',
    'SBIN.NS',
    'TATAMOTORS.NS',
    'BHARTIARTL.NS',
    'ITC.NS',
    'LT.NS'
  ];

  /// Fetch live quote for an Indian stock (NSE/BSE)
  static Future<Stock?> fetchLiveStockQuote(String rawSymbol) async {
    String cleanSymbol = rawSymbol.trim().toUpperCase();
    if (cleanSymbol.isEmpty) return null;

    // Default to NSE (.NS) if no exchange specified (except indices like ^NSEI)
    if (!cleanSymbol.startsWith('^') && !cleanSymbol.endsWith('.NS') && !cleanSymbol.endsWith('.BO')) {
      cleanSymbol = '$cleanSymbol.NS';
    }

    try {
      final url = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$cleanSymbol?range=1d&interval=5m');
      final response = await http
          .get(url, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(
        const Duration(seconds: 4),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['chart']?['result']?[0];
        if (result != null) {
          final meta = result['meta'];
          final double currentPrice =
              (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0.0;
          final double prevClose =
              (meta['chartPreviousClose'] as num?)?.toDouble() ?? currentPrice;
          final double change = currentPrice - prevClose;
          final double percentChange =
              prevClose != 0 ? (change / prevClose) * 100 : 0.0;

          final double high =
              (meta['regularMarketDayHigh'] as num?)?.toDouble() ?? currentPrice * 1.01;
          final double low =
              (meta['regularMarketDayLow'] as num?)?.toDouble() ?? currentPrice * 0.99;
          final double open =
              (meta['regularMarketDayLow'] as num?)?.toDouble() ?? currentPrice;

          final List<dynamic>? closePrices =
              result['indicators']?['quote']?[0]?['close'];

          List<double> chartPoints = [];
          if (closePrices != null) {
            chartPoints = closePrices
                .where((val) => val != null)
                .map((val) => (val as num).toDouble())
                .toList();
          }

          if (chartPoints.length < 2) {
            chartPoints = [prevClose, currentPrice];
          }

          final String exchangeName =
              cleanSymbol.endsWith('.BO') ? 'BSE' : 'NSE';

          final String tickerOnly = cleanSymbol.replaceAll('.NS', '').replaceAll('.BO', '').trim().toUpperCase();

          final stock = Stock(
            instrumentToken: tickerOnly,
            symbol: cleanSymbol,
            name: meta['shortName'] ?? meta['longName'] ?? _getIndianStockName(cleanSymbol),
            exchange: exchangeName,
            price: currentPrice,
            change: change,
            percentChange: percentChange,
            open: open,
            high: high,
            low: low,
            swingHigh: high * 1.01,
            swingLow: low * 0.99,
            marketCap: _formatIndianMarketCap(meta['marketCap']),
            peRatio: (meta['trailingPE'] as num?)?.toDouble() ?? 26.4,
            volume: (meta['regularMarketVolume'] as num?)?.toDouble() ?? 5000000.0,
            chartData: chartPoints,
          );

          _cache[cleanSymbol] = stock;
          return stock;
        }
      }
    } catch (e) {
      print('[STOCK SERVICE ERROR] Fetch live stock quote failed for $cleanSymbol: $e');
    }

    if (_cache.containsKey(cleanSymbol)) {
      return _cache[cleanSymbol]!;
    }

    return null;
  }

  /// Batch fetch quotes for list of Indian stock symbols
  static Future<List<Stock>> fetchBatchStockQuotes(List<String> symbols) async {
    final List<Stock> results = [];
    final futures = symbols.map((sym) => fetchLiveStockQuote(sym));
    final fetched = await Future.wait(futures);

    for (var s in fetched) {
      if (s != null) {
        results.add(s);
      }
    }
    return results;
  }

  /// Search live Indian stocks (NSE / BSE) matching user query
  static Future<List<Stock>> searchLiveStocks(String query) async {
    final q = query.trim().toUpperCase();
    if (q.isEmpty) return [];

    try {
      final url = Uri.parse(
          'https://query1.finance.yahoo.com/v1/finance/search?q=$q&quotesCount=10');
      final response = await http
          .get(url, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(
        const Duration(seconds: 4),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic>? quotes = data['quotes'];
        if (quotes != null && quotes.isNotEmpty) {
          final List<String> symbolsToFetch = [];
          for (var qItem in quotes) {
            final String? sym = qItem['symbol'];
            // Filter to only include Indian stocks (.NS or .BO)
            if (sym != null && (sym.endsWith('.NS') || sym.endsWith('.BO'))) {
              symbolsToFetch.add(sym);
            }
          }

          if (symbolsToFetch.isNotEmpty) {
            return await fetchBatchStockQuotes(symbolsToFetch);
          }
        }
      }
    } catch (_) {}

    // Fallback search using Indian ticker format
    final Stock? exactMatch = await fetchLiveStockQuote(q);
    if (exactMatch != null) {
      return [exactMatch];
    }
    return [];
  }



  static String _getIndianStockName(String symbol) {
    final clean = symbol.replaceAll('.NS', '').replaceAll('.BO', '');
    switch (clean) {
      case '^NSEI':
        return 'NIFTY 50 Index';
      case '^BSESN':
        return 'SENSEX Index';
      case '^NSEBANK':
        return 'NIFTY Bank Index';
      case 'RELIANCE':
        return 'Reliance Industries Ltd.';
      case 'TCS':
        return 'Tata Consultancy Services Ltd.';
      case 'INFY':
        return 'Infosys Limited';
      case 'HDFCBANK':
        return 'HDFC Bank Limited';
      case 'ICICIBANK':
        return 'ICICI Bank Limited';
      case 'SBIN':
        return 'State Bank of India';
      case 'TATAMOTORS':
        return 'Tata Motors Limited';
      case 'BHARTIARTL':
        return 'Bharti Airtel Limited';
      case 'ITC':
        return 'ITC Limited';
      case 'LT':
        return 'Larsen & Toubro Limited';
      default:
        return '$clean India Ltd.';
    }
  }

  static String _formatIndianMarketCap(dynamic cap) {
    if (cap == null || cap is! num) return '₹1,50,000 Cr';
    final double numCap = cap.toDouble();
    if (numCap >= 1e7) {
      return '₹${(numCap / 1e7).toStringAsFixed(1)} Cr';
    } else if (numCap >= 1e5) {
      return '₹${(numCap / 1e5).toStringAsFixed(1)} Lakh';
    }
    return '₹${numCap.toStringAsFixed(0)}';
  }
}
