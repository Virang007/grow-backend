import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:otp/otp.dart';
import '../models/order_request.dart';
import '../models/order_result.dart';
import 'broker_service.dart';

/// Helper: mask a sensitive string — show only first 8 chars, rest as ****
String _mask(String s) {
  if (s.isEmpty) return '(empty)';
  final show = s.length > 8 ? s.substring(0, 8) : s.substring(0, s.length ~/ 2);
  return '$show****';
}

/// Official Groww Trading API Service.
class GrowwBrokerService implements BrokerService {
  final String apiKey;     // Groww TOTP Token
  final String apiSecret;  // Unused / Legacy
  final String totpSecret; // Groww TOTP Base32 Secret
  final String savedAccessToken; // Saved Groww Access Token
  final String baseUrl;

  GrowwBrokerService({
    required this.apiKey,
    this.apiSecret = '',
    this.totpSecret = '',
    this.savedAccessToken = '',
    this.baseUrl = 'https://www.freewpplugin.com',
  });

  @override
  String get brokerName => 'Groww';

  // ─────────────────────────────────────────────────────────────────
  // STEP 2 — Exchange API Key + Checksum for ACCESS_TOKEN
  // POST /v1/token/api/access  (Approval Flow — official Groww docs)
  // Body: {"key_type":"approval","checksum":"<hex>","timestamp":"<epoch_secs>"}
  // ─────────────────────────────────────────────────────────────────
  /// Generates a real Access Token from Groww using TOTP flow:
  /// 1. Generates 6-digit TOTP from growwTotpSecret using SHA1.
  /// 2. Calls POST /v1/token/api/access with Bearer growwTotpToken.
  /// 3. Returns the real access token string on success or throws an exception on error.
  static Future<String?> generateAccessToken({
    required String growwTotpToken,
    required String growwTotpSecret,
    String baseUrl = 'https://api.groww.in',
  }) async {
    if (growwTotpToken.trim().isEmpty) {
      throw Exception('Groww TOTP Token cannot be empty.');
    }
    if (growwTotpSecret.trim().isEmpty) {
      throw Exception('Groww TOTP Secret cannot be empty.');
    }

    try {
      final totp = OTP.generateTOTPCodeString(
        growwTotpSecret.trim(),
        DateTime.now().millisecondsSinceEpoch,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );

      print('[GROWW AUTH] Generated 6-digit TOTP: $totp');

      final url = '$baseUrl/v1/token/api/access';
      
      // Attempt 1: Standard 'totp' key_type payload
      var response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${growwTotpToken.trim()}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'key_type': 'totp',
          'totp': totp,
        }),
      ).timeout(const Duration(seconds: 12));

      print('[GROWW AUTH] Response Status (key_type=totp): ${response.statusCode}');
      print('[GROWW AUTH] Response Body: ${response.body}');

      // Attempt 2: If key_type 'totp' is rejected, compute HMAC-SHA256 checksum & timestamp for key_type 'approval'
      if (response.statusCode == 400 && response.body.contains('Invalid type provided')) {
        print('[GROWW AUTH] Retrying with key_type = "approval" & HMAC-SHA256 checksum...');
        final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
        final keyBytes = utf8.encode(growwTotpSecret.trim());
        final msgBytes = utf8.encode(timestamp);
        final hmac = Hmac(sha256, keyBytes);
        final checksum = hmac.convert(msgBytes).toString();

        print('[GROWW AUTH] Generated Checksum: $checksum | Timestamp: $timestamp');

        response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer ${growwTotpToken.trim()}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'key_type': 'approval',
            'checksum': checksum,
            'timestamp': timestamp,
          }),
        ).timeout(const Duration(seconds: 12));

        print('[GROWW AUTH] Response Status (key_type=approval): ${response.statusCode}');
        print('[GROWW AUTH] Response Body: ${response.body}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        String? accessToken;
        if (data is Map) {
          final resp = data['response'];
          if (resp is Map) {
            accessToken = resp['token']?.toString() ?? resp['access_token']?.toString();
          }
          accessToken ??= data['token']?.toString() ?? data['access_token']?.toString();
        }

        if (accessToken != null && accessToken.isNotEmpty) {
          print('[GROWW AUTH] ✅ Real Access Token generated successfully!');
          return accessToken;
        } else {
          throw Exception('Groww API returned success but token was missing in response body: ${response.body}');
        }
      } else {
        dynamic errData;
        try {
          errData = jsonDecode(response.body);
        } catch (_) {}

        String errorMsg = 'HTTP ${response.statusCode}';
        if (errData is Map && errData['error'] is Map && errData['error']['errorMessage'] != null) {
          errorMsg = errData['error']['errorMessage'].toString();
        } else if (errData is Map && errData['errorMessage'] != null) {
          final msgObj = errData['errorMessage'];
          errorMsg = msgObj is Map ? (msgObj['message'] ?? msgObj.toString()) : msgObj.toString();
        } else if (errData is Map && errData['message'] != null) {
          errorMsg = errData['message'].toString();
        } else if (response.body.isNotEmpty) {
          errorMsg = response.body;
        }
        throw Exception('Groww Token Error (HTTP ${response.statusCode}): $errorMsg');
      }
    } catch (e) {
      print('[GROWW AUTH ERROR] $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 3 — Validate ACCESS_TOKEN via GET /v1/user/detail
  // ─────────────────────────────────────────────────────────────────
  Future<bool> _validateAccessToken(String accessToken) async {
    final url = '$baseUrl/v1/user/detail';
    print('[GROWW AUTH] Validating ACCESS_TOKEN via $url');
    print('[GROWW AUTH] Access Token: ${_mask(accessToken)}');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          'X-API-VERSION': '1.0',
        },
      ).timeout(const Duration(seconds: 8));

      print('[GROWW AUTH] Validation Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[GROWW AUTH] ✅ ACCESS_TOKEN validated — user session active');
        return true;
      } else {
        final errDetail = _extractGrowwError(response);
        print('[GROWW AUTH] ❌ Validation failed: HTTP ${response.statusCode} — $errDetail');
        return false;
      }
    } catch (e, st) {
      print('[GROWW AUTH EXCEPTION] Validation failed: $e');
      print('[GROWW AUTH EXCEPTION] StackTrace: $st');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // GET OR REFRESH ACCESS TOKEN
  // Re-generates a fresh token from TOTP credentials on demand.
  // This allows LTP + Order APIs to work without manual reconnect.
  // ─────────────────────────────────────────────────────────────────
  Future<String?> getOrRefreshToken() async {
    if (apiKey.isEmpty || totpSecret.isEmpty) return null;
    try {
      final token = await generateAccessToken(
        growwTotpToken: apiKey,
        growwTotpSecret: totpSecret,
        baseUrl: baseUrl,
      );
      print('[GROWW LTP] ✅ Refreshed access token successfully');
      return token;
    } catch (e) {
      print('[GROWW LTP] ❌ Token refresh failed: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // FETCH LIVE TRADED PRICE (LTP)
  // GET /v1/live-data/ltp
  // Returns the last traded price in INR for a given Groww symbol.
  //
  // [growwSymbol] — format: NSE_RELIANCE, BSE_TCS, etc.
  // [accessToken] — a valid Groww access token. If null, one is
  //                 generated automatically from stored TOTP credentials.
  //
  // Returns null on any error (caller should fall back to Yahoo price).
  // ─────────────────────────────────────────────────────────────────
  Future<double?> fetchLTP({
    required String growwSymbol,
    String? accessToken,
  }) async {
    String? token = accessToken;
    token ??= await getOrRefreshToken();

    if (token == null || token.isEmpty) {
      print('[GROWW LTP] ❌ No access token available for LTP call');
      return null;
    }

    // Groww LTP endpoint accepts one or more symbols as query params.
    // Format: GET /v1/live-data/ltp?isin=NSE_RELIANCE
    final url = Uri.parse('$baseUrl/v1/live-data/ltp').replace(
      queryParameters: {'isin': growwSymbol.toUpperCase()},
    );

    print('[GROWW LTP] Fetching LTP for $growwSymbol → $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'X-API-VERSION': '1.0',
        },
      ).timeout(const Duration(seconds: 8));

      print('[GROWW LTP] HTTP ${response.statusCode} — ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic data = jsonDecode(response.body);

        // Groww LTP response shapes observed in the wild:
        // 1. { "ltp": 2334.20 }
        // 2. { "data": { "ltp": 2334.20 } }
        // 3. { "result": [{ "ltp": 2334.20, "symbol": "NSE_RELIANCE" }] }
        // 4. { "response": { "data": [{ "ltp": 2334.20 }] } }
        double? ltp;

        if (data is Map) {
          ltp = _extractLtpFromMap(Map<String, dynamic>.from(data));
        } else if (data is List && data.isNotEmpty) {
          final first = data[0];
          if (first is Map) ltp = _extractLtpFromMap(Map<String, dynamic>.from(first));
        }

        if (ltp != null && ltp > 0) {
          print('[GROWW LTP] ✅ LTP for $growwSymbol = ₹$ltp');
          return ltp;
        } else {
          print('[GROWW LTP] ⚠️ LTP parsed as null/zero from body: ${response.body}');
          return null;
        }
      } else {
        final errDetail = _extractGrowwError(response);
        print('[GROWW LTP] ❌ HTTP ${response.statusCode} — $errDetail');
        return null;
      }
    } catch (e) {
      print('[GROWW LTP EXCEPTION] $e');
      return null;
    }
  }

  /// Extracts ltp value from any level of Map nesting.
  double? _extractLtpFromMap(Map<String, dynamic> map) {
    // Direct ltp key
    if (map['ltp'] != null) return (map['ltp'] as num?)?.toDouble();
    if (map['lastTradedPrice'] != null) return (map['lastTradedPrice'] as num?)?.toDouble();
    if (map['price'] != null) return (map['price'] as num?)?.toDouble();

    // One level deeper
    final data = map['data'] ?? map['response'] ?? map['result'];
    if (data is Map) {
      return _extractLtpFromMap(data as Map<String, dynamic>);
    } else if (data is List && data.isNotEmpty) {
      final first = data[0];
      if (first is Map) return _extractLtpFromMap(first as Map<String, dynamic>);
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────
  // VALIDATE CREDENTIALS (BrokerService interface)
  // Runs TOTP → generateAccessToken → validate flow
  // ─────────────────────────────────────────────────────────────────
  @override
  Future<bool> validateCredentials(String key, String secretOrToken) async {
    final tokenToUse = key.isNotEmpty ? key : apiKey;
    final secretToUse = secretOrToken.isNotEmpty ? secretOrToken : totpSecret;

    if (tokenToUse.isEmpty || secretToUse.isEmpty) {
      return false;
    }

    try {
      final accessToken = await generateAccessToken(
        growwTotpToken: tokenToUse,
        growwTotpSecret: secretToUse,
        baseUrl: baseUrl,
      );
      if (accessToken == null) return false;
      return _validateAccessToken(accessToken);
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // PLACE RISK MANAGED ORDER
  // ─────────────────────────────────────────────────────────────────
  @override
  Future<OrderResult> placeRiskManagedOrder(OrderRequest request) async {
    // 1. Check if saved access token exists
    String tokenToUse = savedAccessToken.trim();

    // 2. If no saved access token, fail immediately with clear session error
    if (tokenToUse.isEmpty) {
      print('[GROWW ORDER ERROR] No saved Groww access token found.');
      return _failure('Groww session expired or not connected. Please connect Groww in Broker Settings.');
    }

    print('==================================================');
    print('[GROWW ORDER] Placing order using saved ACCESS_TOKEN: ${_mask(tokenToUse)}');
    print('==================================================');

    // 3. Attempt order placement using saved token directly
    OrderResult result = await _placeOrder(request, tokenToUse);

    // 4. If order failed due to 401 / token expiration, attempt single re-authentication fallback
    if (!result.isSuccess && _isAuthError(result.message)) {
      print('[GROWW ORDER] Saved token rejected (401/Auth failure). Attempting 1-time token refresh...');

      if (apiKey.isEmpty || totpSecret.isEmpty) {
        return _failure('Groww session expired. Re-authentication failed: missing TOTP credentials.');
      }

      try {
        final newToken = await generateAccessToken(
          growwTotpToken: apiKey,
          growwTotpSecret: totpSecret,
          baseUrl: baseUrl,
        );

        if (newToken != null && newToken.isNotEmpty) {
          print('[GROWW ORDER] Token refresh successful. Retrying order once...');
          result = await _placeOrder(request, newToken);
        } else {
          return _failure('Groww session expired. Could not refresh token. Please reconnect in Broker Settings.');
        }
      } catch (e) {
        print('[GROWW ORDER ERROR] Token refresh retry failed: $e');
        return _failure('Groww session expired. Token refresh failed: $e');
      }
    }

    return result;
  }

  bool _isAuthError(String message) {
    // GA005 = "No registered IPs" — this is a config error, NOT a token/auth
    // expiry. Never retry on this; show a clear user message instead.
    if (message.contains('[GA005]')) return false;

    final lower = message.toLowerCase();
    return lower.contains('401') ||
        lower.contains('unauthorized') ||
        lower.contains('token expired') ||
        lower.contains('invalid token') ||
        lower.contains('session invalid');
  }

  // ─────────────────────────────────────────────────────────────────
  // Internal: POST /v1/order/create using validated ACCESS_TOKEN
  // ─────────────────────────────────────────────────────────────────
  Future<OrderResult> _placeOrder(OrderRequest request, String accessToken) async {
    final String tradingSymbol = request.symbol
        .replaceAll('.NS', '')
        .replaceAll('.BO', '')
        .trim()
        .toUpperCase();

    final int qty =
        request.riskCalculation.quantity > 0 ? request.riskCalculation.quantity : 1;
    final String exchange =
        request.exchange.isNotEmpty ? request.exchange : 'NSE';
    final String transactionType =
        request.riskCalculation.tradeSide.name.toUpperCase();
    final String orderRefId = 'RMA-${DateTime.now().millisecondsSinceEpoch}';
    final String url = '$baseUrl/v1/order/create';

    final String product = request.productType.isNotEmpty ? request.productType : 'MIS';

    // Groww documented snake_case payload — NO stopLoss / targetPrice in this call
    final Map<String, dynamic> bodyMap = {
      'trading_symbol': tradingSymbol,
      'quantity': qty,
      'price': request.riskCalculation.entryPrice,
      'validity': 'DAY',
      'exchange': exchange,
      'segment': 'CASH',
      'product': product,
      'order_type': 'LIMIT',
      'transaction_type': transactionType,
      'order_reference_id': orderRefId,
    };

    final String body = jsonEncode(bodyMap);

    print('==================================================');
    print('[GROWW ORDER] Placing order with validated ACCESS_TOKEN');
    print('[GROWW ORDER] URL: $url');
    print('[GROWW ORDER] Access Token: ${_mask(accessToken)}');
    print('[GROWW ORDER] Symbol: $tradingSymbol | Type: $transactionType | Qty: $qty | Price: ₹${request.riskCalculation.entryPrice}');
    print('[GROWW ORDER] Exchange: $exchange | Ref ID: $orderRefId');
    print('[GROWW ORDER] SL: ₹${request.riskCalculation.stopLoss} (Groww Smart Order API — separate call)');
    print('[GROWW ORDER] Target: ₹${request.riskCalculation.targetPrice} (Groww Smart Order API — separate call)');
    print('[GROWW ORDER] Payload: $body');
    print('==================================================');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-API-VERSION': '1.0',
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      print('[GROWW ORDER] Response Status: ${response.statusCode}');
      print('[GROWW ORDER] Response Body: ${response.body}');

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String orderId = (data is Map)
            ? (data['order_id'] ?? data['orderId'] ?? '').toString()
            : '';

        if (orderId.isEmpty) {
          print('[GROWW ORDER ERROR] Groww returned success but no order_id. Body: ${response.body}');
          return _failure(
              'Groww returned success (HTTP ${response.statusCode}) but no order_id in response. Check Groww API dashboard.');
        }

        final msg =
            'Groww $transactionType Order Placed | $tradingSymbol | Qty: $qty | ₹${request.riskCalculation.entryPrice.toStringAsFixed(2)} | ID: $orderId';
        print('[GROWW ORDER] ✅ $msg');
        print('[GROWW ORDER] ⚠️  SL & Target must be placed via Groww Smart Order API (not yet implemented).');

        return OrderResult(
          isSuccess: true,
          orderId: orderId,
          slOrderId: 'SL_PENDING_SMART_ORDER_API',
          tpOrderId: 'TP_PENDING_SMART_ORDER_API',
          message: msg,
          timestamp: DateTime.now(),
        );
      }

      // Real Groww API error
      final String errorMsg = _buildErrorMsg(response, data);
      print('[GROWW ORDER ERROR] ❌ HTTP ${response.statusCode} — $errorMsg');
      return _failure(errorMsg);
    } catch (e, st) {
      print('[GROWW ORDER EXCEPTION] ❌ $e');
      print('[GROWW ORDER EXCEPTION] StackTrace: $st');
      return _failure('Network Error: Could not connect to Groww API. ($e)');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────

  OrderResult _failure(String msg) => OrderResult(
        isSuccess: false,
        orderId: '',
        message: msg,
        timestamp: DateTime.now(),
      );

  /// Extracts human-readable error text from a Groww error response.
  /// Handles Groww's nested: {"errorCode":401,"errorMessage":{"message":"..."},"code":"GA005"}
  ({String message, String? code}) _extractGrowwError(http.Response response) {
    try {
      final dynamic body = jsonDecode(response.body);
      if (body is Map) {
        // Extract error code (e.g. "GA005")
        final String? code = (body['code'] ?? body['errorCode']?.toString())?.toString();

        // Extract human message from nested or flat fields
        final dynamic errField = body['errorMessage'];
        String msg;
        if (errField is Map && errField['message'] != null) {
          msg = errField['message'].toString();
        } else if (errField is String) {
          msg = errField;
        } else {
          final dynamic flat = body['message'] ?? body['error'] ?? body['errMsg'];
          msg = flat?.toString() ?? '';
        }

        if (msg.isEmpty) {
          msg = response.body.length > 200
              ? response.body.substring(0, 200)
              : response.body;
        }
        return (message: msg, code: code);
      }
    } catch (_) {}
    final raw = response.body.length > 200
        ? response.body.substring(0, 200)
        : response.body;
    return (message: raw, code: null);
  }

  String _buildErrorMsg(http.Response response, dynamic data) {
    final extracted = _extractGrowwError(response);
    final String base = extracted.message;
    final String? code = extracted.code;

    // ── GA005: IP not registered — config error, never retry ──────────
    if (code == 'GA005' ||
        base.toLowerCase().contains('no registered ip') ||
        base.toLowerCase().contains('registered ips found')) {
      print('[GROWW ORDER ERROR] ❌ GA005 — IP not registered. Halting retry.');
      return '[GA005] Your IP is not registered with Groww API. '
          'Please go to Groww API Settings → Allowed IPs and add your current IP address. '
          'Then reconnect in Broker Settings.';
    }

    if (response.statusCode == 401) {
      return 'Groww 401 Unauthorized: $base — ACCESS_TOKEN rejected. Re-authenticate.';
    } else if (response.statusCode == 403) {
      return 'Groww 403 Forbidden: $base — Insufficient API permissions.';
    } else if (response.statusCode == 404) {
      return 'Groww 404 Not Found: $base — Endpoint not available. Check Base URL.';
    } else if (response.statusCode == 429) {
      return 'Groww 429 Rate Limited: $base — Too many requests, wait and retry.';
    } else if (response.statusCode >= 500) {
      return 'Groww ${response.statusCode} Server Error: $base — Groww API unavailable, try later.';
    }
    return 'Groww API Error (HTTP ${response.statusCode}): $base';
  }
}
