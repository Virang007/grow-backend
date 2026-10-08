import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/broker_controller.dart';
import '../models/broker.dart';

class BrokerSettingsPage extends StatelessWidget {
  final VoidCallback onBrokersUpdated;

  const BrokerSettingsPage({
    super.key,
    required this.onBrokersUpdated,
  });

  void _openBrokerConnectModal(BuildContext context, BrokerAccount broker) {
    final controller = Get.find<BrokerController>();
    final String savedToken = broker.apiKey;
    final String savedSecret = broker.totpSecret;
    final bool hasSavedCredentials = savedToken.isNotEmpty || savedSecret.isNotEmpty;

    // Default to 'old' mode if saved credentials exist, else 'new'
    String selectedMode = hasSavedCredentials ? 'old' : 'new';

    final totpTokenController = TextEditingController(
      text: selectedMode == 'old' ? savedToken : '',
    );
    final totpSecretController = TextEditingController(
      text: selectedMode == 'old' ? savedSecret : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setStateModal) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom +
                    MediaQuery.of(modalContext).padding.bottom +
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

                    // Header Title
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D09C).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF00D09C),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'GW',
                            style: TextStyle(
                              color: Color(0xFF00D09C),
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
                                broker.status == BrokerStatus.connected
                                    ? 'Update Credentials'
                                    : 'Connect Groww Broker',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Enter or use saved Groww TOTP credentials',
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
                    const SizedBox(height: 18),

                    // ── OLD / NEW SWITCH BUTTON TOGGLE ───────────────────────
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E222D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2E39)),
                      ),
                      child: Row(
                        children: [
                          // OLD / SAVED CREDENTIALS SWITCH
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setStateModal(() {
                                  selectedMode = 'old';
                                  totpTokenController.text = savedToken;
                                  totpSecretController.text = savedSecret;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedMode == 'old'
                                      ? const Color(0xFF00D09C).withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: selectedMode == 'old'
                                      ? Border.all(color: const Color(0xFF00D09C))
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bookmark_added_outlined,
                                      size: 16,
                                      color: selectedMode == 'old'
                                          ? const Color(0xFF00D09C)
                                          : Colors.grey[400],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Old / Saved',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: selectedMode == 'old'
                                            ? const Color(0xFF00D09C)
                                            : Colors.grey[400],
                                      ),
                                    ),
                                    if (hasSavedCredentials) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF00D09C),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // NEW CREDENTIALS SWITCH
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setStateModal(() {
                                  selectedMode = 'new';
                                  totpTokenController.clear();
                                  totpSecretController.clear();
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedMode == 'new'
                                      ? const Color(0xFF2563EB).withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: selectedMode == 'new'
                                      ? Border.all(color: const Color(0xFF2563EB))
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      size: 16,
                                      color: selectedMode == 'new'
                                          ? const Color(0xFF3B82F6)
                                          : Colors.grey[400],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'New',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: selectedMode == 'new'
                                            ? const Color(0xFF3B82F6)
                                            : Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Information banner for Old tab
                    if (selectedMode == 'old') ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: hasSavedCredentials
                              ? const Color(0xFF00D09C).withValues(alpha: 0.1)
                              : Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasSavedCredentials
                                ? const Color(0xFF00D09C).withValues(alpha: 0.3)
                                : Colors.amber.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasSavedCredentials ? Icons.check_circle_outline : Icons.info_outline,
                              color: hasSavedCredentials ? const Color(0xFF00D09C) : Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hasSavedCredentials
                                    ? 'Saved credentials auto-filled. Click "Save & Connect Broker" to proceed.'
                                    : 'No saved credentials found. Switch to "New" to enter credentials.',
                                style: TextStyle(
                                  color: hasSavedCredentials ? const Color(0xFF00D09C) : Colors.amber,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // FIELD 1: Groww TOTP Token
                    _buildTextField(
                      controller: totpTokenController,
                      label: 'Groww TOTP Token (growwTotpToken) *',
                      hint: 'Enter your Groww TOTP Token',
                      icon: Icons.key_outlined,
                    ),
                    const SizedBox(height: 14),

                    // FIELD 2: Groww TOTP Secret
                    _buildTextField(
                      controller: totpSecretController,
                      label: 'Groww TOTP Secret (growwTotpSecret) *',
                      hint: 'Enter 32-character Base32 TOTP Secret',
                      icon: Icons.security_outlined,
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),

                    // Connect / Save Button with Obx for progress state
                    Obx(() {
                      final isConnecting = controller.isConnecting.value;

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isConnecting
                              ? null
                              : () async {
                                  final token = totpTokenController.text.trim();
                                  final secret = totpSecretController.text.trim();

                                  final success = await controller.connectGroww(
                                    growwTotpToken: token,
                                    growwTotpSecret: secret,
                                  );

                                  if (success && modalContext.mounted) {
                                    onBrokersUpdated();
                                    Navigator.pop(modalContext);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D09C),
                            disabledBackgroundColor:
                                const Color(0xFF00D09C).withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isConnecting
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
                                      'Generating Access Token...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  broker.status == BrokerStatus.connected
                                      ? 'Save & Update Credentials'
                                      : 'Save & Connect Broker',
                                ),
                        ),
                      );
                    }),
                    // Disconnect option inside modal if connected
                    if (broker.status == BrokerStatus.connected) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            totpTokenController.clear();
                            totpSecretController.clear();
                            await controller.disconnectGroww();
                            onBrokersUpdated();
                            if (modalContext.mounted) {
                              Navigator.pop(modalContext);
                            }
                          },
                          icon: const Icon(Icons.link_off, size: 16, color: Color(0xFFEF4444)),
                          label: const Text(
                            'Disconnect Broker',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
            prefixIcon: Icon(icon, color: const Color(0xFF00D09C), size: 20),
            filled: true,
            fillColor: const Color(0xFF1E222D),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
              borderSide: const BorderSide(color: Color(0xFF00D09C)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BrokerController());

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D09C)),
            );
          }

          final brokers = controller.brokers;
          final connectedCount = controller.connectedCount.value;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
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
                    'Connect your Groww Stock Broker Account',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Encryption Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D09C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF00D09C).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D09C).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.security,
                        color: Color(0xFF00D09C),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily 6 AM Token Management',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'All API keys reset daily at 6 AM. Saved Groww TOTP credentials are used to auto-generate fresh access tokens.',
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

              // Summary Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Broker',
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
                      connectedCount > 0
                          ? '1 Connected'
                          : '0 Connections',
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

              // Groww Broker Card
              ...brokers.map((broker) => _buildBrokerCard(context, controller, broker)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBrokerCard(
      BuildContext context, BrokerController controller, BrokerAccount broker) {
    final bool isConnected = broker.status == BrokerStatus.connected;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? const Color(0xFF10B981)
              : const Color(0xFF2A2E39),
          width: isConnected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D09C).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00D09C)),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'GW',
                  style: TextStyle(
                    color: Color(0xFF00D09C),
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
                        const Flexible(
                          child: Text(
                            'Groww Broker',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isConnected
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isConnected ? '● Connected' : '○ Disconnected',
                            style: TextStyle(
                              color: isConnected
                                  ? const Color(0xFF10B981)
                                  : Colors.grey[400],
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Groww Stock Broker API Integration',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Connected Status Info ──────────────────────────────────
          if (isConnected && broker.lastConnectedAt != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 6),
                Text(
                  'Access Token Active | Resets daily 6 AM',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Connected: ${_formatDate(broker.lastConnectedAt!)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2A2E39), height: 1),
          const SizedBox(height: 10),

          // ── Action Buttons ────────────────────────────────────────
          Row(
            children: [
              // Connect OR Update button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openBrokerConnectModal(context, broker),
                  icon: Icon(
                    isConnected ? Icons.edit_outlined : Icons.link,
                    size: 16,
                  ),
                  label: Text(
                    isConnected ? 'Update Credentials' : 'Connect Broker',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConnected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF00D09C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              // Disconnect button (only when connected)
              if (isConnected) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await controller.disconnectGroww();
                    onBrokersUpdated();
                  },
                  icon: const Icon(Icons.link_off, size: 16),
                  label: const Text(
                    'Disconnect',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFEF4444).withValues(alpha: 0.15),
                    foregroundColor: const Color(0xFFEF4444),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side:
                          const BorderSide(color: Color(0xFFEF4444), width: 1),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}, ${dt.day}/${dt.month}/${dt.year}';
  }
}


