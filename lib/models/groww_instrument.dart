/// Represents a single instrument entry from Groww's instrument data.
///
/// Key fields:
///   - [tradingSymbol]  e.g. "RELIANCE"
///   - [companyName]    e.g. "Reliance Industries Ltd."
///   - [exchange]       "NSE" or "BSE"
///   - [growwSymbol]    e.g. "NSE_RELIANCE"  (used for LTP + Order API calls)
class GrowwInstrument {
  final String tradingSymbol;
  final String companyName;
  final String exchange;
  final String growwSymbol; // format: EXCHANGE_SYMBOL, e.g. NSE_RELIANCE

  const GrowwInstrument({
    required this.tradingSymbol,
    required this.companyName,
    required this.exchange,
    required this.growwSymbol,
  });

  /// Build from a Groww instrument API JSON record.
  /// Handles multiple possible field name variants.
  factory GrowwInstrument.fromJson(Map<String, dynamic> json) {
    final String sym = (json['tradingSymbol'] ??
            json['trading_symbol'] ??
            json['symbol'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();

    final String exch = (json['exchange'] ??
            json['segment'] ??
            'NSE')
        .toString()
        .trim()
        .toUpperCase();

    final String name = (json['companyName'] ??
            json['company_name'] ??
            json['name'] ??
            sym)
        .toString()
        .trim();

    // Groww uses EXCHANGE_SYMBOL format for LTP / order API calls.
    // e.g. NSE_RELIANCE, BSE_RELIANCE
    final String gSym = (json['growwSymbol'] ??
            json['groww_symbol'] ??
            json['bseScriptCode'] ??
            '${exch}_$sym')
        .toString()
        .trim()
        .toUpperCase();

    return GrowwInstrument(
      tradingSymbol: sym,
      companyName: name,
      exchange: exch,
      growwSymbol: gSym.isNotEmpty ? gSym : '${exch}_$sym',
    );
  }

  Map<String, dynamic> toJson() => {
        'tradingSymbol': tradingSymbol,
        'companyName': companyName,
        'exchange': exchange,
        'growwSymbol': growwSymbol,
      };

  @override
  String toString() =>
      'GrowwInstrument($tradingSymbol | $exchange | $growwSymbol)';
}
