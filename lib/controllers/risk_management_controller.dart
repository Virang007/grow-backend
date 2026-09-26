import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/stock_model.dart';
import '../models/risk_calculation.dart';
import '../models/order_request.dart';
import '../models/order_result.dart';
import '../models/order_model.dart';
import '../services/broker_service.dart';
import '../services/megabull_broker_service.dart';
import '../services/dhan_broker_service.dart';
import '../controllers/broker_controller.dart';
import '../controllers/order_controller.dart';
import '../widgets/order_success_dialog.dart';

class RiskManagementController extends GetxController {
  late Stock stock;
  late TradeSide tradeSide;

  final TextEditingController entryController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '10');
  final TextEditingController stopLossController = TextEditingController();
  final TextEditingController targetController = TextEditingController();
  final TextEditingController bufferController = TextEditingController(text: '2.00');

  final Rx<RiskMethod> selectedMethod = RiskMethod.RR_1_2.obs;
  final RxBool isSubmitting = false.obs;
  final Rxn<RiskCalculation> calculation = Rxn<RiskCalculation>();

  // ─────────────────────────────────────────────
  // INITIALIZE
  // ─────────────────────────────────────────────
  void initialize(Stock selectedStock, TradeSide side) {
    stock = selectedStock;
    tradeSide = side;

    final double price = stock.price;
    entryController.text = price.toStringAsFixed(2);
    quantityController.text = '10';

    // Default SL: 2% below entry for BUY, 2% above for SELL
    _applyDefaultSL(price);
    recalculate();
  }

  void _applyDefaultSL(double entry) {
    if (tradeSide == TradeSide.BUY) {
      stopLossController.text = (entry * 0.98).toStringAsFixed(2);
    } else {
      stopLossController.text = (entry * 1.02).toStringAsFixed(2);
    }
  }

  // ─────────────────────────────────────────────
  // SET RISK METHOD (chip tap)
  // ─────────────────────────────────────────────
  void setRiskMethod(RiskMethod method) {
    selectedMethod.value = method;
    final double entry = double.tryParse(entryController.text) ?? stock.price;
    final double buffer = double.tryParse(bufferController.text) ?? 2.0;

    switch (method) {
      case RiskMethod.SWING_LOW:
        // BUY: SL = swing low (must be below entry)
        final double rawSwingLow = stock.swingLow > 0 ? stock.swingLow : entry * 0.97;
        if (rawSwingLow >= entry) {
          stopLossController.text = (entry * 0.97).toStringAsFixed(2);
          _showMethodWarning('Swing Low (₹${rawSwingLow.toStringAsFixed(2)}) is not below entry. Using 3% default SL.');
        } else {
          stopLossController.text = rawSwingLow.toStringAsFixed(2);
        }
        break;

      case RiskMethod.SWING_HIGH:
        // SELL: SL = swing high (must be above entry)
        final double rawSwingHigh = stock.swingHigh > 0 ? stock.swingHigh : entry * 1.03;
        if (rawSwingHigh <= entry) {
          stopLossController.text = (entry * 1.03).toStringAsFixed(2);
          _showMethodWarning('Swing High (₹${rawSwingHigh.toStringAsFixed(2)}) is not above entry. Using 3% default SL.');
        } else {
          stopLossController.text = rawSwingHigh.toStringAsFixed(2);
        }
        break;

      case RiskMethod.PREV_CANDLE:
        // BUY: Previous Candle Low - Buffer
        // SELL: Previous Candle High + Buffer
        if (tradeSide == TradeSide.BUY) {
          final double baseLow = stock.low > 0 ? stock.low : entry * 0.98;
          final double slVal = baseLow - buffer;
          if (slVal >= entry) {
            stopLossController.text = (entry - buffer).toStringAsFixed(2);
          } else {
            stopLossController.text = slVal.toStringAsFixed(2);
          }
        } else {
          final double baseHigh = stock.high > 0 ? stock.high : entry * 1.02;
          final double slVal = baseHigh + buffer;
          if (slVal <= entry) {
            stopLossController.text = (entry + buffer).toStringAsFixed(2);
          } else {
            stopLossController.text = slVal.toStringAsFixed(2);
          }
        }
        break;

      case RiskMethod.CUSTOM:
        // Keep existing SL — user will edit manually
        break;

      default:
        // RR_1_1, RR_1_2, RR_1_3 — keep current SL, only TP changes
        break;
    }

    recalculate();
  }

  void _showMethodWarning(String msg) {
    Get.snackbar(
      'Method Warning',
      msg,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFF59E0B),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      icon: const Icon(Icons.warning_amber, color: Colors.white),
    );
  }

  // ─────────────────────────────────────────────
  // RECALCULATE SL / TP
  // ─────────────────────────────────────────────
  void recalculate() {
    final double entry = double.tryParse(entryController.text) ?? stock.price;
    final int qty = _parseQty();
    double sl = double.tryParse(stopLossController.text) ?? _defaultSL(entry);
    final RiskMethod method = selectedMethod.value;

    // ── Validate SL direction ──────────────────────────
    // Auto-correct only when using a non-custom method
    if (method != RiskMethod.CUSTOM) {
      if (tradeSide == TradeSide.BUY && sl >= entry) {
        // SL must be below entry for BUY
        sl = entry * 0.98;
        stopLossController.text = sl.toStringAsFixed(2);
      } else if (tradeSide == TradeSide.SELL && sl <= entry) {
        // SL must be above entry for SELL
        sl = entry * 1.02;
        stopLossController.text = sl.toStringAsFixed(2);
      }
    }

    // ── Compute risk per share ─────────────────────────
    final double riskPerShare = tradeSide == TradeSide.BUY
        ? (entry > sl ? entry - sl : 0.0)
        : (sl > entry ? sl - entry : 0.0);

    // Guard: no risk = no valid trade
    if (riskPerShare <= 0 && method != RiskMethod.CUSTOM) {
      calculation.value = RiskCalculation(
        tradeSide: tradeSide,
        entryPrice: entry,
        stopLoss: sl,
        targetPrice: entry, // TP = Entry = invalid, will show error
        quantity: qty,
        riskMethod: method,
      );
      return;
    }

    // ── Compute target price ───────────────────────────
    double tp;

    if (tradeSide == TradeSide.BUY) {
      switch (method) {
        case RiskMethod.RR_1_1:
          tp = entry + riskPerShare * 1.0; // 1:1 — reward = risk
          break;
        case RiskMethod.RR_1_2:
          tp = entry + riskPerShare * 2.0; // 1:2 — reward = 2× risk
          break;
        case RiskMethod.RR_1_3:
          tp = entry + riskPerShare * 3.0; // 1:3 — reward = 3× risk
          break;
        case RiskMethod.SWING_LOW:
          // BUY Swing: SL = swing low, TP = entry + 2× risk (1:2)
          tp = entry + riskPerShare * 2.0;
          break;
        case RiskMethod.CUSTOM:
          // User sets TP manually — just read field or fallback 1:2
          tp = double.tryParse(targetController.text) ?? entry + riskPerShare * 2.0;
          break;
        default:
          tp = entry + riskPerShare * 2.0;
      }
    } else {
      // ── SELL / SHORT ───────────────────────────────
      // Entry > SL is WRONG for SELL — SL is ABOVE entry
      // TP is BELOW entry
      switch (method) {
        case RiskMethod.RR_1_1:
          tp = entry - riskPerShare * 1.0; // Price drops by risk amount
          break;
        case RiskMethod.RR_1_2:
          tp = entry - riskPerShare * 2.0;
          break;
        case RiskMethod.RR_1_3:
          tp = entry - riskPerShare * 3.0;
          break;
        case RiskMethod.SWING_HIGH:
          // SELL Swing: SL = swing high (above entry), TP = entry - 2× risk
          tp = entry - riskPerShare * 2.0;
          break;
        case RiskMethod.CUSTOM:
          tp = double.tryParse(targetController.text) ?? entry - riskPerShare * 2.0;
          break;
        default:
          tp = entry - riskPerShare * 2.0;
      }
    }

    // ── Guard TP on wrong side ─────────────────────────
    if (tradeSide == TradeSide.BUY && tp <= entry && method != RiskMethod.CUSTOM) {
      tp = entry + riskPerShare * 2.0; // Force valid
    }
    if (tradeSide == TradeSide.SELL && tp >= entry && method != RiskMethod.CUSTOM) {
      tp = entry - riskPerShare * 2.0; // Force valid
    }
    // Guard: TP must be > 0
    if (tp <= 0) tp = entry * 0.5;

    // ── Update target field (except CUSTOM) ────────────
    if (method != RiskMethod.CUSTOM) {
      targetController.text = tp.toStringAsFixed(2);
    }

    calculation.value = RiskCalculation(
      tradeSide: tradeSide,
      entryPrice: entry,
      stopLoss: sl,
      targetPrice: tp,
      quantity: qty,
      riskMethod: method,
    );
  }

  int _parseQty() {
    final int parsed = int.tryParse(quantityController.text) ?? 1;
    return parsed > 0 ? parsed : 1;
  }

  double _defaultSL(double entry) {
    return tradeSide == TradeSide.BUY ? entry * 0.98 : entry * 1.02;
  }

  // ─────────────────────────────────────────────
  // CONFIRM & PLACE ORDER
  // ─────────────────────────────────────────────
  Future<bool> confirmAndPlaceOrder() async {
    final calc = calculation.value;
    if (calc == null || !calc.isValid) {
      final err = calc?.validationError ?? 'Please check your Entry, Stop Loss, and Target values.';
      print('[RISK CONTROLLER ERROR] Invalid risk parameters: $err');
      Get.snackbar(
        'Invalid Risk Parameters',
        err,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
      return false;
    }

    isSubmitting.value = true;
    print('[RISK CONTROLLER] Processing order: ${stock.symbol} ${tradeSide.name}');
    print('[RISK CONTROLLER] Entry=₹${calc.entryPrice} | SL=₹${calc.stopLoss} | TP=₹${calc.targetPrice} | Qty=${calc.quantity} | Method=${calc.riskMethod.name}');

    final BrokerController brokerController = Get.find<BrokerController>();
    final activeBroker = brokerController.brokers.firstWhere(
      (b) => b.status.name == 'connected',
      orElse: () => brokerController.brokers.first,
    );
    print('[RISK CONTROLLER] Active broker: ${activeBroker.name} (${activeBroker.id})');

    BrokerService brokerService;
    if (activeBroker.id == 'dhan') {
      brokerService = DhanBrokerService(
        clientId: activeBroker.accountId.isNotEmpty ? activeBroker.accountId : 'DHAN-DEMO',
        accessToken: activeBroker.apiSecret,
      );
    } else {
      brokerService = MegaBullBrokerService(
        apiKey: activeBroker.apiKey.isNotEmpty ? activeBroker.apiKey : 'd35a226d-5b3a-44d7-a954-2db87bd069a7',
        baseUrl: activeBroker.baseUrl.isNotEmpty ? activeBroker.baseUrl : 'https://api.megabull.in',
      );
    }

    final request = OrderRequest(
      instrumentToken: stock.instrumentToken,
      symbol: stock.symbol,
      name: stock.name,
      exchange: stock.exchange,
      riskCalculation: calc,
    );

    final OrderResult result = await brokerService.placeRiskManagedOrder(request);
    isSubmitting.value = false;

    if (result.isSuccess) {
      print('[RISK CONTROLLER SUCCESS] OrderID=${result.orderId}');

      final OrderController orderController = Get.find<OrderController>();
      orderController.orders.insert(0, OrderItem(
        orderId: result.orderId,
        instrumentToken: stock.instrumentToken,
        symbol: stock.symbol,
        name: stock.name,
        transactionType: tradeSide == TradeSide.BUY ? OrderTransactionType.BUY : OrderTransactionType.SELL,
        orderType: OrderType.LIMIT,
        quantity: calc.quantity,
        price: calc.entryPrice,
        triggerPrice: calc.stopLoss,
        status: OrderStatus.PENDING,
        timestamp: DateTime.now(),
      ));

      final ctx = Get.context;
      if (ctx != null && ctx.mounted) {
        await OrderSuccessDialog.show(
          context: ctx,
          result: result,
          calculation: calc,
          stock: stock,
          tradeSide: tradeSide,
        );
      }
      return true;
    } else {
      print('[RISK CONTROLLER ERROR] Broker rejected: ${result.message}');
      Get.snackbar(
        'Order Rejected by Broker',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
        icon: const Icon(Icons.cancel_outlined, color: Colors.white),
      );
      return false;
    }
  }

  @override
  void onClose() {
    entryController.dispose();
    quantityController.dispose();
    stopLossController.dispose();
    targetController.dispose();
    super.onClose();
  }
}
