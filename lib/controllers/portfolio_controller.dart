import 'package:get/get.dart';
import '../models/holding_model.dart';
import '../services/megabull_api_service.dart';

class PortfolioController extends GetxController {
  /// Virtual cash balance comes from the API. Null means not yet loaded.
  final Rxn<double> virtualBalance = Rxn<double>();
  final RxList<HoldingItem> holdings = <HoldingItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasApiError = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPortfolio();
  }

  Future<void> fetchPortfolio() async {
    isLoading.value = true;
    hasApiError.value = false;
    try {
      final apiHoldings = await MegaBullApiService.fetchHoldings();
      // Only populate from real API data. Never load fake/demo data.
      holdings.assignAll(apiHoldings);
    } catch (_) {
      hasApiError.value = true;
    }
    isLoading.value = false;
  }

  double get totalInvested =>
      holdings.fold(0.0, (sum, item) => sum + item.investedValue);

  double get currentValue =>
      holdings.fold(0.0, (sum, item) => sum + item.currentValue);

  double get totalPnl => currentValue - totalInvested;

  double get totalPnlPercent =>
      totalInvested > 0 ? (totalPnl / totalInvested) * 100 : 0.0;

  double get totalPortfolioValue => currentValue;

  void updatePortfolioAfterBuy(String token, String symbol, String name, int qty, double price) {
    final existingIndex = holdings.indexWhere((h) => h.symbol == symbol);
    if (existingIndex >= 0) {
      final existing = holdings[existingIndex];
      final newQty = existing.quantity + qty;
      final newAvgPrice = ((existing.quantity * existing.averagePrice) + (qty * price)) / newQty;
      holdings[existingIndex] = HoldingItem(
        instrumentToken: token,
        symbol: symbol,
        name: name,
        quantity: newQty,
        averagePrice: newAvgPrice,
        currentPrice: price,
      );
    } else {
      holdings.add(HoldingItem(
        instrumentToken: token,
        symbol: symbol,
        name: name,
        quantity: qty,
        averagePrice: price,
        currentPrice: price,
      ));
    }
  }

  void updatePortfolioAfterSell(String symbol, int qty, double price) {
    final existingIndex = holdings.indexWhere((h) => h.symbol == symbol);
    if (existingIndex >= 0) {
      final existing = holdings[existingIndex];
      if (qty >= existing.quantity) {
        holdings.removeAt(existingIndex);
      } else {
        holdings[existingIndex] = HoldingItem(
          instrumentToken: existing.instrumentToken,
          symbol: existing.symbol,
          name: existing.name,
          quantity: existing.quantity - qty,
          averagePrice: existing.averagePrice,
          currentPrice: price,
        );
      }
    }
  }
}
