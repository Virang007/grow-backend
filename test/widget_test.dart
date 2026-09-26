import 'package:flutter_test/flutter_test.dart';
import 'package:riskmanageapp/main.dart';

void main() {
  testWidgets('App renders markets screen properly', (WidgetTester tester) async {
    await tester.pumpWidget(const StockRiskManagerApp());
    expect(find.text('Markets'), findsOneWidget);
    expect(find.text('My Watchlist'), findsOneWidget);
  });
}
