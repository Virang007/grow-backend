import 'dart:async';
import 'package:flutter/material.dart';
import '../models/stock.dart';
import '../services/stock_service.dart';
import '../services/storage_service.dart';
import '../widgets/stock_detail_modal.dart';

class StockDashboardPage extends StatefulWidget {
  final VoidCallback onNavigateToBrokerSettings;
  final int connectedBrokersCount;

  const StockDashboardPage({
    super.key,
    required this.onNavigateToBrokerSettings,
    required this.connectedBrokersCount,
  });

  @override
  State<StockDashboardPage> createState() => _StockDashboardPageState();
}

class _StockDashboardPageState extends State<StockDashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<Stock> _watchlistStocks = [];
  List<Stock> _searchResults = [];
  List<String> _savedSymbols = [];

  bool _isSearching = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchInputChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      _savedSymbols = await StorageService.getSavedStockSymbols();
      final fetched = await StockService.fetchBatchStockQuotes(_savedSymbols);

      for (var stock in fetched) {
        stock.isSaved = true;
      }

      setState(() {
        _watchlistStocks = fetched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Unable to fetch NSE/BSE market quotes. Check connection.';
      });
    }
  }

  void _onSearchInputChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _debounceTimer?.cancel();
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      setState(() {
        _isSearching = true;
        _isLoading = true;
      });

      try {
        final results = await StockService.searchLiveStocks(query);
        for (var stock in results) {
          stock.isSaved = _savedSymbols.contains(stock.symbol);
        }

        if (mounted) {
          setState(() {
            _searchResults = results;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Indian market search failed. Try again.'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      }
    });
  }

  Future<void> _toggleSaveStock(Stock stock) async {
    final messenger = ScaffoldMessenger.of(context);
    final bool newSavedState = !stock.isSaved;

    setState(() {
      stock.isSaved = newSavedState;
      if (newSavedState) {
        if (!_savedSymbols.contains(stock.symbol)) {
          _savedSymbols.add(stock.symbol);
        }
        if (!_watchlistStocks.any((s) => s.symbol == stock.symbol)) {
          _watchlistStocks.add(stock);
        }
      } else {
        _savedSymbols.remove(stock.symbol);
        _watchlistStocks.removeWhere((s) => s.symbol == stock.symbol);
      }
    });

    final success = await StorageService.saveSavedStockSymbols(_savedSymbols);

    if (success) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            newSavedState
                ? '${stock.displaySymbol} added to Indian Watchlist'
                : '${stock.displaySymbol} removed from Watchlist',
          ),
          backgroundColor: newSavedState
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to update Watchlist storage.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  void _openStockDetail(Stock stock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StockDetailModal(
          stock: stock,
          onToggleSave: () {
            _toggleSaveStock(stock);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF2563EB),
          backgroundColor: const Color(0xFF1E222D),
          child: CustomScrollView(
            slivers: [
              // Top Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Indian Markets (NSE/BSE)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Live INR (₹) Quotes & Paper Trading',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: widget.onNavigateToBrokerSettings,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.connectedBrokersCount > 0
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.connectedBrokersCount > 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.connectedBrokersCount > 0
                                    ? Icons.cloud_done
                                    : Icons.cloud_off,
                                size: 16,
                                color: widget.connectedBrokersCount > 0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.connectedBrokersCount > 0
                                    ? '${widget.connectedBrokersCount} Connected'
                                    : 'Connect Broker',
                                style: TextStyle(
                                  color: widget.connectedBrokersCount > 0
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search Indian stocks (e.g. RELIANCE, TCS, INFY)...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF161B22),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF2A2E39)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF2A2E39)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                ),
              ),

              // Search Results vs Watchlist View
              if (_isSearching) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      'Indian Stock Results (${_searchResults.length})',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                _isLoading
                    ? const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                          ),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.all(40),
                              alignment: Alignment.center,
                              child: Text(
                                'No Indian stocks found matching "${_searchController.text}"',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final stock = _searchResults[index];
                                return _buildStockListItem(stock);
                              },
                              childCount: _searchResults.length,
                            ),
                          ),
              ] else ...[
                // Indian Market Indices Ribbon
                SliverToBoxAdapter(
                  child: Container(
                    height: 95,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildMarketIndexCard('NIFTY 50', '25,410.20', '+0.45%', true),
                        _buildMarketIndexCard('SENSEX', '83,184.40', '+0.52%', true),
                        _buildMarketIndexCard('NIFTY BANK', '52,240.10', '+0.38%', true),
                        _buildMarketIndexCard('NIFTY IT', '42,890.60', '-0.15%', false),
                      ],
                    ),
                  ),
                ),

                // Watchlist Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'NSE/BSE Watchlist',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_watchlistStocks.length} Saved',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Error View
                if (_hasError)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.wifi_off, color: Color(0xFFEF4444), size: 36),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retry Connection'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_isLoading)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                      ),
                    ),
                  )
                else if (_watchlistStocks.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2A2E39)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.bookmark_outline,
                              size: 44, color: Colors.grey[600]),
                          const SizedBox(height: 12),
                          const Text(
                            'Your Watchlist is Empty',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Use the search bar above to search for Indian stocks (e.g. RELIANCE, TCS, INFY) and tap the bookmark icon.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final stock = _watchlistStocks[index];
                        return _buildStockListItem(stock);
                      },
                      childCount: _watchlistStocks.length,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketIndexCard(
      String title, String value, String change, bool isPositive) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2E39)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            change,
            style: TextStyle(
              color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockListItem(Stock stock) {
    final bool isPositive = stock.change >= 0;
    final Color color =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2E39)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: () => _openStockDetail(stock),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          alignment: Alignment.center,
          child: Text(
            stock.displaySymbol.substring(
                0, stock.displaySymbol.length > 3 ? 3 : stock.displaySymbol.length),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              stock.displaySymbol,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                stock.exchange,
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _toggleSaveStock(stock),
              child: Icon(
                stock.isSaved ? Icons.bookmark : Icons.bookmark_border,
                size: 18,
                color: stock.isSaved ? const Color(0xFF2563EB) : Colors.grey[600],
              ),
            ),
          ],
        ),
        subtitle: Text(
          stock.name,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${stock.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${isPositive ? "+" : ""}₹${stock.change.toStringAsFixed(2)} (${isPositive ? "+" : ""}${stock.percentChange.toStringAsFixed(2)}%)',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
