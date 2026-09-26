import 'package:flutter/material.dart';
import '../models/stock.dart';
import 'stock_chart_widget.dart';

class StockDetailModal extends StatefulWidget {
  final Stock stock;
  final VoidCallback onToggleSave;

  const StockDetailModal({
    super.key,
    required this.stock,
    required this.onToggleSave,
  });

  @override
  State<StockDetailModal> createState() => _StockDetailModalState();
}

class _StockDetailModalState extends State<StockDetailModal> {
  String _selectedPeriod = '1D';
  late Stock stock;

  @override
  void initState() {
    super.initState();
    stock = widget.stock;
  }

  @override
  Widget build(BuildContext context) {
    final bool isPositive = stock.change >= 0;
    final Color priceColor =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF131722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Symbol, Name & Save Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E222D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2E39)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      stock.symbol.substring(0, stock.symbol.length > 3 ? 3 : stock.symbol.length),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.symbol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        stock.name,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    stock.isSaved = !stock.isSaved;
                  });
                  widget.onToggleSave();
                },
                icon: Icon(
                  stock.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: stock.isSaved ? const Color(0xFF2563EB) : Colors.grey[400],
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Price & Change
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$${stock.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: priceColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: priceColor,
                      size: 20,
                    ),
                    Text(
                      '${isPositive ? "+" : ""}${stock.change.toStringAsFixed(2)} (${isPositive ? "+" : ""}${stock.percentChange.toStringAsFixed(2)}%)',
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

          // Period Filter selector
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          // Chart Display
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: StockChartPainter(
                prices: stock.chartData,
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
              _buildStatTile('Open', '\$${stock.open.toStringAsFixed(2)}'),
              _buildStatTile('High', '\$${stock.high.toStringAsFixed(2)}'),
              _buildStatTile('Low', '\$${stock.low.toStringAsFixed(2)}'),
              _buildStatTile('Market Cap', stock.marketCap),
              _buildStatTile('P/E Ratio', '${stock.peRatio}'),
              _buildStatTile(
                  'Volume', '${(stock.volume / 1000000).toStringAsFixed(1)}M'),
            ],
          ),
          const SizedBox(height: 24),

          // Action Buttons: Buy / Sell
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Buy order initiated for ${stock.symbol} at \$${stock.price.toStringAsFixed(2)}',
                        ),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'BUY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Sell order initiated for ${stock.symbol} at \$${stock.price.toStringAsFixed(2)}',
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SELL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
