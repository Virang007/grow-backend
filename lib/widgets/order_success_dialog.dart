import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/order_result.dart';
import '../models/risk_calculation.dart';
import '../models/stock_model.dart';

class OrderSuccessDialog extends StatefulWidget {
  final OrderResult result;
  final RiskCalculation calculation;
  final Stock stock;
  final TradeSide tradeSide;

  const OrderSuccessDialog({
    super.key,
    required this.result,
    required this.calculation,
    required this.stock,
    required this.tradeSide,
  });

  static Future<void> show({
    required BuildContext context,
    required OrderResult result,
    required RiskCalculation calculation,
    required Stock stock,
    required TradeSide tradeSide,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => OrderSuccessDialog(
        result: result,
        calculation: calculation,
        stock: stock,
        tradeSide: tradeSide,
      ),
    );
  }

  @override
  State<OrderSuccessDialog> createState() => _OrderSuccessDialogState();
}

class _OrderSuccessDialogState extends State<OrderSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late AnimationController _fadeController;
  late AnimationController _particleController;

  late Animation<double> _scaleAnim;
  late Animation<double> _checkAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _particleAnim;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _checkController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _particleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));

    _scaleAnim = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
    _checkAnim = CurvedAnimation(parent: _checkController, curve: Curves.easeOutCubic);
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _particleAnim = CurvedAnimation(parent: _particleController, curve: Curves.easeOut);

    HapticFeedback.heavyImpact();

    _scaleController.forward().then((_) {
      _checkController.forward();
      _fadeController.forward();
      _particleController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isBuy = widget.tradeSide == TradeSide.BUY;
    final Color sideColor = isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final String sideLabel = isBuy ? 'BUY' : 'SELL';
    final calc = widget.calculation;
    final double riskAmt = (calc.entryPrice - calc.stopLoss).abs() * calc.quantity;
    final double rewardAmt = (calc.targetPrice - calc.entryPrice).abs() * calc.quantity;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Particle burst
            AnimatedBuilder(
              animation: _particleAnim,
              builder: (_, child) => CustomPaint(
                size: const Size(320, 520),
                painter: _ParticlePainter(_particleAnim.value, sideColor),
              ),
            ),

            // Main card
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: sideColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: sideColor.withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header gradient strip
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      gradient: LinearGradient(
                        colors: isBuy
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      children: [
                        // Animated checkmark circle
                        AnimatedBuilder(
                          animation: _checkAnim,
                          builder: (_, child) => Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sideColor.withValues(alpha: 0.12),
                              border: Border.all(
                                color: sideColor.withValues(alpha: _checkAnim.value),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: sideColor.withValues(alpha: 0.3 * _checkAnim.value),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.check_rounded,
                                size: 42 * _checkAnim.value,
                                color: sideColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Title
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: Column(
                            children: [
                              Text(
                                'Order Placed!',
                                style: TextStyle(
                                  color: sideColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sideColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: sideColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  '$sideLabel  \u2022  Groww Order',
                                  style: TextStyle(
                                    color: sideColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Stock + Order ID row
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1117),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF2A2E39)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: sideColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.stock.displaySymbol.substring(0, 1),
                                      style: TextStyle(
                                        color: sideColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.stock.displaySymbol,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        'Order #${widget.result.orderId}',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: const Text(
                                    'PENDING',
                                    style: TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Order details grid
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1117),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF2A2E39)),
                            ),
                            child: Column(
                              children: [
                                _detailRow('Entry Price',
                                    '\u20b9${calc.entryPrice.toStringAsFixed(2)}',
                                    Colors.white),
                                const SizedBox(height: 10),
                                _detailRow('Quantity',
                                    '${calc.quantity} Shares', Colors.white),
                                const SizedBox(height: 10),
                                _detailRow('Stop Loss',
                                    '\u20b9${calc.stopLoss.toStringAsFixed(2)}',
                                    const Color(0xFFEF4444)),
                                const SizedBox(height: 10),
                                _detailRow('Target Price',
                                    '\u20b9${calc.targetPrice.toStringAsFixed(2)}',
                                    const Color(0xFF10B981)),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(color: Color(0xFF2A2E39), height: 1),
                                ),
                                _detailRow('Max Risk',
                                    '\u20b9${riskAmt.toStringAsFixed(2)}',
                                    const Color(0xFFEF4444)),
                                const SizedBox(height: 8),
                                _detailRow('Max Reward',
                                    '\u20b9${rewardAmt.toStringAsFixed(2)}',
                                    const Color(0xFF10B981),
                                    bold: true),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Done button
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: sideColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Done',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color valueColor,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            fontSize: bold ? 15 : 13,
          ),
        ),
      ],
    );
  }
}

// Confetti / particle burst painter
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  static const int _count = 18;

  _ParticlePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.01) return;
    final center = Offset(size.width / 2, size.height / 2);
    final rng = math.Random(42);

    for (int i = 0; i < _count; i++) {
      final angle = (i / _count) * 2 * math.pi;
      final speed = 90.0 + rng.nextDouble() * 60.0;
      final dx = math.cos(angle) * speed * progress;
      final dy = math.sin(angle) * speed * progress - 30 * progress;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final radius = (3.0 + rng.nextDouble() * 3.0) * (1 - progress * 0.5);

      final Color particleColor = (i % 3 == 0
          ? Colors.white
          : i % 3 == 1
              ? color
              : const Color(0xFFF59E0B));

      final paint = Paint()
        ..color = particleColor.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center.translate(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress || old.color != color;
}
