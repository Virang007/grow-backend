class HoldingItem {
  final String instrumentToken;
  final String symbol;
  final String name;
  final int quantity;
  final double averagePrice;
  double currentPrice;

  HoldingItem({
    required this.instrumentToken,
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
  });

  String get displaySymbol {
    if (symbol.endsWith('.NS') || symbol.endsWith('.BO')) {
      return symbol.substring(0, symbol.length - 3);
    }
    return symbol;
  }

  double get investedValue => quantity * averagePrice;
  double get currentValue => quantity * currentPrice;
  double get pnl => currentValue - investedValue;
  double get pnlPercent =>
      investedValue > 0 ? (pnl / investedValue) * 100 : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'instrumentToken': instrumentToken,
      'symbol': symbol,
      'name': name,
      'quantity': quantity,
      'averagePrice': averagePrice,
      'currentPrice': currentPrice,
    };
  }

  factory HoldingItem.fromJson(Map<String, dynamic> json) {
    return HoldingItem(
      instrumentToken: json['instrumentToken'] ?? json['token'] ?? '',
      symbol: json['symbol'] ?? json['tradingSymbol'] ?? '',
      name: json['name'] ?? json['companyName'] ?? json['symbol'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      averagePrice: (json['averagePrice'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
