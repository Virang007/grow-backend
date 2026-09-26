import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Normalize symbol: strips .NS, .BO, NSE:, BSE: prefixes
  String _clean(String sym) {
    return sym
        .replaceAll('.NS', '')
        .replaceAll('.BO', '')
        .replaceAll('NSE:', '')
        .replaceAll('BSE:', '')
        .trim()
        .toUpperCase();
  }

  Future<void> loadWatchlist() async {
    isLoading.value = true;
    savedSymbols.value = await StorageService.getSavedStockSymbols();

    final fetched = await StockService.fetchBatchStockQuotes(savedSymbols);
    watchlist.assignAll(fetched);
    isLoading.value = false;
  }

  bool isSaved(String symbol) {
    final clean = _clean(symbol);
    return savedSymbols.any((s) => _clean(s) == clean);
  }

  Future<void> toggleSave(Stock stock) async {
    final String sym = stock.symbol;
    final String cleanSym = _clean(sym);

    final bool alreadySaved = isSaved(sym);

    if (alreadySaved) {
      // Remove all variants of this symbol
      savedSymbols.removeWhere((s) => _clean(s) == cleanSym);
      watchlist.removeWhere((item) => _clean(item.symbol) == cleanSym);
      HapticFeedback.lightImpact();
      Get.snackbar(
        'Removed from Watchlist',
        '${stock.displaySymbol} has been removed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF374151),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        icon: const Icon(Icons.bookmark_remove, color: Colors.white),
      );
    } else {
      // Save the clean symbol (no .NS suffix) for consistency
      savedSymbols.add(cleanSym);
      if (!watchlist.any((item) => _clean(item.symbol) == cleanSym)) {
        watchlist.add(stock);
      }
      HapticFeedback.mediumImpact();
      Get.snackbar(
        'Added to Watchlist',
        '${stock.displaySymbol} saved to your Watchlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF2563EB),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        icon: const Icon(Icons.bookmark_added, color: Colors.white),
      );
    }

    // Persist updated list
    final bool saved = await StorageService.saveSavedStockSymbols(savedSymbols);
    if (!saved) {
      print('[WATCHLIST] Failed to persist watchlist to storage!');
    } else {
      print('[WATCHLIST] Saved ${savedSymbols.length} symbols: $savedSymbols');
    }
  }
}
