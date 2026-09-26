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
  List<Stock> _allStocks = [];
  List<Stock> _searchResults = [];
  List<String> _savedSymbols = [];
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    _savedSymbols = await StorageService.getSavedStockSymbols();
    _allStocks = StockService.getAllStocks();

    for (var stock in _allStocks) {
      stock.isSaved = _savedSymbols.contains(stock.symbol);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    } else {
      setState(() {
        _isSearching = true;
        _searchResults = StockService.searchStocks(query);
      });
    }
  }

  Future<void> _toggleSaveStock(Stock stock) async {
    setState(() {
      stock.isSaved = !stock.isSaved;
      if (stock.isSaved) {
        if (!_savedSymbols.contains(stock.symbol)) {
          _savedSymbols.add(stock.symbol);
        }
      } else {
        _savedSymbols.remove(stock.symbol);
      }
    });

    await StorageService.saveSavedStockSymbols(_savedSymbols);
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
    final savedStocksList =
        _allStocks.where((s) => _savedSymbols.contains(s.symbol)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF2563EB),
          backgroundColor: const Color(0xFF1E222D),
          child: CustomScrollView(
            slivers: [
              // Top App Bar
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
                            'Markets',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Real-time quotes & watchlist',
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
                      hintText: 'Search stocks, indices, crypto (e.g. AAPL, NVDA)...',
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

              // Content View: Search Results vs Saved Watchlist
              if (_isSearching) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      'Search Results (${_searchResults.length})',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                _searchResults.isEmpty
                    ? SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          child: Text(
                            'No stocks found matching "${_searchController.text}"',
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
                // Quick Market Summary Cards
                SliverToBoxAdapter(
                  child: Container(
                    height: 100,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildMarketIndexCard('S&P 500', '5,620.40', '+0.85%', true),
                        _buildMarketIndexCard('NASDAQ', '17,840.10', '+1.15%', true),
                        _buildMarketIndexCard('DOW JONES', '41,120.80', '-0.12%', false),
                        _buildMarketIndexCard('NIFTY 50', '25,410.20', '+0.45%', true),
                      ],
                    ),
                  ),
                ),

                // Watchlist Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Watchlist',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${savedStocksList.length} Saved',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Watchlist Stock Cards
                _isLoading
                    ? const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                          ),
                        ),
                      )
                    : savedStocksList.isEmpty
                        ? SliverToBoxAdapter(
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
                                    'Use the search bar above to search for any stock and tap the save icon to add it here.',
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
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final stock = savedStocksList[index];
                                return _buildStockListItem(stock);
                              },
                              childCount: savedStocksList.length,
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
            stock.symbol.substring(0, stock.symbol.length > 3 ? 3 : stock.symbol.length),
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
              stock.symbol,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
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
              '\$${stock.price.toStringAsFixed(2)}',
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
                '${isPositive ? "+" : ""}${stock.percentChange.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
