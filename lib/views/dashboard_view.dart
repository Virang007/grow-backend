import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/broker_controller.dart';
import '../controllers/watchlist_controller.dart';
import '../controllers/home_controller.dart';
import '../models/stock_model.dart';
import 'search_view.dart';
import 'stock_detail_view.dart';
import 'orders_view.dart';
import 'portfolio_view.dart';
import 'broker_settings_page.dart';

/// Main dashboard with bottom navigation.
///
/// Fully StatelessWidget — tab index is managed by [HomeController.currentTabIndex]
/// (RxInt) so only the BottomNavigationBar and IndexedStack rebuild on tab change,
/// not the entire widget tree.
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final BrokerController brokerController = Get.find<BrokerController>();
    final WatchlistController watchlistController =
        Get.find<WatchlistController>();
    final HomeController homeController = Get.find<HomeController>();

    final List<Widget> pages = [
      _buildHomeDashboard(
          context, brokerController, homeController, watchlistController),
      _buildWatchlistView(watchlistController),
      const OrdersView(),
      const PortfolioView(),
      BrokerSettingsPage(onBrokersUpdated: brokerController.loadBrokers),
    ];

    return Scaffold(
      body: Obx(() => IndexedStack(
            index: homeController.currentTabIndex.value,
            children: pages,
          )),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF161B22),
          border: Border(top: BorderSide(color: Color(0xFF2A2E39), width: 1)),
        ),
        child: Obx(() => BottomNavigationBar(
              currentIndex: homeController.currentTabIndex.value,
              onTap: (index) => homeController.currentTabIndex.value = index,
              backgroundColor: const Color(0xFF161B22),
              selectedItemColor: const Color(0xFF2563EB),
              unselectedItemColor: Colors.grey[500],
              selectedFontSize: 11,
              unselectedFontSize: 11,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home, color: Color(0xFF2563EB)),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.bookmark_outline),
                  activeIcon: Icon(Icons.bookmark, color: Color(0xFF2563EB)),
                  label: 'Watchlist',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_outlined),
                  activeIcon: Icon(Icons.assignment, color: Color(0xFF2563EB)),
                  label: 'Orders',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  activeIcon: Icon(Icons.account_balance_wallet,
                      color: Color(0xFF2563EB)),
                  label: 'Portfolio',
                ),
                BottomNavigationBarItem(
                  icon: Obx(() {
                    final count = brokerController.connectedCount.value;
                    return Badge(
                      isLabelVisible: count > 0,
                      backgroundColor: const Color(0xFF10B981),
                      label: Text('$count'),
                      child: const Icon(Icons.account_balance_outlined),
                    );
                  }),
                  activeIcon: Obx(() {
                    final count = brokerController.connectedCount.value;
                    return Badge(
                      isLabelVisible: count > 0,
                      backgroundColor: const Color(0xFF10B981),
                      label: Text('$count'),
                      child: const Icon(Icons.account_balance,
                          color: Color(0xFF2563EB)),
                    );
                  }),
                  label: 'Broker API',
                ),
              ],
            )),
      ),
    );
  }

  Widget _buildHomeDashboard(
    BuildContext context,
    BrokerController brokerController,
    HomeController homeController,
    WatchlistController watchlistController,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: homeController.loadMarketStocks,
          color: const Color(0xFF2563EB),
          backgroundColor: const Color(0xFF1E222D),
          child: CustomScrollView(
            slivers: [
              // Header Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Home',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Indian Stock Market Shares & SL/TP Calculator',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Obx(() {
                        final count = brokerController.connectedCount.value;
                        return GestureDetector(
                          // Navigate directly via RxInt — no setState
                          onTap: () =>
                              homeController.currentTabIndex.value = 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: count > 0
                                  ? const Color(0xFF10B981)
                                      .withValues(alpha: 0.15)
                                  : const Color(0xFFEF4444)
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: count > 0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  count > 0
                                      ? Icons.cloud_done
                                      : Icons.cloud_off,
                                  size: 14,
                                  color: count > 0
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  count > 0 ? '$count Active' : 'Connect',
                                  style: TextStyle(
                                    color: count > 0
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Search Launcher Bar (Primary Action)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GestureDetector(
                    onTap: () => Get.to(() => const SearchView()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF2563EB), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Color(0xFF2563EB)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search Indian stock (e.g. RELIANCE, TCS, INFY)...',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SEARCH',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Live Market Indices Ribbon
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 96,
                  child: Obx(() {
                    if (homeController.isIndicesLoading.value &&
                        homeController.marketIndices.isEmpty) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: const Color(0xFF2A2E39)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Loading live market indices...',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      itemCount: homeController.marketIndices.length,
                      itemBuilder: (context, index) {
                        final idx = homeController.marketIndices[index];
                        final bool isPositive = idx.change >= 0;
                        final Color color = isPositive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444);

                        String cleanName =
                            idx.symbol.replaceAll('^', '');
                        if (cleanName == 'NSEI') cleanName = 'NIFTY 50';
                        if (cleanName == 'BSESN') cleanName = 'SENSEX';
                        if (cleanName == 'NSEBANK') {
                          cleanName = 'BANK NIFTY';
                        }

                        return Container(
                          width: 160,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFF2A2E39)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    cleanName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Icon(
                                    isPositive
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    color: color,
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${idx.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${isPositive ? "+" : ""}${idx.change.toStringAsFixed(2)} (${isPositive ? "+" : ""}${idx.percentChange.toStringAsFixed(2)}%)',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),

              // Market Stocks Section Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Market Stocks (NSE Shares)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Obx(() => Text(
                            '${homeController.marketStocks.length} Shares',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12),
                          )),
                    ],
                  ),
                ),
              ),

              // Live Market Stocks Feed
              Obx(() {
                if (homeController.isLoading.value &&
                    homeController.marketStocks.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(
                            color: Color(0xFF2563EB)),
                      ),
                    ),
                  );
                }

                if (homeController.marketStocks.isEmpty) {
                  return SliverToBoxAdapter(
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
                          Icon(Icons.show_chart,
                              size: 44, color: Colors.grey[600]),
                          const SizedBox(height: 12),
                          const Text(
                            'No Market Data Loaded',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap the search bar above to search for any Indian stock share (e.g. RELIANCE, TCS, INFY).',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final stock = homeController.marketStocks[index];
                      return _buildStockTile(stock, watchlistController);
                    },
                    childCount: homeController.marketStocks.length,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWatchlistView(WatchlistController watchlistController) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NSE/BSE Watchlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track prices & calculate risk levels',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            Obx(() {
              if (watchlistController.watchlist.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(30),
                    alignment: Alignment.center,
                    child: Text('No stocks in Watchlist yet.',
                        style: TextStyle(color: Colors.grey[500])),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final stock = watchlistController.watchlist[index];
                    return _buildStockTile(stock, watchlistController);
                  },
                  childCount: watchlistController.watchlist.length,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStockTile(
      Stock stock, WatchlistController watchlistController) {
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                0,
                stock.displaySymbol.length > 3
                    ? 3
                    : stock.displaySymbol.length),
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
                stock.displaySymbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
              onTap: () => watchlistController.toggleSave(stock),
              child: Obx(() {
                final saved = watchlistController.isSaved(stock.symbol);
                return Icon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  size: 18,
                  color:
                      saved ? const Color(0xFF2563EB) : Colors.grey[500],
                );
              }),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
