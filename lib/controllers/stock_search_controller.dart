import 'dart:async';
import 'package:get/get.dart';
import '../models/groww_instrument.dart';
import '../services/groww_instrument_service.dart';

/// Controller for the stock search screen.
///
/// Now backed by Groww's instrument list instead of Yahoo Finance, so
/// search results contain real Groww symbols (e.g. NSE_RELIANCE) that
/// can be used directly with the LTP and Order APIs.
class StockSearchController extends GetxController {
  final RxString query = ''.obs;
  final RxList<GrowwInstrument> searchResults = <GrowwInstrument>[].obs;
  final RxBool isSearching = false.obs;
  final RxBool isLoading = false.obs;

  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    // Pre-warm the instrument list in the background so first search is fast.
    GrowwInstrumentService.getAllInstruments().catchError((_) => <GrowwInstrument>[]);
  }

  void onQueryChanged(String text) {
    query.value = text.trim();
    if (query.isEmpty) {
      _debounceTimer?.cancel();
      isSearching.value = false;
      searchResults.clear();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      isSearching.value = true;
      isLoading.value = true;

      try {
        final results = await GrowwInstrumentService.search(query.value);
        searchResults.assignAll(results);
      } catch (e) {
        print('[SEARCH CONTROLLER ERROR] $e');
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
