import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/stock_search_controller.dart';
import '../models/groww_instrument.dart';
import '../models/stock_model.dart';
import '../services/stock_service.dart';
import 'stock_detail_view.dart';

/// Stock search screen backed by Groww's instrument list.
///
/// Displays trading symbol + company name + exchange from Groww instrument data.
/// On tap, fetches a live Yahoo Finance quote to populate the [StockDetailView]
/// (which shows the Groww LTP price as well via its own LTP refresh flow).
class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final StockSearchController searchController =
        Get.find<StockSearchController>();
    final TextEditingController textEditingController =
        TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: TextField(
          controller: textEditingController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          onChanged: searchController.onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Search Indian stocks (e.g. RELIANCE, TCS, INFY)...',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                textEditingController.clear();
                searchController.clearSearch();
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          // ── Empty state ─────────────────────────────────────────────
          if (!searchController.isSearching.value) {
            return Container(
              padding: const EdgeInsets.all(30),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 56, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  const Text(
                    'Search Indian Stocks (NSE / BSE)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Powered by Groww instrument data.\n'
                    'Try: RELIANCE, TCS, INFY, HDFCBANK, ITC...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // ── Loading state ───────────────────────────────────────────
          if (searchController.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            );
          }

          // ── No results ──────────────────────────────────────────────
          if (searchController.searchResults.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 44, color: Colors.grey[600]),
                  const SizedBox(height: 12),
                  Text(
                    'No stocks found for "${searchController.query.value}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try a different symbol or company name.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            );
          }

          // ── Results list ────────────────────────────────────────────
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  '${searchController.searchResults.length} results from Groww',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: searchController.searchResults.length,
                  itemBuilder: (context, index) {
                    final instrument = searchController.searchResults[index];
                    return _GrowwSearchResultTile(instrument: instrument);
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// A single search result tile for a [GrowwInstrument].
///
/// On tap it fetches the Yahoo Finance live quote (fallback price)
/// and navigates to [StockDetailView]. The detail view then independently
/// calls Groww LTP for a real price refresh.
class _GrowwSearchResultTile extends StatefulWidget {
  final GrowwInstrument instrument;

  const _GrowwSearchResultTile({required this.instrument});

  @override
  State<_GrowwSearchResultTile> createState() => _GrowwSearchResultTileState();
}

class _GrowwSearchResultTileState extends State<_GrowwSearchResultTile> {
  final RxBool _isLoading = false.obs;

  Future<void> _onTap() async {
    if (_isLoading.value) return;
    _isLoading.value = true;

    try {
      // Fetch Yahoo quote to get price + chart data for StockDetailView.
      // StockDetailView will then refresh price from Groww LTP.
      final Stock? stock = await StockService.fetchLiveStockQuote(
        '${widget.instrument.tradingSymbol}.${widget.instrument.exchange == "BSE" ? "BO" : "NS"}',
      );

      if (stock != null) {
        // Attach the Groww symbol to instrumentToken so StockDetailView
        // can use it for LTP calls.
        final stockWithGrowwSym = Stock(
          instrumentToken: widget.instrument.growwSymbol,
          symbol: stock.symbol,
          name: widget.instrument.companyName.isNotEmpty
              ? widget.instrument.companyName
              : stock.name,
          exchange: widget.instrument.exchange,
          price: stock.price,
          change: stock.change,
          percentChange: stock.percentChange,
          open: stock.open,
          high: stock.high,
          low: stock.low,
          swingHigh: stock.swingHigh,
          swingLow: stock.swingLow,
          marketCap: stock.marketCap,
          peRatio: stock.peRatio,
          volume: stock.volume,
          chartData: stock.chartData,
        );
        Get.to(() => StockDetailView(stock: stockWithGrowwSym));
      } else {
        // Could not fetch price — navigate with a placeholder price.
        // StockDetailView LTP call will update it.
        final placeholderStock = Stock(
          instrumentToken: widget.instrument.growwSymbol,
          symbol:
              '${widget.instrument.tradingSymbol}.${widget.instrument.exchange == "BSE" ? "BO" : "NS"}',
          name: widget.instrument.companyName,
          exchange: widget.instrument.exchange,
          price: 0.0,
          change: 0.0,
          percentChange: 0.0,
          open: 0.0,
          high: 0.0,
          low: 0.0,
          swingHigh: 0.0,
          swingLow: 0.0,
          marketCap: '—',
          peRatio: 0.0,
          volume: 0.0,
          chartData: [],
        );
        Get.to(() => StockDetailView(stock: placeholderStock));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load ${widget.instrument.tradingSymbol}. Check connection.'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String sym = widget.instrument.tradingSymbol;
    final String exch = widget.instrument.exchange;

    // Badge color: NSE = blue, BSE = amber
    final Color exchColor =
        exch == 'BSE' ? const Color(0xFFF59E0B) : const Color(0xFF2563EB);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2E39)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: _onTap,
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          alignment: Alignment.center,
          child: Text(
            sym.length > 3 ? sym.substring(0, 3) : sym,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                sym,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: exchColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                exch,
                style: TextStyle(
                  color: exchColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              widget.instrument.companyName,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              widget.instrument.growwSymbol,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        trailing: Obx(() => _isLoading.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFF2563EB),
                  strokeWidth: 2,
                ),
              )
            : Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey[600],
              )),
      ),
    );
  }
}
