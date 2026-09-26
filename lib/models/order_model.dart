enum OrderTransactionType { BUY, SELL }
enum OrderType { MARKET, LIMIT, SL }
enum OrderStatus { PENDING, EXECUTED, CANCELLED, FAILED }

class OrderItem {
  final String orderId;
  final String instrumentToken;
  final String symbol;
  final String name;
  final OrderTransactionType transactionType;
  final OrderType orderType;
  final int quantity;
  final double price;
  final double triggerPrice;
  final OrderStatus status;
  final DateTime timestamp;
  final String? failureReason;

  OrderItem({
    required this.orderId,
    required this.instrumentToken,
    required this.symbol,
    required this.name,
    required this.transactionType,
    required this.orderType,
    required this.quantity,
    required this.price,
    this.triggerPrice = 0.0,
    required this.status,
    required this.timestamp,
    this.failureReason,
  });

  String get displaySymbol {
    if (symbol.endsWith('.NS') || symbol.endsWith('.BO')) {
      return symbol.substring(0, symbol.length - 3);
    }
    return symbol;
  }

  double get totalValue => quantity * price;

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'instrumentToken': instrumentToken,
      'symbol': symbol,
      'name': name,
      'transactionType': transactionType.name,
      'orderType': orderType.name,
      'quantity': quantity,
      'price': price,
      'triggerPrice': triggerPrice,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'failureReason': failureReason,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      orderId: json['orderId'] ?? json['id'] ?? '',
      instrumentToken: json['instrumentToken'] ?? json['token'] ?? '',
      symbol: json['symbol'] ?? json['tradingSymbol'] ?? '',
      name: json['name'] ?? json['companyName'] ?? json['symbol'] ?? '',
      transactionType: OrderTransactionType.values.firstWhere(
        (e) => e.name == json['transactionType'],
        orElse: () => OrderTransactionType.BUY,
      ),
      orderType: OrderType.values.firstWhere(
        (e) => e.name == json['orderType'],
        orElse: () => OrderType.MARKET,
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      triggerPrice: (json['triggerPrice'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.EXECUTED,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      failureReason: json['failureReason'],
    );
  }
}
