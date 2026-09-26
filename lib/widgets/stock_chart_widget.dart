import 'package:flutter/material.dart';

class StockChartPainter extends CustomPainter {
  final List<double> prices;
  final bool isPositive;

  StockChartPainter({required this.prices, required this.isPositive});

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    final double minPrice = prices.reduce((a, b) => a < b ? a : b);
    final double maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final double range = maxPrice - minPrice == 0 ? 1 : maxPrice - minPrice;

    final Color lineAccent = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    final Paint linePaint = Paint()
      ..color = lineAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path();
    final double stepX = size.width / (prices.length - 1);

    for (int i = 0; i < prices.length; i++) {
      final double x = i * stepX;
      final double normalizedY = (prices[i] - minPrice) / range;
      final double y = size.height - (normalizedY * (size.height - 12)) - 6;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw gradient fill under curve
    final Path fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineAccent.withValues(alpha: 0.25),
          lineAccent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant StockChartPainter oldDelegate) {
    return oldDelegate.prices != prices || oldDelegate.isPositive != isPositive;
  }
}
