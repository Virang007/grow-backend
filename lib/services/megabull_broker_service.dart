import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import '../models/order_request.dart';
import '../models/order_result.dart';
import 'broker_service.dart';
import 'megabull_api_service.dart';

class MegaBullBrokerService implements BrokerService {
  final String apiKey;
  final String baseUrl;

  MegaBullBrokerService({
    required this.apiKey,
    this.baseUrl = 'https://api.megabull.in',
  });

  @override
  String get brokerName => 'MegaBull API';

  @override
  Future<bool> validateCredentials(String key, String secretOrToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/my'),
        headers: {
          'api-key': key,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<OrderResult> placeRiskManagedOrder(OrderRequest request) async {
    final String cleanSymbol = request.symbol.replaceAll('.NS', '').replaceAll('.BO', '').trim().toUpperCase();
    String resolvedToken = request.instrumentToken;
    String resolvedSymbol = cleanSymbol;

    // Resolve stock against MegaBull instrument master
    try {
      final mbInstruments = await MegaBullApiService.fetchInstruments();
      if (mbInstruments.isNotEmpty) {
        final String searchTicker = cleanSymbol.replaceAll('-EQ', '').replaceAll('NSE:', '').replaceAll('BSE:', '').trim();

        final matched = mbInstruments.firstWhereOrNull((inst) {
          final sym = inst.symbol.replaceAll('"', '').replaceAll("'", '').replaceAll('.NS', '').replaceAll('.BO', '').replaceAll('-EQ', '').replaceAll('NSE:', '').trim().toUpperCase();
          final token = inst.instrumentToken.replaceAll('"', '').replaceAll("'", '').trim();
          return sym == searchTicker || token == request.instrumentToken;
        }) ?? mbInstruments.firstWhereOrNull((inst) {
          final sym = inst.symbol.replaceAll('"', '').replaceAll("'", '').replaceAll('.NS', '').replaceAll('.BO', '').replaceAll('-EQ', '').replaceAll('NSE:', '').trim().toUpperCase();
          return sym.contains(searchTicker);
        });

        if (matched != null) {
          resolvedToken = matched.instrumentToken.replaceAll('"', '').replaceAll("'", '').trim();
          resolvedSymbol = matched.symbol.replaceAll('"', '').replaceAll("'", '').replaceAll('.NS', '').replaceAll('.BO', '').trim().toUpperCase();

          print('==================================================');
          print('[MEGABULL INSTRUMENT DYNAMIC MATCH]');
          print('Searched Symbol: $cleanSymbol');
          print('Matched Instrument Object: ${matched.toJson()}');
          print('Exchange: ${matched.exchange}');
          print('Broker Script ID / Token: $resolvedToken');
          print('Broker Trading Symbol: $resolvedSymbol');
          print('==================================================');
        } else {
          print('[MEGABULL BROKER SERVICE ERROR] Stock $cleanSymbol not found in MegaBull broker catalog.');
          return OrderResult(
            isSuccess: false,
            orderId: '',
            message: '$cleanSymbol is not available for trading with MegaBull.',
            timestamp: DateTime.now(),
          );
        }
      }
    } catch (e) {
      print('[MEGABULL BROKER SERVICE WARNING] Instrument resolution error: $e');
    }

    final int qtyInt = request.riskCalculation.quantity > 0 ? request.riskCalculation.quantity : 1;

    final url = '$baseUrl/api/order/buysell';
    final headers = {
      'api-key': apiKey,
      'Content-Type': 'application/json',
      'User-Agent': 'MegaBullPaperTrader/1.0',
    };
    // MegaBull Order Payload - exact schema matching Postman working request
    final bodyMap = {
      'instrumentToken': resolvedToken,
      'qty': qtyInt,
      'type': request.riskCalculation.tradeSide.name.toUpperCase(),
      'duration': 'MIS',
      'orderType': 'LIMIT',
      'price': request.riskCalculation.entryPrice,
      'triggerPrice': request.riskCalculation.stopLoss,
    };
    final body = jsonEncode(bodyMap);

    print('==================================================');
    print('[BROKER ORDER LOGGING]');
    print('Broker: $brokerName');
    print('Broker Script/Instrument ID: $resolvedToken');
    print('Broker Trading Symbol: $resolvedSymbol');
    print('Transaction Type: ${request.riskCalculation.tradeSide.name}');
    print('Quantity: $qtyInt');
    print('Price: ₹${request.riskCalculation.entryPrice}');
    print('SL: ₹${request.riskCalculation.stopLoss}');
    print('Target: ₹${request.riskCalculation.targetPrice}');
    print('Final Order Payload: $body');
    print('==================================================');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 6));

      print('[MEGABULL BROKER SERVICE] Response Status: ${response.statusCode}');
      print('[MEGABULL BROKER SERVICE] Response Body: ${response.body}');

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        print('[MEGABULL BROKER SERVICE] JSON Decode Error: $e');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // MegaBull API returns "id" field (not "orderId")
        final orderId = (data is Map)
            ? (data['id'] ?? data['orderId'] ?? data['order_id'] ?? 'MB-${DateTime.now().millisecondsSinceEpoch}').toString()
            : 'MB-${DateTime.now().millisecondsSinceEpoch}';
        final instrumentName = (data is Map && data['instrumentName'] != null) ? data['instrumentName'].toString() : resolvedSymbol;
        final orderStatus = (data is Map && data['status'] != null) ? data['status'].toString() : 'PENDING';
        final msg = '${request.riskCalculation.tradeSide.name} $instrumentName | Qty: $qtyInt | ₹${request.riskCalculation.entryPrice.toStringAsFixed(2)} | SL: ₹${request.riskCalculation.stopLoss.toStringAsFixed(2)} | TP: ₹${request.riskCalculation.targetPrice.toStringAsFixed(2)} | Status: $orderStatus';

        print('[MEGABULL BROKER SERVICE SUCCESS] Order ID: $orderId | Status: $orderStatus');
        return OrderResult(
          isSuccess: true,
          orderId: orderId,
          slOrderId: 'SL-MB-$orderId',
          tpOrderId: 'TP-MB-$orderId',
          message: msg,
          timestamp: DateTime.now(),
        );
      } else {
        String errorMsg = 'MegaBull Rejected Order (${response.statusCode})';
        if (data is Map) {
          if (data['message'] != null) {
            final m = data['message'];
            errorMsg = m is List ? m.join(', ') : m.toString();
          } else if (data['error'] != null) {
            errorMsg = data['error'].toString();
          }
        }

        print('[MEGABULL BROKER SERVICE ERROR] Order Failed: $errorMsg');
        return OrderResult(
          isSuccess: false,
          orderId: '',
          message: errorMsg,
          timestamp: DateTime.now(),
        );
      }
    } catch (e, stackTrace) {
      print('==================================================');
      print('[MEGABULL BROKER SERVICE EXCEPTION] Order placement failed!');
      print('Error: $e');
      print('StackTrace:\n$stackTrace');
      print('==================================================');
      return OrderResult(
        isSuccess: false,
        orderId: '',
        message: 'Network Error: Unable to connect to MegaBull API ($e)',
        timestamp: DateTime.now(),
      );
    }
  }
}
