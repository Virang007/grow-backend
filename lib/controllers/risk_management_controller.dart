import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/stock_model.dart';
import '../models/risk_calculation.dart';
import '../models/order_request.dart';
import '../models/order_result.dart';
import '../models/order_model.dart';
import '../models/broker.dart';
import '../services/broker_service.dart';
import '../services/groww_service.dart';
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
  final RxString productType = 'MIS'.obs; // Default: Intraday (MIS)
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
        final double rawSwingLow = stock.swingLow > 0 ? stock.swingLow : entry * 0.97;
        if (rawSwingLow >= entry) {
          stopLossController.text = (entry * 0.97).toStringAsFixed(2);
          _showMethodWarning('Swing Low (₹${rawSwingLow.toStringAsFixed(2)}) is not below entry. Using 3% default SL.');
        } else {
          stopLossController.text = rawSwingLow.toStringAsFixed(2);
        }
        break;

      case RiskMethod.SWING_HIGH:
        final double rawSwingHigh = stock.swingHigh > 0 ? stock.swingHigh : entry * 1.03;
        if (rawSwingHigh <= entry) {
          stopLossController.text = (entry * 1.03).toStringAsFixed(2);
          _showMethodWarning('Swing High (₹${rawSwingHigh.toStringAsFixed(2)}) is not above entry. Using 3% default SL.');
        } else {
          stopLossController.text = rawSwingHigh.toStringAsFixed(2);
        }
        break;

      case RiskMethod.PREV_CANDLE:
        if (tradeSide == TradeSide.BUY) {
          final double baseLow = stock.low > 0 ? stock.low : entry * 0.98;
          final double slVal = baseLow - buffer;
          stopLossController.text = (slVal >= entry ? entry - buffer : slVal).toStringAsFixed(2);
        } else {
          final double baseHigh = stock.high > 0 ? stock.high : entry * 1.02;
          final double slVal = baseHigh + buffer;
          stopLossController.text = (slVal <= entry ? entry + buffer : slVal).toStringAsFixed(2);
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
    if (method != RiskMethod.CUSTOM) {
      if (tradeSide == TradeSide.BUY && sl >= entry) {
        sl = entry * 0.98;
        stopLossController.text = sl.toStringAsFixed(2);
      } else if (tradeSide == TradeSide.SELL && sl <= entry) {
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
        targetPrice: entry,
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
          tp = entry + riskPerShare * 1.0;
          break;
        case RiskMethod.RR_1_2:
          tp = entry + riskPerShare * 2.0;
          break;
        case RiskMethod.RR_1_3:
          tp = entry + riskPerShare * 3.0;
          break;
        case RiskMethod.SWING_LOW:
          tp = entry + riskPerShare * 2.0;
          break;
        case RiskMethod.CUSTOM:
          tp = double.tryParse(targetController.text) ?? entry + riskPerShare * 2.0;
          break;
        default:
          tp = entry + riskPerShare * 2.0;
      }
    } else {
      switch (method) {
        case RiskMethod.RR_1_1:
          tp = entry - riskPerShare * 1.0;
          break;
        case RiskMethod.RR_1_2:
          tp = entry - riskPerShare * 2.0;
          break;
        case RiskMethod.RR_1_3:
          tp = entry - riskPerShare * 3.0;
          break;
        case RiskMethod.SWING_HIGH:
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
      tp = entry + riskPerShare * 2.0;
    }
    if (tradeSide == TradeSide.SELL && tp >= entry && method != RiskMethod.CUSTOM) {
      tp = entry - riskPerShare * 2.0;
    }
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
  // CONFIRM & PLACE ORDER — robust error handling
  // ─────────────────────────────────────────────
  Future<bool> confirmAndPlaceOrder() async {
    // 1. Validate risk calculation
    final calc = calculation.value;
    if (calc == null || !calc.isValid) {
      final err = calc?.validationError ?? 'Please check your Entry, Stop Loss, and Target values.';
      // ignore: avoid_print
      print('[RISK CTRL ERROR] Invalid risk parameters: $err');
      _showErrorDialog('Invalid Risk Parameters', err);
      return false;
    }

    // 2. Check broker is configured
    final BrokerController brokerController = Get.find<BrokerController>();

    if (brokerController.brokers.isEmpty) {
      const msg = 'No broker configured. Please go to Broker Settings and connect your Groww account first.';
      print('[RISK CTRL ERROR] No brokers found — $msg');
      _showErrorDialog('No Broker Configured', msg);
      return false;
    }

    // 3. Find connected Groww broker
    final BrokerAccount? growwBroker = brokerController.growwBroker;

    if (growwBroker == null) {
      const msg = 'Groww broker account not found. Please add your Groww credentials in Broker Settings.';
      print('[RISK CTRL ERROR] Groww broker not found');
      _showErrorDialog('Groww Not Configured', msg);
      return false;
    }

    if (growwBroker.status != BrokerStatus.connected) {
      const msg = 'Groww broker is disconnected. Please reconnect in Broker Settings (the session resets daily at 6 AM).';
      print('[RISK CTRL ERROR] Groww broker is ${growwBroker.status.name} — not connected');
      _showErrorDialog('Groww Disconnected', msg);
      return false;
    }

    if (growwBroker.apiKey.isEmpty || growwBroker.totpSecret.isEmpty) {
      const msg = 'Groww API credentials are incomplete. Please re-enter your TOTP Token and TOTP Secret in Broker Settings.';
      print('[RISK CTRL ERROR] Groww credentials missing');
      _showErrorDialog('Missing Credentials', msg);
      return false;
    }

    // 4. Begin submission
    isSubmitting.value = true;

    print('==================================================');
    print('[RISK CTRL] Placing order: ${stock.symbol} ${tradeSide.name}');
    print('[RISK CTRL] Entry=₹${calc.entryPrice} | SL=₹${calc.stopLoss} | TP=₹${calc.targetPrice} | Qty=${calc.quantity} | Method=${calc.riskMethod.name}');
    print('[RISK CTRL] Broker: ${growwBroker.name} | Status: ${growwBroker.status.name}');
    print('[RISK CTRL] API Key (masked): ${growwBroker.apiKey.length > 8 ? growwBroker.apiKey.substring(0, 8) : growwBroker.apiKey}****');
    print('==================================================');

    final BrokerService brokerService = GrowwBrokerService(
      apiKey: growwBroker.apiKey,
      apiSecret: growwBroker.apiSecret,
      totpSecret: growwBroker.totpSecret,
      savedAccessToken: growwBroker.accessToken.isNotEmpty
          ? growwBroker.accessToken
          : brokerController.currentAccessToken.value,
      baseUrl: growwBroker.baseUrl.isNotEmpty ? growwBroker.baseUrl : 'https://api.groww.in',
    );

    final request = OrderRequest(
      instrumentToken: stock.instrumentToken,
      symbol: stock.symbol,
      name: stock.name,
      exchange: stock.exchange,
      riskCalculation: calc,
      productType: productType.value,
    );

    // 5. Place order with full exception guard
    OrderResult result;
    try {
      result = await brokerService.placeRiskManagedOrder(request);
    } catch (e, st) {
      isSubmitting.value = false;
      final errMsg = 'Unexpected error while placing order:\n$e';
      print('[RISK CTRL EXCEPTION] $e');
      print('[RISK CTRL EXCEPTION] StackTrace: $st');
      _showErrorDialog('Order Failed', errMsg);
      return false;
    }

    isSubmitting.value = false;

    // 6. Handle result
    if (result.isSuccess) {
      print('[RISK CTRL SUCCESS] OrderID=${result.orderId} | ${result.message}');

      // Record in local order history
      try {
        final OrderController orderController = Get.find<OrderController>();
        orderController.orders.insert(0, OrderItem(
          orderId: result.orderId,
          instrumentToken: stock.instrumentToken,
          symbol: stock.symbol,
          name: stock.name,
          transactionType: tradeSide == TradeSide.BUY
              ? OrderTransactionType.BUY
              : OrderTransactionType.SELL,
          orderType: OrderType.LIMIT,
          quantity: calc.quantity,
          price: calc.entryPrice,
          triggerPrice: calc.stopLoss,
          status: OrderStatus.PENDING,
          timestamp: DateTime.now(),
        ));
        print('[RISK CTRL] Order recorded in local history');
      } catch (e) {
        // Non-fatal — local history recording failed, but Groww order was placed
        print('[RISK CTRL WARNING] Could not record in local order history: $e');
      }

      // Show animated success dialog
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
      print('[RISK CTRL ERROR] Broker rejected: ${result.message}');
      _showErrorDialog('Order Rejected', result.message);
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Error Dialog (proper modal, not snackbar)
  // ─────────────────────────────────────────────
  void _showErrorDialog(String title, String message) {
    // Dismiss any existing dialogs first
    if (Get.isDialogOpen == true) Get.back();

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  void onClose() {
    entryController.dispose();
    quantityController.dispose();
    stopLossController.dispose();
    targetController.dispose();
    bufferController.dispose();
    super.onClose();
  }
}
