class Stock {
  final String symbol;
  final String name;
  double price;
  double change;
  double percentChange;
  final double open;
  final double high;
  final double low;
  final String marketCap;
  final double peRatio;
  final double volume;
  final List<double> chartData;
  bool isSaved;

  Stock({
    required this.symbol,
    required this.name,
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
    this.isSaved = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
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
      'isSaved': isSaved,
    };
  }

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      change: (json['change'] as num?)?.toDouble() ?? 0.0,
      percentChange: (json['percentChange'] as num?)?.toDouble() ?? 0.0,
      open: (json['open'] as num?)?.toDouble() ?? 0.0,
      high: (json['high'] as num?)?.toDouble() ?? 0.0,
      low: (json['low'] as num?)?.toDouble() ?? 0.0,
      marketCap: json['marketCap'] ?? '\$0.0B',
      peRatio: (json['peRatio'] as num?)?.toDouble() ?? 0.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
      chartData: (json['chartData'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      isSaved: json['isSaved'] ?? false,
    );
  }
}
