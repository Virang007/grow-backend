class Instrument {
  final String instrumentToken;
  final String symbol;
  final String name;
  final String exchange; // NSE or BSE
  final double price;
  final double change;
  final double percentChange;
  final double open;
  final double high;
  final double low;
  final String marketCap;
  final double peRatio;
  final double volume;
  final List<double> chartData;

  Instrument({
    required this.instrumentToken,
    required this.symbol,
    required this.name,
    this.exchange = 'NSE',
    required this.price,
    required this.change,
    required this.percentChange,
    required this.open,
    required this.high,
    required this.low,
    required this.marketCap,
    required this.peRatio,
    required this.volume,
    required this.chartData,
  });

  String get displaySymbol {
    if (symbol.endsWith('.NS') || symbol.endsWith('.BO')) {
      return symbol.substring(0, symbol.length - 3);
    }
    return symbol;
  }

  Map<String, dynamic> toJson() {
    return {
      'instrumentToken': instrumentToken,
      'symbol': symbol,
      'name': name,
      'exchange': exchange,
      'price': price,
      'change': change,
      'percentChange': percentChange,
      'open': open,
      'high': high,
      'low': low,
      'marketCap': marketCap,
      'peRatio': peRatio,
      'volume': volume,
      'chartData': chartData,
    };
  }

  factory Instrument.fromJson(Map<String, dynamic> json) {
    final String parsedToken = (json['instrumentToken'] ??
            json['instrument_token'] ??
            json['token'] ??
            json['scriptId'] ??
            json['script_id'] ??
            json['securityId'] ??
            json['security_id'] ??
            json['id'] ??
            '')
        .toString();

    final String parsedSymbol = (json['tradingSymbol'] ??
            json['trading_symbol'] ??
            json['symbol'] ??
            json['scriptName'] ??
            json['displaySymbol'] ??
            '')
        .toString();

    return Instrument(
      instrumentToken: parsedToken.isNotEmpty ? parsedToken : parsedSymbol,
      symbol: parsedSymbol,
      name: (json['name'] ?? json['companyName'] ?? parsedSymbol).toString(),
      exchange: (json['exchange'] ?? 'NSE').toString(),
      price: (json['price'] as num?)?.toDouble() ??
          (json['lastPrice'] as num?)?.toDouble() ??
          0.0,
      change: (json['change'] as num?)?.toDouble() ?? 0.0,
      percentChange: (json['percentChange'] as num?)?.toDouble() ?? 0.0,
      open: (json['open'] as num?)?.toDouble() ?? 0.0,
      high: (json['high'] as num?)?.toDouble() ?? 0.0,
      low: (json['low'] as num?)?.toDouble() ?? 0.0,
      marketCap: (json['marketCap'] ?? '₹1,50,000 Cr').toString(),
      peRatio: (json['peRatio'] as num?)?.toDouble() ?? 24.5,
      volume: (json['volume'] as num?)?.toDouble() ?? 1000000.0,
      chartData: (json['chartData'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }
}
