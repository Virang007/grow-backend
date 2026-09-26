import 'risk_calculation.dart';

class OrderRequest {
  final String instrumentToken;
  final String symbol;
  final String name;
  final String exchange;
  final RiskCalculation riskCalculation;
  final String productType; // CNC, MIS, Bracket

  OrderRequest({
    required this.instrumentToken,
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.riskCalculation,
    this.productType = 'MIS',
  });

  Map<String, dynamic> toJson() {
    return {
      'instrumentToken': instrumentToken,
      'tradingSymbol': symbol,
      'exchange': exchange,
      'transactionType': riskCalculation.tradeSide.name,
      'quantity': riskCalculation.quantity,
      'entryPrice': riskCalculation.entryPrice,
      'stopLossPrice': riskCalculation.stopLoss,
      'targetPrice': riskCalculation.targetPrice,
      'productType': productType,
    };
  }
}
