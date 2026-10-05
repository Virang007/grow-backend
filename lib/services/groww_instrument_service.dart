import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/groww_instrument.dart';

/// Fetches and searches Groww's instrument list (NSE + BSE).
///
/// Groww publishes a live instrument data endpoint that contains all
/// tradeable stocks with fields: trading_symbol, company_name, exchange,
/// groww_symbol etc.
///
/// This service:
///   1. Fetches the instrument list on first use and caches it in memory.
///   2. Provides client-side fuzzy search (symbol + company name).
///   3. Builds a static offline fallback list of top Indian stocks so the
///      search works even when the network call fails.
class GrowwInstrumentService {
  // ─── In-memory cache ────────────────────────────────────────────────────────
  static List<GrowwInstrument>? _cachedInstruments;
  static DateTime? _cacheTime;

  // Cache instruments for 4 hours to avoid repeated large fetches.
  static const Duration _cacheTtl = Duration(hours: 4);

  // ─── Groww instrument list endpoint ─────────────────────────────────────────
  // Groww's publicly documented instrument data endpoint.
  // Returns a JSON array of instruments for the NSE CASH segment.
  static const String _nseUrl =
      'https://groww.in/v1/api/stocks_data/v1/tr_live_prices/exchange/NSE/segment/CASH/all-lr';
  static const String _bseUrl =
      'https://groww.in/v1/api/stocks_data/v1/tr_live_prices/exchange/BSE/segment/CASH/all-lr';

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Returns the full cached instrument list, fetching from Groww if needed.
  static Future<List<GrowwInstrument>> getAllInstruments() async {
    if (_cachedInstruments != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheTtl) {
      return _cachedInstruments!;
    }
    await _loadFromNetwork();
    return _cachedInstruments ?? _buildStaticFallback();
  }

  /// Search instruments by trading symbol or company name.
  /// Returns up to [maxResults] results ordered by relevance.
  static Future<List<GrowwInstrument>> search(
    String query, {
    int maxResults = 15,
  }) async {
    final q = query.trim().toUpperCase();
    if (q.isEmpty) return [];

    List<GrowwInstrument> all;
    try {
      all = await getAllInstruments();
    } catch (_) {
      all = _buildStaticFallback();
    }

    // Scoring: exact symbol match → 3, starts-with symbol → 2,
    // contains symbol → 1, contains company name → 0
    final scored = <MapEntry<GrowwInstrument, int>>[];
    for (final inst in all) {
      int score = -1;
      final sym = inst.tradingSymbol.toUpperCase();
      final name = inst.companyName.toUpperCase();

      if (sym == q) {
        score = 3;
      } else if (sym.startsWith(q)) {
        score = 2;
      } else if (sym.contains(q)) {
        score = 1;
      } else if (name.contains(q)) {
        score = 0;
      }

      if (score >= 0) {
        scored.add(MapEntry(inst, score));
      }
    }

    // Sort descending by score
    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.take(maxResults).map((e) => e.key).toList();
  }

  // ─── Network fetch ──────────────────────────────────────────────────────────

  static Future<void> _loadFromNetwork() async {
    print('[GROWW INSTRUMENTS] Fetching instrument list from Groww...');

    final List<GrowwInstrument> all = [];

    // Try NSE
    await _fetchSegment(_nseUrl, 'NSE', all);
    // Try BSE (allow partial failure)
    await _fetchSegment(_bseUrl, 'BSE', all);

    if (all.isNotEmpty) {
      _cachedInstruments = all;
      _cacheTime = DateTime.now();
      print('[GROWW INSTRUMENTS] ✅ Loaded ${all.length} instruments');
    } else {
      print('[GROWW INSTRUMENTS] ⚠️ Network fetch returned 0 instruments — using static fallback');
      _cachedInstruments = _buildStaticFallback();
      _cacheTime = DateTime.now();
    }
  }

  static Future<void> _fetchSegment(
    String url,
    String exchangeLabel,
    List<GrowwInstrument> out,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        // Groww returns either a List or {"data": [...]} wrapper
        List<dynamic> items;
        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          items = decoded['data'] as List<dynamic>;
        } else if (decoded is Map && decoded['result'] is List) {
          items = decoded['result'] as List<dynamic>;
        } else {
          print('[GROWW INSTRUMENTS] Unexpected response shape for $exchangeLabel');
          return;
        }

        for (final item in items) {
          if (item is Map<String, dynamic>) {
            try {
              // Ensure exchange field is set correctly from the segment URL
              final enriched = Map<String, dynamic>.from(item);
              enriched['exchange'] ??= exchangeLabel;
              out.add(GrowwInstrument.fromJson(enriched));
            } catch (_) {
              // Skip malformed entries silently
            }
          }
        }
        print('[GROWW INSTRUMENTS] $exchangeLabel: loaded ${out.length} entries so far');
      } else {
        print('[GROWW INSTRUMENTS] $exchangeLabel fetch failed — HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('[GROWW INSTRUMENTS] $exchangeLabel fetch exception: $e');
    }
  }

  // ─── Static fallback (top NSE stocks) ───────────────────────────────────────

  /// Returns a curated list of top NSE stocks so search works offline.
  static List<GrowwInstrument> _buildStaticFallback() {
    const data = [
      ['RELIANCE', 'Reliance Industries Ltd.', 'NSE', 'NSE_RELIANCE'],
      ['TCS', 'Tata Consultancy Services Ltd.', 'NSE', 'NSE_TCS'],
      ['INFY', 'Infosys Limited', 'NSE', 'NSE_INFY'],
      ['HDFCBANK', 'HDFC Bank Limited', 'NSE', 'NSE_HDFCBANK'],
      ['ICICIBANK', 'ICICI Bank Limited', 'NSE', 'NSE_ICICIBANK'],
      ['SBIN', 'State Bank of India', 'NSE', 'NSE_SBIN'],
      ['TATAMOTORS', 'Tata Motors Limited', 'NSE', 'NSE_TATAMOTORS'],
      ['BHARTIARTL', 'Bharti Airtel Limited', 'NSE', 'NSE_BHARTIARTL'],
      ['ITC', 'ITC Limited', 'NSE', 'NSE_ITC'],
      ['LT', 'Larsen & Toubro Limited', 'NSE', 'NSE_LT'],
      ['WIPRO', 'Wipro Limited', 'NSE', 'NSE_WIPRO'],
      ['AXISBANK', 'Axis Bank Limited', 'NSE', 'NSE_AXISBANK'],
      ['KOTAKBANK', 'Kotak Mahindra Bank Limited', 'NSE', 'NSE_KOTAKBANK'],
      ['BAJFINANCE', 'Bajaj Finance Limited', 'NSE', 'NSE_BAJFINANCE'],
      ['MARUTI', 'Maruti Suzuki India Limited', 'NSE', 'NSE_MARUTI'],
      ['TITAN', 'Titan Company Limited', 'NSE', 'NSE_TITAN'],
      ['SUNPHARMA', 'Sun Pharmaceutical Industries Ltd.', 'NSE', 'NSE_SUNPHARMA'],
      ['ONGC', 'Oil & Natural Gas Corporation Ltd.', 'NSE', 'NSE_ONGC'],
      ['NTPC', 'NTPC Limited', 'NSE', 'NSE_NTPC'],
      ['POWERGRID', 'Power Grid Corporation of India Ltd.', 'NSE', 'NSE_POWERGRID'],
      ['ASIANPAINT', 'Asian Paints Limited', 'NSE', 'NSE_ASIANPAINT'],
      ['ULTRACEMCO', 'UltraTech Cement Limited', 'NSE', 'NSE_ULTRACEMCO'],
      ['HCLTECH', 'HCL Technologies Limited', 'NSE', 'NSE_HCLTECH'],
      ['TECHM', 'Tech Mahindra Limited', 'NSE', 'NSE_TECHM'],
      ['DRREDDY', 'Dr. Reddy\'s Laboratories Limited', 'NSE', 'NSE_DRREDDY'],
      ['CIPLA', 'Cipla Limited', 'NSE', 'NSE_CIPLA'],
      ['DIVISLAB', 'Divi\'s Laboratories Limited', 'NSE', 'NSE_DIVISLAB'],
      ['BAJAJFINSV', 'Bajaj Finserv Limited', 'NSE', 'NSE_BAJAJFINSV'],
      ['JSWSTEEL', 'JSW Steel Limited', 'NSE', 'NSE_JSWSTEEL'],
      ['TATASTEEL', 'Tata Steel Limited', 'NSE', 'NSE_TATASTEEL'],
      ['ADANIPORTS', 'Adani Ports & SEZ Limited', 'NSE', 'NSE_ADANIPORTS'],
      ['ADANIENT', 'Adani Enterprises Limited', 'NSE', 'NSE_ADANIENT'],
      ['HINDALCO', 'Hindalco Industries Limited', 'NSE', 'NSE_HINDALCO'],
      ['COALINDIA', 'Coal India Limited', 'NSE', 'NSE_COALINDIA'],
      ['GRASIM', 'Grasim Industries Limited', 'NSE', 'NSE_GRASIM'],
      ['BPCL', 'Bharat Petroleum Corporation Ltd.', 'NSE', 'NSE_BPCL'],
      ['HEROMOTOCO', 'Hero MotoCorp Limited', 'NSE', 'NSE_HEROMOTOCO'],
      ['EICHERMOT', 'Eicher Motors Limited', 'NSE', 'NSE_EICHERMOT'],
      ['M&M', 'Mahindra & Mahindra Limited', 'NSE', 'NSE_M&M'],
      ['INDUSINDBK', 'IndusInd Bank Limited', 'NSE', 'NSE_INDUSINDBK'],
    ];

    return data.map((row) => GrowwInstrument(
          tradingSymbol: row[0],
          companyName: row[1],
          exchange: row[2],
          growwSymbol: row[3],
        )).toList();
  }

  /// Clears the in-memory cache (useful for testing or forced refresh).
  static void clearCache() {
    _cachedInstruments = null;
    _cacheTime = null;
  }
}
