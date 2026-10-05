import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/stock_model.dart';
import '../models/risk_calculation.dart';
import '../controllers/risk_management_controller.dart';

class RiskManagementView extends StatefulWidget {
  final Stock stock;
  final TradeSide tradeSide;

  const RiskManagementView({
    super.key,
    required this.stock,
    required this.tradeSide,
  });

  @override
  State<RiskManagementView> createState() => _RiskManagementViewState();
}

class _RiskManagementViewState extends State<RiskManagementView> {
  late final RiskManagementController controller;

  @override
  void initState() {
    super.initState();
    // Always delete any existing instance so we get fresh state
    // when navigating to risk management for a different stock.
    Get.delete<RiskManagementController>(force: true);
    controller = Get.put(RiskManagementController());
    controller.initialize(widget.stock, widget.tradeSide);
  }

  @override
  Widget build(BuildContext context) {
    final bool isBuy = widget.tradeSide == TradeSide.BUY;
    final Color sideColor = isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: Text(
          'Risk Management - ${widget.stock.displaySymbol}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stock & Direction Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sideColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sideColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: sideColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.tradeSide.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${widget.stock.exchange})',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                        Text(
                          widget.stock.name,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${widget.stock.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Product / Order Type Selector (Intraday MIS vs Delivery CNC)
            const Text(
              'Order Product Type',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final activeProduct = controller.productType.value;
              return Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.productType.value = 'MIS',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: activeProduct == 'MIS'
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF1E222D),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: activeProduct == 'MIS'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF2A2E39),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Intraday (MIS)',
                              style: TextStyle(
                                color: activeProduct == 'MIS'
                                    ? Colors.white
                                    : Colors.grey[400],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Same day square off',
                              style: TextStyle(
                                color: activeProduct == 'MIS'
                                    ? Colors.white70
                                    : Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.productType.value = 'CNC',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: activeProduct == 'CNC'
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF1E222D),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: activeProduct == 'CNC'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF2A2E39),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Delivery (CNC)',
                              style: TextStyle(
                                color: activeProduct == 'CNC'
                                    ? Colors.white
                                    : Colors.grey[400],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hold multi-day',
                              style: TextStyle(
                                color: activeProduct == 'CNC'
                                    ? Colors.white70
                                    : Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),

            // Entry Price & Quantity Inputs with +/- controls
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: controller.entryController,
                    label: 'Entry Price (₹)',
                    onChanged: (_) => controller.recalculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity (Shares)',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              final int current = int.tryParse(controller.quantityController.text) ?? 1;
                              if (current > 1) {
                                controller.quantityController.text = (current - 1).toString();
                                controller.recalculate();
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              controller: controller.quantityController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              onChanged: (_) => controller.recalculate(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF1E222D),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF2A2E39)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF2A2E39)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF2563EB)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () {
                              final int current = int.tryParse(controller.quantityController.text) ?? 0;
                              controller.quantityController.text = (current + 1).toString();
                              controller.recalculate();
                            },
                            icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Select Risk Method Header
            const Text(
              'Select Risk Method',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Risk Method Options (1:1, 1:2, 1:3, Swing Low/High, Prev Candle)
            Obx(() {
              final activeMethod = controller.selectedMethod.value;
              final double candleVal = isBuy ? widget.stock.low : widget.stock.high;
              final String labelText = isBuy
                  ? 'Prev Low (₹${candleVal.toStringAsFixed(2)})'
                  : 'Prev High (₹${candleVal.toStringAsFixed(2)})';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMethodChip('1 : 1', RiskMethod.RR_1_1, activeMethod),
                      _buildMethodChip('1 : 2 (Recommended)', RiskMethod.RR_1_2, activeMethod),
                      _buildMethodChip('1 : 3', RiskMethod.RR_1_3, activeMethod),
                      if (isBuy)
                        _buildMethodChip('Swing Low (₹${widget.stock.swingLow.toStringAsFixed(2)})',
                            RiskMethod.SWING_LOW, activeMethod)
                      else
                        _buildMethodChip('Swing High (₹${widget.stock.swingHigh.toStringAsFixed(2)})',
                            RiskMethod.SWING_HIGH, activeMethod),
                      _buildMethodChip(labelText, RiskMethod.PREV_CANDLE, activeMethod),
                      _buildMethodChip('Custom', RiskMethod.CUSTOM, activeMethod),
                    ],
                  ),
                  if (activeMethod == RiskMethod.PREV_CANDLE) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: controller.bufferController,
                            label: 'SL Buffer (₹)',
                            onChanged: (_) => controller.setRiskMethod(RiskMethod.PREV_CANDLE),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[800]!),
                            ),
                            child: Text(
                              isBuy
                                  ? 'SL = Prev Low - Buffer'
                                  : 'SL = Prev High + Buffer',
                              style: TextStyle(color: Colors.grey[400], fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            }),
            const SizedBox(height: 20),

            // Calculated Stop Loss & Target Price Inputs
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: controller.stopLossController,
                    label: 'Stop Loss (₹)',
                    accentColor: const Color(0xFFEF4444),
                    onChanged: (_) {
                      controller.selectedMethod.value = RiskMethod.CUSTOM;
                      controller.recalculate();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    controller: controller.targetController,
                    label: 'Target Price (₹)',
                    accentColor: const Color(0xFF10B981),
                    onChanged: (_) {
                      controller.selectedMethod.value = RiskMethod.CUSTOM;
                      controller.recalculate();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Risk & Reward Calculation Card Preview
            Obx(() {
              final calc = controller.calculation.value;
              if (calc == null) return const SizedBox.shrink();

              final bool isValid = calc.isValid;
              final String? error = calc.validationError;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isValid ? const Color(0xFF2563EB) : const Color(0xFFEF4444),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RISK / REWARD PREVIEW',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPreviewRow('Risk Per Share', '₹${calc.riskPerShare.toStringAsFixed(2)}'),
                    _buildPreviewRow('Total Risk', '₹${calc.totalRisk.toStringAsFixed(2)}',
                        valueColor: const Color(0xFFEF4444)),
                    _buildPreviewRow('Potential Profit', '₹${calc.potentialProfit.toStringAsFixed(2)}',
                        valueColor: const Color(0xFF10B981)),
                    _buildPreviewRow('Risk : Reward Ratio', calc.formattedRatio,
                        valueColor: const Color(0xFF2563EB), isBold: true),
                    _buildPreviewRow('Est. Order Value', '₹${calc.estimatedOrderValue.toStringAsFixed(2)}'),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber, color: Color(0xFFEF4444), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Confirm & Place Order Button
            Obx(() {
              final isSubmitting = controller.isSubmitting.value;
              final calc = controller.calculation.value;
              final bool isValid = calc != null && calc.isValid;

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (!isValid || isSubmitting)
                      ? null
                      : () async {
                          final success = await controller.confirmAndPlaceOrder();
                          if (success && context.mounted) {
                            Get.back(); // go back after dialog is dismissed
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sideColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            ),
                            SizedBox(width: 12),
                            Text('Sending Order to Broker...',
                                style: TextStyle(color: Colors.white)),
                          ],
                        )
                      : Text(
                          'CONFIRM & PLACE ORDER WITH SL/TP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodChip(String label, RiskMethod method, RiskMethod current) {
    final bool isSelected = method == current;
    return GestureDetector(
      onTap: () => controller.setRiskMethod(method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E222D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF2A2E39),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    Color? accentColor,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1E222D),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2A2E39)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2A2E39)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: accentColor ?? const Color(0xFF2563EB)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
