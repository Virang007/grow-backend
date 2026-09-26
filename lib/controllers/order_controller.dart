import 'package:get/get.dart';
import '../models/order_model.dart';
import '../models/instrument_model.dart';
import '../services/megabull_api_service.dart';

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
    isLoading.value = true;
    final fetched = await MegaBullApiService.fetchPaperOrders();
    if (fetched.isNotEmpty) {
      orders.assignAll(fetched);
    }
    isLoading.value = false;
  }

  /// Place Paper BUY or SELL order with MegaBull API
  Future<bool> placePaperOrder({
    required Instrument instrument,
    required OrderTransactionType transactionType,
    required OrderType orderType,
    required int quantity,
    required double price,
    double triggerPrice = 0.0,
  }) async {
    if (quantity <= 0) {
      Get.snackbar(
        'Invalid Quantity',
        'Quantity must be greater than 0',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (orderType == OrderType.LIMIT && price <= 0) {
      Get.snackbar(
        'Invalid Limit Price',
        'Please enter a valid price for LIMIT order',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (orderType == OrderType.SL && triggerPrice <= 0) {
      Get.snackbar(
        'Invalid Trigger Price',
        'Please enter a valid trigger price for Stop-Loss order',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    isSubmitting.value = true;

    final result = await MegaBullApiService.placePaperOrder(
      instrumentToken: instrument.instrumentToken,
      symbol: instrument.symbol,
      name: instrument.name,
      transactionType: transactionType,
      orderType: orderType,
      quantity: quantity,
      price: price,
      triggerPrice: triggerPrice,
    );

    isSubmitting.value = false;

    if (result['success'] == true) {
      final newOrder = OrderItem(
        orderId: result['orderId'] ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}',
        instrumentToken: instrument.instrumentToken,
        symbol: instrument.symbol,
        name: instrument.name,
        transactionType: transactionType,
        orderType: orderType,
        quantity: quantity,
        price: price,
        triggerPrice: triggerPrice,
        status: OrderStatus.EXECUTED,
        timestamp: DateTime.now(),
      );

      orders.insert(0, newOrder);

      Get.snackbar(
        'Order Executed!',
        '${transactionType.name} $quantity shares of ${instrument.displaySymbol} at ₹${price.toStringAsFixed(2)}',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } else {
      Get.snackbar(
        'Order Failed',
        result['message'] ?? 'Unable to place paper order.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}
