import 'package:get/get.dart';
import '../models/stock_model.dart';
import '../services/stock_service.dart';

class HomeController extends GetxController {
  final RxList<Stock> marketStocks = <Stock>[].obs;
  final RxList<Stock> marketIndices = <Stock>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isIndicesLoading = false.obs;

  /// Current bottom-nav tab index — replaces setState in DashboardView.
  final RxInt currentTabIndex = 0.obs;

  static final List<String> topMarketSymbols = [
    'RELIANCE.NS',
    'TCS.NS',
    'INFY.NS',
    'HDFCBANK.NS',
    'ICICIBANK.NS',
    'SBIN.NS',
    'TATAMOTORS.NS',
    'BHARTIARTL.NS',
    'ITC.NS',
    'LT.NS',
  ];

  static final List<String> indexSymbols = [
    '^NSEI',
    '^BSESN',
    '^NSEBANK',
  ];

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadMarketIndices(),
      loadMarketStocks(),
    ]);
  }

  Future<void> loadMarketIndices() async {
    isIndicesLoading.value = true;
    try {
      final List<Stock> loaded = [];
      for (final sym in indexSymbols) {
        final stock = await StockService.fetchLiveStockQuote(sym);
        if (stock != null) {
          loaded.add(stock);
        }
      }

      if (loaded.isEmpty) {
        // Fallback placeholder data if network/Yahoo query blocked
        loaded.addAll(_getFallbackIndices());
      }
      marketIndices.assignAll(loaded);
    } catch (e) {
      print('[HOME CONTROLLER] Error loading market indices: $e');
      marketIndices.assignAll(_getFallbackIndices());
    } finally {
      isIndicesLoading.value = false;
    }
  }

  Future<void> loadMarketStocks() async {
    isLoading.value = true;
    try {
      final stocks = await StockService.fetchBatchStockQuotes(topMarketSymbols);
      marketStocks.assignAll(stocks);
    } catch (e) {
      print('[HOME CONTROLLER] Error loading market stocks: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<Stock> _getFallbackIndices() {
    return [
      Stock(
        instrumentToken: 'NIFTY50',
        symbol: '^NSEI',
        name: 'NIFTY 50 Index',
        exchange: 'NSE',
        price: 26175.40,
        change: 142.30,
        percentChange: 0.55,
        open: 26050.00,
        high: 26210.00,
        low: 26010.00,
        swingHigh: 26210.00,
        swingLow: 26010.00,
        marketCap: '',
        peRatio: 0,
        volume: 0,
        chartData: [26050, 26100, 26175.40],
      ),
      Stock(
        instrumentToken: 'SENSEX',
        symbol: '^BSESN',
        name: 'SENSEX Index',
        exchange: 'BSE',
        price: 85571.80,
        change: 450.20,
        percentChange: 0.53,
        open: 85200.00,
        high: 85700.00,
        low: 85150.00,
        swingHigh: 85700.00,
        swingLow: 85150.00,
        marketCap: '',
        peRatio: 0,
        volume: 0,
        chartData: [85200, 85400, 85571.80],
      ),
      Stock(
        instrumentToken: 'BANKNIFTY',
        symbol: '^NSEBANK',
        name: 'BANK NIFTY Index',
        exchange: 'NSE',
        price: 54120.60,
        change: 280.10,
        percentChange: 0.52,
        open: 53900.00,
        high: 54250.00,
        low: 53850.00,
        swingHigh: 54250.00,
        swingLow: 53850.00,
        marketCap: '',
        peRatio: 0,
        volume: 0,
        chartData: [53900, 54050, 54120.60],
      ),
    ];
  }
}
