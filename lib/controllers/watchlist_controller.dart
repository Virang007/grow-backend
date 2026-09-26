import 'package:get/get.dart';
import '../models/stock_model.dart';
import '../services/storage_service.dart';
import '../services/stock_service.dart';

class WatchlistController extends GetxController {
  final RxList<Stock> watchlist = <Stock>[].obs;
  final RxList<String> savedSymbols = <String>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadWatchlist();
  }

  Future<void> loadWatchlist() async {
    isLoading.value = true;
    savedSymbols.value = await StorageService.getSavedStockSymbols();

    final fetched = await StockService.fetchBatchStockQuotes(savedSymbols);
    watchlist.assignAll(fetched);
    isLoading.value = false;
  }

  bool isSaved(String symbol) {
    return savedSymbols.contains(symbol);
  }

  Future<void> toggleSave(Stock stock) async {
    final String sym = stock.symbol;
    if (savedSymbols.contains(sym)) {
      savedSymbols.remove(sym);
      watchlist.removeWhere((item) => item.symbol == sym);
      Get.snackbar(
        'Watchlist Updated',
        '${stock.displaySymbol} removed from Watchlist',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      savedSymbols.add(sym);
      if (!watchlist.any((item) => item.symbol == sym)) {
        watchlist.add(stock);
      }
      Get.snackbar(
        'Watchlist Updated',
        '${stock.displaySymbol} added to Watchlist',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    await StorageService.saveSavedStockSymbols(savedSymbols);
  }
}
