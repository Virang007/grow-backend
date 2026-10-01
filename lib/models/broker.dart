enum BrokerStatus { connected, disconnected, testing, failed }

class BrokerAccount {
  final String id;
  String name;
  String logoSymbol;
  String description;
  String apiKey;      // Groww API Key (used to get ACCESS_TOKEN via TOTP flow)
  String apiSecret;   // Legacy / unused for Groww
  String totpSecret;  // Groww TOTP Secret (base32) — used to generate 6-digit TOTP
  String accountId;
  String baseUrl;
  String environment; // Sandbox / Live
  BrokerStatus status;
  DateTime? lastConnectedAt;
  bool isCustom;

  BrokerAccount({
    required this.id,
    required this.name,
    required this.logoSymbol,
    required this.description,
    this.apiKey = '',
    this.apiSecret = '',
    this.totpSecret = '',
    this.accountId = '',
    this.baseUrl = '',
    this.environment = 'Sandbox',
    this.status = BrokerStatus.disconnected,
    this.lastConnectedAt,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoSymbol': logoSymbol,
      'description': description,
      'apiKey': apiKey,
      'apiSecret': apiSecret,
      'totpSecret': totpSecret,
      'accountId': accountId,
      'baseUrl': baseUrl,
      'environment': environment,
      'status': status.name,
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
      'isCustom': isCustom,
    };
  }

  factory BrokerAccount.fromJson(Map<String, dynamic> json) {
    return BrokerAccount(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      logoSymbol: json['logoSymbol'] ?? 'BK',
      description: json['description'] ?? '',
      apiKey: json['apiKey'] ?? '',
      apiSecret: json['apiSecret'] ?? '',
      totpSecret: json['totpSecret'] ?? '', // Must be real Base32 secret from Groww API Portal
      accountId: json['accountId'] ?? '',
      baseUrl: json['baseUrl'] ?? '',
      environment: json['environment'] ?? 'Sandbox',
      status: BrokerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BrokerStatus.disconnected,
      ),
      lastConnectedAt: json['lastConnectedAt'] != null
          ? DateTime.tryParse(json['lastConnectedAt'])
          : null,
      isCustom: json['isCustom'] ?? false,
    );
  }
}
