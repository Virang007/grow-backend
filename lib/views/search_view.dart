import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/stock_search_controller.dart';
import '../models/stock_model.dart';
import 'stock_detail_view.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final StockSearchController searchController = Get.find<StockSearchController>();
    final TextEditingController textEditingController = TextEditingController();

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
                    'Try searching for RELIANCE, TCS, INFY, HDFCBANK, ICICIBANK, SBIN, TATAMOTORS, ITC...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            );
          }

          if (searchController.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            );
          }

          if (searchController.searchResults.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: Text(
                'No Indian stocks found matching "${searchController.query.value}"',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: searchController.searchResults.length,
            itemBuilder: (context, index) {
              final Stock stock = searchController.searchResults[index];
              return _buildSearchResultTile(stock);
            },
          );
        }),
      ),
    );
  }

  Widget _buildSearchResultTile(Stock stock) {
    final bool isPositive = stock.change >= 0;
    final Color color =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2E39)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: () {
          Get.to(() => StockDetailView(stock: stock));
        },
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
          ],
        ),
        subtitle: Text(
          stock.name,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
