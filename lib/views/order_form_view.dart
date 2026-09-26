import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/instrument_model.dart';
import '../models/order_model.dart';
import '../controllers/order_controller.dart';
import '../controllers/portfolio_controller.dart';

class OrderFormView extends StatefulWidget {
  final Instrument instrument;
  final bool isBuy;

  const OrderFormView({
    super.key,
    required this.instrument,
    required this.isBuy,
  });

  @override
  State<OrderFormView> createState() => _OrderFormViewState();
}

class _OrderFormViewState extends State<OrderFormView> {
  final TextEditingController quantityController = TextEditingController(text: '1');
  late TextEditingController priceController;
  final TextEditingController triggerPriceController = TextEditingController(text: '0.0');

  OrderType _selectedOrderType = OrderType.MARKET;

  @override
  void initState() {
    super.initState();
    priceController = TextEditingController(
      text: widget.instrument.price.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    triggerPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OrderController orderController = Get.find<OrderController>();
    final PortfolioController portfolioController = Get.find<PortfolioController>();

    final OrderTransactionType transType =
        widget.isBuy ? OrderTransactionType.BUY : OrderTransactionType.SELL;
    final Color actionColor =
        widget.isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    final int qty = int.tryParse(quantityController.text) ?? 1;
    final double targetPrice = double.tryParse(priceController.text) ?? widget.instrument.price;
    final double totalOrderValue = qty * targetPrice;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: Text(
          'Paper ${transType.name} - ${widget.instrument.displaySymbol}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Order Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: actionColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: actionColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isBuy ? Icons.add_shopping_cart : Icons.sell_outlined,
                      color: actionColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MegaBull Paper ${transType.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${widget.instrument.name} (${widget.instrument.exchange})',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${widget.instrument.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Available Balance from API
            Obx(() {
              final bal = portfolioController.virtualBalance.value;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2E39)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Balance:',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                    Text(
                      bal != null ? '₹${bal.toStringAsFixed(2)}' : 'Balance unavailable',
                      style: TextStyle(
                        color: bal != null ? const Color(0xFF10B981) : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Order Type Selector (MARKET, LIMIT, SL)
            const Text(
              'Order Type',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: OrderType.values.map((type) {
                final isSelected = _selectedOrderType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedOrderType = type;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? actionColor : const Color(0xFF1E222D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        type.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[400],
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Quantity Field
            const Text(
              'Quantity (Shares)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E222D),
                hintText: 'Enter quantity',
                hintStyle: TextStyle(color: Colors.grey[600]),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  borderSide: BorderSide(color: actionColor),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Price Field (Enabled for LIMIT or SL)
            if (_selectedOrderType == OrderType.LIMIT ||
                _selectedOrderType == OrderType.SL) ...[
              const Text(
                'Limit Price (₹)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E222D),
                  hintText: 'Enter limit price in ₹',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    borderSide: BorderSide(color: actionColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Trigger Price Field (Enabled for SL)
            if (_selectedOrderType == OrderType.SL) ...[
              const Text(
                'Trigger Price (₹)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: triggerPriceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E222D),
                  hintText: 'Enter trigger price in ₹',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    borderSide: BorderSide(color: actionColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Total Order Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A2E39)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Est. Order Total:',
                          style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      Text(
                        '₹${totalOrderValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            Obx(() {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: orderController.isSubmitting.value
                      ? null
                      : () async {
                          final int inputQty =
                              int.tryParse(quantityController.text) ?? 0;
                          final double inputPrice =
                              double.tryParse(priceController.text) ?? 0.0;
                          final double inputTrigger =
                              double.tryParse(triggerPriceController.text) ?? 0.0;

                          final success = await orderController.placePaperOrder(
                            instrument: widget.instrument,
                            transactionType: transType,
                            orderType: _selectedOrderType,
                            quantity: inputQty,
                            price: inputPrice,
                            triggerPrice: inputTrigger,
                          );

                          if (success) {
                            if (widget.isBuy) {
                              portfolioController.updatePortfolioAfterBuy(
                                widget.instrument.instrumentToken,
                                widget.instrument.symbol,
                                widget.instrument.name,
                                inputQty,
                                inputPrice,
                              );
                            } else {
                              portfolioController.updatePortfolioAfterSell(
                                widget.instrument.symbol,
                                inputQty,
                                inputPrice,
                              );
                            }
                            Get.back();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: orderController.isSubmitting.value
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
                            Text('Submitting Paper Order...',
                                style: TextStyle(color: Colors.white)),
                          ],
                        )
                      : Text(
                          'Place Paper ${transType.name} Order',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
}
