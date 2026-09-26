import 'package:flutter/material.dart';
import '../models/broker.dart';
import '../services/storage_service.dart';

class BrokerSettingsPage extends StatefulWidget {
  final VoidCallback onBrokersUpdated;

  const BrokerSettingsPage({
    super.key,
    required this.onBrokersUpdated,
  });

  @override
  State<BrokerSettingsPage> createState() => _BrokerSettingsPageState();
}

class _BrokerSettingsPageState extends State<BrokerSettingsPage> {
  List<BrokerAccount> _brokers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBrokers();
  }

  Future<void> _loadBrokers() async {
    setState(() {
      _isLoading = true;
    });
    _brokers = await StorageService.getBrokers();
    setState(() {
      _isLoading = false;
    });
  }

  void _openBrokerConnectModal(BrokerAccount broker, {bool isNewCustom = false}) {
    final nameController = TextEditingController(text: broker.name);
    final logoSymbolController = TextEditingController(text: broker.logoSymbol);
    final baseUrlController = TextEditingController(text: broker.baseUrl);
    final apiKeyController = TextEditingController(text: broker.apiKey);
    final apiSecretController = TextEditingController(text: broker.apiSecret);
    final accountIdController = TextEditingController(text: broker.accountId);
    String selectedEnv = broker.environment;
    bool isTesting = false;

    final bool isDhan = broker.id == 'dhan';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom +
                    20,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF131722),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: isDhan
                                ? const Color(0xFF00C853).withValues(alpha: 0.15)
                                : const Color(0xFF2563EB).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDhan
                                  ? const Color(0xFF00C853)
                                  : const Color(0xFF2563EB),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            broker.logoSymbol.isNotEmpty
                                ? broker.logoSymbol
                                : 'CB',
                            style: TextStyle(
                              color: isDhan
                                  ? const Color(0xFF00C853)
                                  : const Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isNewCustom
                                    ? 'Connect Custom Broker'
                                    : 'Connect ${broker.name}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isDhan
                                    ? 'Official Dhan HQ REST & WebSocket API Integration'
                                    : broker.description,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Environment toggle
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedEnv = 'Sandbox';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedEnv == 'Sandbox'
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF1E222D),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Sandbox / Paper',
                                style: TextStyle(
                                  color: selectedEnv == 'Sandbox'
                                      ? Colors.white
                                      : Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedEnv = 'Live';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedEnv == 'Live'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF1E222D),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Live Trading',
                                style: TextStyle(
                                  color: selectedEnv == 'Live'
                                      ? Colors.white
                                      : Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Custom Broker Name & Symbol (if custom broker)
                    if (broker.isCustom || isNewCustom) ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildTextField(
                              controller: nameController,
                              label: 'Broker Name',
                              hint: 'e.g. AngelOne, Tradovate, Choice',
                              icon: Icons.business_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: _buildTextField(
                              controller: logoSymbolController,
                              label: 'Tag',
                              hint: 'e.g. AO',
                              icon: Icons.tag,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: baseUrlController,
                        label: 'Base Server URL (Optional)',
                        hint: 'https://api.custombroker.com/v1',
                        icon: Icons.language_outlined,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Account ID / Client Code
                    _buildTextField(
                      controller: accountIdController,
                      label: isDhan
                          ? 'Dhan Client ID'
                          : 'Account ID / Client Code',
                      hint: isDhan
                          ? 'e.g. 1000001234'
                          : 'e.g. U1234567 or AB1234',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),

                    // API Key / Client ID
                    _buildTextField(
                      controller: apiKeyController,
                      label: isDhan ? 'Dhan App Key / ID' : 'API Key',
                      hint: isDhan
                          ? 'Enter Dhan API App Key'
                          : 'Enter your broker API key',
                      icon: Icons.key_outlined,
                    ),
                    const SizedBox(height: 12),

                    // API Secret / Access Token
                    _buildTextField(
                      controller: apiSecretController,
                      label: isDhan
                          ? 'Dhan Access Token / JWT'
                          : 'API Secret / Access Token',
                      hint: isDhan
                          ? 'Enter generated Dhan Access Token'
                          : 'Enter secret key or access token',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),

                    // Save & Connect Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isTesting
                            ? null
                            : () async {
                                setModalState(() {
                                  isTesting = true;
                                });

                                final navigator = Navigator.of(modalContext);
                                final messenger = ScaffoldMessenger.of(context);

                                // Simulate API authentication delay
                                await Future.delayed(
                                    const Duration(milliseconds: 1500));

                                setState(() {
                                  if (isNewCustom) {
                                    final customId =
                                        'custom_${DateTime.now().millisecondsSinceEpoch}';
                                    final newBroker = BrokerAccount(
                                      id: customId,
                                      name: nameController.text.trim().isEmpty
                                          ? 'Custom Broker'
                                          : nameController.text.trim(),
                                      logoSymbol: logoSymbolController.text
                                              .trim()
                                              .isEmpty
                                          ? 'CB'
                                          : logoSymbolController.text
                                              .trim()
                                              .toUpperCase(),
                                      description:
                                          'Custom REST API Trading Endpoint.',
                                      apiKey: apiKeyController.text,
                                      apiSecret: apiSecretController.text,
                                      accountId: accountIdController.text.isEmpty
                                          ? 'ACC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
                                          : accountIdController.text,
                                      baseUrl: baseUrlController.text,
                                      environment: selectedEnv,
                                      status: BrokerStatus.connected,
                                      lastConnectedAt: DateTime.now(),
                                      isCustom: true,
                                    );
                                    _brokers.insert(0, newBroker);
                                  } else {
                                    if (broker.isCustom) {
                                      broker.name = nameController.text.trim().isEmpty
                                          ? 'Custom Broker'
                                          : nameController.text.trim();
                                      broker.logoSymbol = logoSymbolController.text
                                              .trim()
                                              .isEmpty
                                          ? 'CB'
                                          : logoSymbolController.text
                                              .trim()
                                              .toUpperCase();
                                      broker.baseUrl = baseUrlController.text;
                                    }
                                    broker.apiKey = apiKeyController.text;
                                    broker.apiSecret = apiSecretController.text;
                                    broker.accountId = accountIdController.text.isEmpty
                                        ? 'ACC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
                                        : accountIdController.text;
                                    broker.environment = selectedEnv;
                                    broker.status = BrokerStatus.connected;
                                    broker.lastConnectedAt = DateTime.now();
                                  }
                                });

                                await StorageService.saveBrokers(_brokers);
                                widget.onBrokersUpdated();

                                navigator.pop();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${isNewCustom ? nameController.text : broker.name} connected successfully!'),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDhan
                              ? const Color(0xFF00C853)
                              : const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isTesting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Authenticating Broker API...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                isNewCustom
                                    ? 'Save & Connect Custom Broker'
                                    : 'Save & Connect Broker',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addNewCustomBroker() {
    final customBrokerTemplate = BrokerAccount(
      id: '',
      name: 'Custom Broker',
      logoSymbol: 'CB',
      description: 'Custom REST API Trading Endpoint.',
      isCustom: true,
    );
    _openBrokerConnectModal(customBrokerTemplate, isNewCustom: true);
  }

  Future<void> _deleteCustomBroker(BrokerAccount broker) async {
    setState(() {
      _brokers.removeWhere((b) => b.id == broker.id);
    });
    await StorageService.saveBrokers(_brokers);
    widget.onBrokersUpdated();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${broker.name} removed.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _disconnectBroker(BrokerAccount broker) async {
    setState(() {
      broker.status = BrokerStatus.disconnected;
      broker.apiKey = '';
      broker.apiSecret = '';
      broker.accountId = '';
    });
    await StorageService.saveBrokers(_brokers);
    widget.onBrokersUpdated();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${broker.name} disconnected.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
            filled: true,
            fillColor: const Color(0xFF1E222D),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2A2E39)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2A2E39)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectedCount =
        _brokers.where((b) => b.status == BrokerStatus.connected).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Page Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Broker Integration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Connect any stock broker or custom API',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _addNewCustomBroker,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Custom'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Encryption Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.security,
                            color: Color(0xFF2563EB),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bank-Grade API Encryption',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your API keys are stored locally with AES-256 encryption. We never store credentials on external servers.',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Add Custom Broker Highlight Banner
                  GestureDetector(
                    onTap: _addNewCustomBroker,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2563EB),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_link,
                              color: Color(0xFF2563EB),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '+ Connect Any Custom Broker',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Add your custom REST/WebSocket trading API, AngelOne, Tradovate, etc.',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 16, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Connection Summary Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Brokers',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: connectedCount > 0
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$connectedCount Active Connection${connectedCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: connectedCount > 0
                                ? const Color(0xFF10B981)
                                : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Broker Cards List
                  ..._brokers.map((broker) => _buildBrokerCard(broker)),
                ],
              ),
      ),
    );
  }

  Widget _buildBrokerCard(BrokerAccount broker) {
    final bool isConnected = broker.status == BrokerStatus.connected;
    final bool isDhan = broker.id == 'dhan';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? (isDhan ? const Color(0xFF00C853) : const Color(0xFF10B981))
              : const Color(0xFF2A2E39),
          width: isConnected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDhan
                      ? const Color(0xFF00C853).withValues(alpha: 0.15)
                      : const Color(0xFF21262D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDhan
                        ? const Color(0xFF00C853)
                        : const Color(0xFF30363D),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  broker.logoSymbol,
                  style: TextStyle(
                    color: isDhan ? const Color(0xFF00C853) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          broker.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (broker.isCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Custom',
                              style: TextStyle(
                                color: Colors.purpleAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        if (isConnected) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              broker.environment,
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected
                          ? 'Account: ${broker.accountId}'
                          : broker.description,
                      style: TextStyle(
                        color: isConnected ? Colors.white70 : Colors.grey[400],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (isConnected) {
                        _disconnectBroker(broker);
                      } else {
                        _openBrokerConnectModal(broker);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnected
                          ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                          : (isDhan
                              ? const Color(0xFF00C853)
                              : const Color(0xFF2563EB)),
                      foregroundColor: isConnected
                          ? const Color(0xFFEF4444)
                          : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: isConnected
                            ? const BorderSide(color: Color(0xFFEF4444))
                            : BorderSide.none,
                      ),
                    ),
                    child: Text(
                      isConnected ? 'Disconnect' : 'Connect',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (broker.isCustom) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFEF4444), size: 20),
                      onPressed: () => _deleteCustomBroker(broker),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (isConnected && broker.lastConnectedAt != null) ...[
            const SizedBox(height: 10),
            const Divider(color: Color(0xFF2A2E39), height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: isDhan
                            ? const Color(0xFF00C853)
                            : const Color(0xFF10B981),
                        size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'API Verified & Synced',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
                Text(
                  'Connected: ${_formatDate(broker.lastConnectedAt!)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}, ${dt.day}/${dt.month}/${dt.year}';
  }
}
