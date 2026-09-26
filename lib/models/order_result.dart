class OrderResult {
  final bool isSuccess;
  final String orderId;
  final String? slOrderId;
  final String? tpOrderId;
  final String message;
  final DateTime timestamp;

  OrderResult({
    required this.isSuccess,
    required this.orderId,
    this.slOrderId,
    this.tpOrderId,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'orderId': orderId,
      'slOrderId': slOrderId,
      'tpOrderId': tpOrderId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
