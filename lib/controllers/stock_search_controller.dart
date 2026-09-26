import 'dart:async';
import 'package:get/get.dart';
import '../models/stock_model.dart';
import '../services/stock_service.dart';

class StockSearchController extends GetxController {
  final RxString query = ''.obs;
  final RxList<Stock> searchResults = <Stock>[].obs;
  final RxBool isSearching = false.obs;
  final RxBool isLoading = false.obs;

  Timer? _debounceTimer;

  void onQueryChanged(String text) {
    query.value = text.trim();
    if (query.isEmpty) {
      _debounceTimer?.cancel();
      isSearching.value = false;
      searchResults.clear();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      isSearching.value = true;
      isLoading.value = true;

      try {
        final stocks = await StockService.searchLiveStocks(query.value);
        searchResults.assignAll(stocks);
      } catch (_) {
        searchResults.clear();
      } finally {
        isLoading.value = false;
      }
    });
  }

  void clearSearch() {
    query.value = '';
    isSearching.value = false;
    searchResults.clear();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }
}
