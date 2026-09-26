import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/stock_model.dart';
import '../models/risk_calculation.dart';
import '../controllers/watchlist_controller.dart';
import '../widgets/stock_chart_widget.dart';
import 'risk_management_view.dart';

class StockDetailView extends StatefulWidget {
  final Stock stock;

  const StockDetailView({super.key, required this.stock});

  @override
  State<StockDetailView> createState() => _StockDetailViewState();
}

class _StockDetailViewState extends State<StockDetailView> {
  String _selectedPeriod = '1D';

  @override
  Widget build(BuildContext context) {
    final WatchlistController watchlistController = Get.find<WatchlistController>();
    final bool isPositive = widget.stock.change >= 0;
    final Color priceColor =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: Text(
          widget.stock.displaySymbol,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Obx(() {
            // Clean symbol for matching (remove .NS, .BO suffix)
            final cleanSym = widget.stock.symbol
                .replaceAll('.NS', '')
                .replaceAll('.BO', '')
                .trim();
            final isSaved = watchlistController.savedSymbols.any((s) =>
                s == widget.stock.symbol ||
                s == cleanSym ||
                s.replaceAll('.NS', '').replaceAll('.BO', '') == cleanSym);
            return IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? const Color(0xFF2563EB) : Colors.grey[400],
                size: 26,
              ),
              tooltip: isSaved ? 'Remove from Watchlist' : 'Add to Watchlist',
              onPressed: () async {
                await watchlistController.toggleSave(widget.stock);
              },
            );
          }),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Company Header
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E222D),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A2E39)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.stock.displaySymbol.substring(
                        0,
                        widget.stock.displaySymbol.length > 3
                            ? 3
                            : widget.stock.displaySymbol.length),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.stock.displaySymbol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.stock.exchange,
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.stock.name,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Live Price & Change in ₹ INR
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '₹${widget.stock.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: priceColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: priceColor,
                        size: 20,
                      ),
                      Text(
                        '${isPositive ? "+" : ""}₹${widget.stock.change.toStringAsFixed(2)} (${isPositive ? "+" : ""}${widget.stock.percentChange.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: priceColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Time Period Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['1D', '1W', '1M', '1Y', 'ALL'].map((period) {
                final isSelected = _selectedPeriod == period;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = period;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF1E222D),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      period,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[400],
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Chart
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: StockChartPainter(
                  prices: widget.stock.chartData,
                  isPositive: isPositive,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Key Statistics Grid
            const Text(
              'Key Statistics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildStatTile('Open', '₹${widget.stock.open.toStringAsFixed(2)}'),
                _buildStatTile('High', '₹${widget.stock.high.toStringAsFixed(2)}'),
                _buildStatTile('Low', '₹${widget.stock.low.toStringAsFixed(2)}'),
                _buildStatTile('Market Cap', widget.stock.marketCap),
                _buildStatTile('P/E Ratio', '${widget.stock.peRatio}'),
                _buildStatTile('Volume',
                    '${(widget.stock.volume / 100000).toStringAsFixed(1)}L'),
              ],
            ),
            const SizedBox(height: 24),

            // Primary Actions: BUY & SELL -> Risk Management Screen
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.to(() => RiskManagementView(
                            stock: widget.stock,
                            tradeSide: TradeSide.BUY,
                          ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'BUY (LONG)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.to(() => RiskManagementView(
                            stock: widget.stock,
                            tradeSide: TradeSide.SELL,
                          ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SELL (SHORT)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2E39)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
