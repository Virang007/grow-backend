import '../models/order_request.dart';
import '../models/order_result.dart';

abstract class BrokerService {
  String get brokerName;

  /// Place Entry + Stop Loss + Target Order with connected broker
  Future<OrderResult> placeRiskManagedOrder(OrderRequest request);

  /// Test & validate API Key / Secret credentials
  Future<bool> validateCredentials(String apiKey, String secretOrToken);
}
