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

  final Rx<RiskMethod> selectedMethod = RiskMethod.RR_1_2.obs;
  final RxBool isSubmitting = false.obs;

  final Rxn<RiskCalculation> calculation = Rxn<RiskCalculation>();

  void initialize(Stock selectedStock, TradeSide side) {
    stock = selectedStock;
    tradeSide = side;

    entryController.text = stock.price.toStringAsFixed(2);
    quantityController.text = '10';

    // Set initial SL based on trade direction
    if (tradeSide == TradeSide.BUY) {
      final double defaultSl = stock.price * 0.98; // 2% risk by default
      stopLossController.text = defaultSl.toStringAsFixed(2);
    } else {
      final double defaultSl = stock.price * 1.02; // 2% risk by default
      stopLossController.text = defaultSl.toStringAsFixed(2);
    }

    recalculate();
  }

  void setRiskMethod(RiskMethod method) {
    selectedMethod.value = method;

    final double entry = double.tryParse(entryController.text) ?? stock.price;

    if (method == RiskMethod.SWING_LOW) {
      final double swingLowPrice = stock.swingLow > 0 ? stock.swingLow : entry * 0.97;
      stopLossController.text = swingLowPrice.toStringAsFixed(2);
    } else if (method == RiskMethod.SWING_HIGH) {
      final double swingHighPrice = stock.swingHigh > 0 ? stock.swingHigh : entry * 1.03;
      stopLossController.text = swingHighPrice.toStringAsFixed(2);
    }

    recalculate();
  }

  void recalculate() {
    final double entry = double.tryParse(entryController.text) ?? stock.price;
    final int parsedQty = int.tryParse(quantityController.text) ?? 1;
    final int qty = parsedQty > 0 ? parsedQty : 1;
    double sl = double.tryParse(stopLossController.text) ?? (tradeSide == TradeSide.BUY ? entry * 0.98 : entry * 1.02);

    double tp = 0.0;

    if (tradeSide == TradeSide.BUY) {
      final double riskPerShare = entry > sl ? entry - sl : 0.0;
      switch (selectedMethod.value) {
        case RiskMethod.RR_1_1:
          tp = entry + riskPerShare;
          break;
        case RiskMethod.RR_1_2:
        case RiskMethod.SWING_LOW:
          tp = entry + (riskPerShare * 2.0);
          break;
        case RiskMethod.RR_1_3:
          tp = entry + (riskPerShare * 3.0);
          break;
        default:
          tp = double.tryParse(targetController.text) ?? entry + (riskPerShare * 2.0);
          break;
      }
    } else {
      // SELL / SHORT
      final double riskPerShare = sl > entry ? sl - entry : 0.0;
      switch (selectedMethod.value) {
        case RiskMethod.RR_1_1:
          tp = entry - riskPerShare;
          break;
        case RiskMethod.RR_1_2:
        case RiskMethod.SWING_HIGH:
          tp = entry - (riskPerShare * 2.0);
          break;
        case RiskMethod.RR_1_3:
          tp = entry - (riskPerShare * 3.0);
          break;
        default:
          tp = double.tryParse(targetController.text) ?? entry - (riskPerShare * 2.0);
          break;
      }
    }

    if (selectedMethod.value != RiskMethod.CUSTOM) {
      targetController.text = tp.toStringAsFixed(2);
    }

    calculation.value = RiskCalculation(
      tradeSide: tradeSide,
      entryPrice: entry,
      stopLoss: sl,
      targetPrice: tp,
      quantity: qty,
      riskMethod: selectedMethod.value,
    );
  }

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
      );
      return false;
    }

    isSubmitting.value = true;
    print('[RISK CONTROLLER] Processing order confirmation for ${stock.symbol} ${tradeSide.name}');

    // Get active broker implementation
    final BrokerController brokerController = Get.find<BrokerController>();
    final activeBroker = brokerController.brokers.firstWhere(
      (b) => b.status.name == 'connected',
      orElse: () => brokerController.brokers.first,
    );

    print('[RISK CONTROLLER] Active broker selected: ${activeBroker.name} (${activeBroker.id})');

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
      print('[RISK CONTROLLER SUCCESS] Broker order placed successfully: OrderID=${result.orderId}');
      // Save order to history
      final OrderController orderController = Get.find<OrderController>();
      orderController.orders.insert(
        0,
        OrderItem(
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
        ),
      );

      // Show premium success dialog
      final context = Get.context;
      if (context != null && context.mounted) {
        await OrderSuccessDialog.show(
          context: context,
          result: result,
          calculation: calc,
          stock: stock,
          tradeSide: tradeSide,
        );
      }

      return true;
    } else {
      print('[RISK CONTROLLER ERROR] Broker rejected order: ${result.message}');
      Get.snackbar(
        'Broker Order Failed',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
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
