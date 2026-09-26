enum TradeSide { BUY, SELL }
enum RiskMethod { RR_1_1, RR_1_2, RR_1_3, SWING_LOW, SWING_HIGH, CUSTOM }

class RiskCalculation {
  final TradeSide tradeSide;
  final double entryPrice;
  final double stopLoss;
  final double targetPrice;
  final int quantity;
  final RiskMethod riskMethod;

  RiskCalculation({
    required this.tradeSide,
    required this.entryPrice,
    required this.stopLoss,
    required this.targetPrice,
    required this.quantity,
    required this.riskMethod,
  });

  bool get isBuy => tradeSide == TradeSide.BUY;

  double get riskPerShare {
    if (isBuy) {
      return entryPrice > stopLoss ? entryPrice - stopLoss : 0.0;
    } else {
      return stopLoss > entryPrice ? stopLoss - entryPrice : 0.0;
    }
  }

  double get rewardPerShare {
    if (isBuy) {
      return targetPrice > entryPrice ? targetPrice - entryPrice : 0.0;
    } else {
      return entryPrice > targetPrice ? entryPrice - targetPrice : 0.0;
    }
  }

  double get totalRisk => riskPerShare * quantity;

  double get potentialProfit => rewardPerShare * quantity;

  double get estimatedOrderValue => entryPrice * quantity;

  String get formattedRatio {
    if (riskPerShare <= 0) return '0 : 0';
    final double ratio = rewardPerShare / riskPerShare;
    return '1 : ${ratio.toStringAsFixed(1)}';
  }

  bool get isValid {
    if (entryPrice <= 0 || quantity <= 0 || stopLoss <= 0 || targetPrice <= 0) {
      return false;
    }
    if (isBuy) {
      return stopLoss < entryPrice && targetPrice > entryPrice;
    } else {
      return stopLoss > entryPrice && targetPrice < entryPrice;
    }
  }

  String? get validationError {
    if (entryPrice <= 0) return 'Entry price must be greater than ₹0';
    if (quantity <= 0) return 'Quantity must be at least 1 share';
    if (stopLoss <= 0) return 'Stop Loss must be greater than ₹0';
    if (targetPrice <= 0) return 'Target price must be greater than ₹0';

    if (isBuy) {
      if (stopLoss >= entryPrice) {
        return 'For BUY orders, Stop Loss must be BELOW Entry Price (₹${entryPrice.toStringAsFixed(2)})';
      }
      if (targetPrice <= entryPrice) {
        return 'For BUY orders, Target must be ABOVE Entry Price (₹${entryPrice.toStringAsFixed(2)})';
      }
    } else {
      if (stopLoss <= entryPrice) {
        return 'For SELL orders, Stop Loss must be ABOVE Entry Price (₹${entryPrice.toStringAsFixed(2)})';
      }
      if (targetPrice >= entryPrice) {
        return 'For SELL orders, Target must be BELOW Entry Price (₹${entryPrice.toStringAsFixed(2)})';
      }
    }
    return null;
  }
}
