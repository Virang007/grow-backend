import 'package:get/get.dart';
import '../controllers/broker_controller.dart';
import '../controllers/stock_search_controller.dart';
import '../controllers/watchlist_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/portfolio_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(BrokerController());
    Get.put(StockSearchController());
    Get.put(WatchlistController());
    Get.put(OrderController());
    Get.put(PortfolioController());
  }
}
