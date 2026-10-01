import 'package:get/get.dart';
import '../models/order_model.dart';
import '../models/instrument_model.dart';

class OrderController extends GetxController {
  final RxList<OrderItem> orders = <OrderItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    isLoading.value = false;
  }

  /// Place BUY or SELL order with Groww API
  Future<bool> placePaperOrder({
    required Instrument instrument,
    required OrderTransactionType transactionType,
    required OrderType orderType,
    required int quantity,
    required double price,
    double triggerPrice = 0.0,
  }) async {
    if (quantity <= 0) {
      print('[ORDER CONTROLLER ERROR] Invalid Quantity: $quantity');
      Get.snackbar(
        'Invalid Quantity',
        'Quantity must be greater than 0',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    // Default to instrument market price if MARKET order price is 0
    double actualPrice = price;
    if (orderType == OrderType.MARKET && actualPrice <= 0) {
      actualPrice = instrument.price;
    }

    if (orderType == OrderType.LIMIT && actualPrice <= 0) {
      print('[ORDER CONTROLLER ERROR] Invalid Limit Price: $actualPrice');
      Get.snackbar(
        'Invalid Limit Price',
        'Please enter a valid price for LIMIT order',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (orderType == OrderType.SL && triggerPrice <= 0) {
      print('[ORDER CONTROLLER ERROR] Invalid Trigger Price: $triggerPrice');
      Get.snackbar(
        'Invalid Trigger Price',
        'Please enter a valid trigger price for Stop-Loss order',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    isSubmitting.value = true;
    print('[ORDER CONTROLLER] Recording order: ${transactionType.name} ${instrument.symbol}, Qty: $quantity, Price: ₹$actualPrice');
    print('[ORDER CONTROLLER] ℹ️  This controller records orders already placed via Groww API.');

    isSubmitting.value = false;

    // This method only records orders locally after Groww API confirms them.
    // Do NOT generate fake order IDs here — use RiskManagementController.confirmAndPlaceOrder()
    // which calls GrowwBrokerService for real API placement.
    print('[ORDER CONTROLLER ERROR] placePaperOrder() should not be called directly. Use RiskManagementController.confirmAndPlaceOrder() which places real Groww orders.');
    Get.snackbar(
      'Internal Error',
      'placePaperOrder() is not a real Groww order. Use the Risk Calculator to place real orders.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
    return false;
  }
}
