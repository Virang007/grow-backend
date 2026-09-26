import '../models/stock.dart';

class StockService {
  static final List<Stock> _allStocks = [
    Stock(
      symbol: 'AAPL',
      name: 'Apple Inc.',
      price: 232.80,
      change: 3.45,
      percentChange: 1.50,
      open: 229.35,
      high: 233.10,
      low: 228.90,
      marketCap: '\$3.57T',
      peRatio: 34.2,
      volume: 48200000,
      chartData: [225.0, 226.4, 224.8, 227.1, 229.5, 230.2, 232.8],
    ),
    Stock(
      symbol: 'NVDA',
      name: 'NVIDIA Corporation',
      price: 128.40,
      change: 5.60,
      percentChange: 4.56,
      open: 123.10,
      high: 129.20,
      low: 122.80,
      marketCap: '\$3.15T',
      peRatio: 48.5,
      volume: 72100000,
      chartData: [118.0, 120.2, 122.0, 124.5, 123.8, 126.1, 128.4],
    ),
    Stock(
      symbol: 'TSLA',
      name: 'Tesla, Inc.',
      price: 245.50,
      change: -4.20,
      percentChange: -1.68,
      open: 250.00,
      high: 252.30,
      low: 243.80,
      marketCap: '\$782.4B',
      peRatio: 62.1,
      volume: 59300000,
      chartData: [255.0, 253.2, 250.0, 248.5, 249.0, 247.2, 245.5],
    ),
    Stock(
      symbol: 'AMZN',
      name: 'Amazon.com Inc.',
      price: 186.20,
      change: 2.10,
      percentChange: 1.14,
      open: 184.50,
      high: 187.00,
      low: 183.90,
      marketCap: '\$1.94T',
      peRatio: 42.8,
      volume: 34100000,
      chartData: [181.0, 182.5, 183.0, 184.2, 185.0, 185.8, 186.2],
    ),
    Stock(
      symbol: 'MSFT',
      name: 'Microsoft Corporation',
      price: 435.15,
      change: 1.85,
      percentChange: 0.43,
      open: 433.50,
      high: 436.80,
      low: 432.10,
      marketCap: '\$3.23T',
      peRatio: 36.4,
      volume: 21500000,
      chartData: [428.0, 430.1, 431.5, 432.0, 434.0, 433.8, 435.15],
    ),
    Stock(
      symbol: 'GOOGL',
      name: 'Alphabet Inc.',
      price: 178.90,
      change: -1.10,
      percentChange: -0.61,
      open: 180.00,
      high: 181.20,
      low: 177.50,
      marketCap: '\$2.21T',
      peRatio: 25.1,
      volume: 28400000,
      chartData: [182.0, 181.4, 180.2, 179.8, 180.5, 179.1, 178.9],
    ),
    Stock(
      symbol: 'META',
      name: 'Meta Platforms Inc.',
      price: 512.30,
      change: 8.70,
      percentChange: 1.73,
      open: 504.00,
      high: 514.50,
      low: 503.20,
      marketCap: '\$1.30T',
      peRatio: 28.9,
      volume: 16800000,
      chartData: [495.0, 498.2, 502.0, 505.4, 508.1, 510.0, 512.3],
    ),
    Stock(
      symbol: 'RELIANCE',
      name: 'Reliance Industries Ltd.',
      price: 2985.40,
      change: 24.50,
      percentChange: 0.83,
      open: 2965.00,
      high: 2992.00,
      low: 2960.00,
      marketCap: '₹20.2T',
      peRatio: 26.8,
      volume: 9400000,
      chartData: [2920.0, 2935.0, 2950.0, 2962.0, 2970.0, 2978.0, 2985.4],
    ),
    Stock(
      symbol: 'TCS',
      name: 'Tata Consultancy Services',
      price: 4280.00,
      change: -15.60,
      percentChange: -0.36,
      open: 4300.00,
      high: 4312.00,
      low: 4265.00,
      marketCap: '₹15.5T',
      peRatio: 31.2,
      volume: 4100000,
      chartData: [4320.0, 4310.0, 4295.0, 4305.0, 4290.0, 4285.0, 4280.0],
    ),
    Stock(
      symbol: 'BTC-USD',
      name: 'Bitcoin / US Dollar',
      price: 64250.00,
      change: 1420.00,
      percentChange: 2.26,
      open: 62830.00,
      high: 64800.00,
      low: 62500.00,
      marketCap: '\$1.27T',
      peRatio: 0.0,
      volume: 38200000000,
      chartData: [61200.0, 62000.0, 61800.0, 62900.0, 63400.0, 63800.0, 64250.0],
    ),
  ];

  static List<Stock> getAllStocks() {
    return List.from(_allStocks);
  }

  static List<Stock> searchStocks(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    return _allStocks.where((s) {
      return s.symbol.toLowerCase().contains(q) ||
          s.name.toLowerCase().contains(q);
    }).toList();
  }

  static Stock? getStockBySymbol(String symbol) {
    try {
      return _allStocks.firstWhere(
        (s) => s.symbol.toUpperCase() == symbol.toUpperCase(),
      );
    } catch (_) {
      // Dynamic fallback for custom tickers
      return Stock(
        symbol: symbol.toUpperCase(),
        name: '${symbol.toUpperCase()} Corp',
        price: 150.00,
        change: 2.50,
        percentChange: 1.69,
        open: 147.50,
        high: 151.20,
        low: 147.00,
        marketCap: '\$50.0B',
        peRatio: 22.4,
        volume: 12000000,
        chartData: [142.0, 144.5, 146.0, 145.8, 147.2, 148.9, 150.0],
      );
    }
  }
}
