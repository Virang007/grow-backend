import 'package:get/get.dart';
import '../models/holding_model.dart';
import '../services/megabull_api_service.dart';

class PortfolioController extends GetxController {
  final RxDouble virtualBalance = 1000000.00.obs; // Initial ₹10,00,000 virtual cash balance
  final RxList<HoldingItem> holdings = <HoldingItem>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPortfolio();
  }

  Future<void> fetchPortfolio() async {
    isLoading.value = true;
    final apiHoldings = await MegaBullApiService.fetchHoldings();
    if (apiHoldings.isNotEmpty) {
      holdings.assignAll(apiHoldings);
    } else if (holdings.isEmpty) {
      _loadDefaultPaperHoldings();
    }
    isLoading.value = false;
  }

  void _loadDefaultPaperHoldings() {
    holdings.assignAll([
      HoldingItem(
        instrumentToken: '738561',
        symbol: 'RELIANCE.NS',
        name: 'Reliance Industries Ltd.',
        quantity: 15,
        averagePrice: 2950.00,
        currentPrice: 2985.40,
      ),
      HoldingItem(
        instrumentToken: '2953217',
        symbol: 'TCS.NS',
        name: 'Tata Consultancy Services',
        quantity: 10,
        averagePrice: 4300.00,
        currentPrice: 4280.00,
      ),
      HoldingItem(
        instrumentToken: '408065',
        symbol: 'INFY.NS',
        name: 'Infosys Limited',
        quantity: 25,
        averagePrice: 1850.00,
        currentPrice: 1890.50,
      ),
    ]);
  }

  double get totalInvested =>
      holdings.fold(0.0, (sum, item) => sum + item.investedValue);

  double get currentValue =>
      holdings.fold(0.0, (sum, item) => sum + item.currentValue);

  double get totalPnl => currentValue - totalInvested;

  double get totalPnlPercent =>
      totalInvested > 0 ? (totalPnl / totalInvested) * 100 : 0.0;

  double get totalPortfolioValue => virtualBalance.value + currentValue;

  void updatePortfolioAfterBuy(String token, String symbol, String name, int qty, double price) {
    final double cost = qty * price;
    virtualBalance.value -= cost;

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
      virtualBalance.value += qty * price;
    }
  }
}
