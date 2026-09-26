import 'package:flutter_test/flutter_test.dart';
import 'package:riskmanageapp/main.dart';

void main() {
  testWidgets('App renders Indian stock markets screen properly', (WidgetTester tester) async {
    await tester.pumpWidget(const StockRiskManagerApp());
    expect(find.text('Indian Markets (NSE/BSE)'), findsOneWidget);
    expect(find.text('NSE/BSE Watchlist'), findsOneWidget);
  });
}
