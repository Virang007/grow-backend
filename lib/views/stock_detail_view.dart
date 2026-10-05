import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/stock_model.dart';
import '../models/risk_calculation.dart';
import '../controllers/watchlist_controller.dart';
import '../controllers/broker_controller.dart';
import '../services/groww_service.dart';
import '../widgets/stock_chart_widget.dart';
import 'risk_management_view.dart';

class StockDetailView extends StatefulWidget {
  final Stock stock;

  const StockDetailView({super.key, required this.stock});

  @override
  State<StockDetailView> createState() => _StockDetailViewState();
}

class _StockDetailViewState extends State<StockDetailView> {
  final RxString _selectedPeriod = '1D'.obs;

  // Groww LTP reactive state
  final Rxn<double> _growwLtp = Rxn<double>(); // null = not yet fetched / unavailable
  final RxBool _ltpLoading = false.obs;       // true while LTP call is in-flight
  final RxBool _ltpFetched = false.obs;       // true once we have a definitive result

  @override
  void initState() {
    super.initState();
    _fetchGrowwLtp();
  }

  /// Checks if [instrumentToken] looks like a Groww symbol (EXCHANGE_SYMBOL)
  /// and calls Groww LTP API if so.
  Future<void> _fetchGrowwLtp() async {
    final String token = widget.stock.instrumentToken;
    // Groww symbols contain underscore: NSE_RELIANCE, BSE_TCS, etc.
    if (!token.contains('_')) return;

    _ltpLoading.value = true;

    try {
      final BrokerController brokerCtrl = Get.find<BrokerController>();
      final growwBroker = brokerCtrl.growwBroker;

      if (growwBroker == null ||
          growwBroker.apiKey.isEmpty ||
          growwBroker.totpSecret.isEmpty) {
        print('[LTP] Groww credentials not configured — skipping LTP call');
        return;
      }

      final service = GrowwBrokerService(
        apiKey: growwBroker.apiKey,
        totpSecret: growwBroker.totpSecret,
        baseUrl: growwBroker.baseUrl,
      );

      // Use cached token from BrokerController if available
      final cachedToken = brokerCtrl.currentAccessToken.value;

      final double? ltp = await service.fetchLTP(
        growwSymbol: token,
        accessToken: cachedToken.isNotEmpty ? cachedToken : null,
      );

      _growwLtp.value = ltp;
      _ltpFetched.value = true;
    } catch (e) {
      print('[LTP EXCEPTION] $e');
    } finally {
      _ltpLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final WatchlistController watchlistController =
        Get.find<WatchlistController>();

    // Use Groww LTP if available, fall back to Yahoo Finance price
    final double displayPrice = _growwLtp.value ?? widget.stock.price;
    final bool isPositive = displayPrice >= widget.stock.price - (widget.stock.price * 0.5)
        ? widget.stock.change >= 0
        : false;
    final Color priceColor =
        widget.stock.change >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

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
            Obx(() {
              final double displayPrice = _growwLtp.value ?? widget.stock.price;
              final bool ltpLoading = _ltpLoading.value;
              final bool ltpFetched = _ltpFetched.value;
              final double? growwLtp = _growwLtp.value;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  // ── Price ────────────────────────────────────────────
                  ltpLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFF2563EB),
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          '₹${displayPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                  const SizedBox(width: 10),
                  // ── LIVE badge (Groww LTP source indicator) ──────────
                  if (ltpFetched && growwLtp != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'GROWW LIVE',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (ltpFetched && growwLtp == null)
                    // Fallback badge when Groww LTP was unavailable
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Yahoo Finance',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 8),
            // Change row
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
                    widget.stock.change >= 0
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: priceColor,
                    size: 20,
                  ),
                  Text(
                    '${widget.stock.change >= 0 ? "+" : ""}₹${widget.stock.change.toStringAsFixed(2)} (${widget.stock.change >= 0 ? "+" : ""}${widget.stock.percentChange.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: priceColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Time Period Selector
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['1D', '1W', '1M', '1Y', 'ALL'].map((period) {
                final isSelected = _selectedPeriod.value == period;
                return GestureDetector(
                  onTap: () {
                    _selectedPeriod.value = period;
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
            )),
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
