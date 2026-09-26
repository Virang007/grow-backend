import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/portfolio_controller.dart';
import '../models/holding_model.dart';

class PortfolioView extends StatelessWidget {
  const PortfolioView({super.key});

  @override
  Widget build(BuildContext context) {
    final PortfolioController portfolioController = Get.find<PortfolioController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: portfolioController.fetchPortfolio,
          color: const Color(0xFF2563EB),
          backgroundColor: const Color(0xFF1E222D),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Page Title
              const Text(
                'Paper Portfolio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Indian Stock Market Holdings & Virtual Cash',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Total Portfolio Value & Virtual Cash Card
              Obx(() {
                final double totalVal = portfolioController.totalPortfolioValue;
                final double cash = portfolioController.virtualBalance.value;
                final double pnl = portfolioController.totalPnl;
                final double pnlPct = portfolioController.totalPnlPercent;
                final bool isProfit = pnl >= 0;
                final Color pnlColor =
                    isProfit ? const Color(0xFF10B981) : const Color(0xFFEF4444);

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2A2E39)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Portfolio Value',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${totalVal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFF2A2E39), height: 1),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Virtual Cash Balance',
                                  style: TextStyle(
                                      color: Colors.grey[400], fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                '₹${cash.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Overall P&L',
                                  style: TextStyle(
                                      color: Colors.grey[400], fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                '${isProfit ? "+" : ""}₹${pnl.toStringAsFixed(2)} (${isProfit ? "+" : ""}${pnlPct.toStringAsFixed(2)}%)',
                                style: TextStyle(
                                  color: pnlColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Holdings Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Holdings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Obx(() {
                    return Text(
                      '${portfolioController.holdings.length} Positions',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),

              // Holdings List
              Obx(() {
                if (portfolioController.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                    ),
                  );
                }

                if (portfolioController.holdings.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A2E39)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.pie_chart_outline,
                            size: 44, color: Colors.grey[600]),
                        const SizedBox(height: 12),
                        const Text(
                          'No Holdings Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Place Paper BUY orders on NSE/BSE stocks to build your demo portfolio.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: portfolioController.holdings
                      .map((holding) => _buildHoldingCard(holding))
                      .toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoldingCard(HoldingItem holding) {
    final bool isProfit = holding.pnl >= 0;
    final Color pnlColor =
        isProfit ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2E39)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding.displaySymbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${holding.quantity} Shares • Avg: ₹${holding.averagePrice.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${holding.currentValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${isProfit ? "+" : ""}₹${holding.pnl.toStringAsFixed(2)} (${isProfit ? "+" : ""}${holding.pnlPercent.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: pnlColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
