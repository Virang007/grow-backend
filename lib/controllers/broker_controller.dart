import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/broker.dart';
import '../services/storage_service.dart';
import '../services/groww_service.dart';

class BrokerController extends GetxController {
  final RxList<BrokerAccount> brokers = <BrokerAccount>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isConnecting = false.obs;
  final RxInt connectedCount = 0.obs;
  final RxString currentAccessToken = ''.obs;

  BrokerAccount? get growwBroker =>
      brokers.firstWhereOrNull((b) => b.id == 'groww');

  @override
  void onInit() {
    super.onInit();
    loadBrokers();
  }

  /// Check if credentials have crossed the 6:00 AM daily reset boundary.
  bool isTokenExpired6AM(DateTime? lastConn) {
    if (lastConn == null) return true;
    final now = DateTime.now();
    // 6 AM boundary for current day
    final today6AM = DateTime(now.year, now.month, now.day, 6, 0, 0);

    if (now.isAfter(today6AM)) {
      // If current time is after 6 AM, connection must be after today's 6 AM
      return lastConn.isBefore(today6AM);
    } else {
      // If current time is before 6 AM, connection must be after yesterday's 6 AM
      final yesterday6AM = today6AM.subtract(const Duration(days: 1));
      return lastConn.isBefore(yesterday6AM);
    }
  }

  Future<void> loadBrokers() async {
    isLoading.value = true;
    final loaded = await StorageService.getBrokers();
    
    // Automatic check for 6 AM daily reset
    for (var broker in loaded) {
      if (broker.id == 'groww' && broker.status == BrokerStatus.connected) {
        if (isTokenExpired6AM(broker.lastConnectedAt)) {
          print('[GROWW RESET] 6 AM Daily Reset detected! Status set to disconnected.');
          broker.status = BrokerStatus.disconnected;
          currentAccessToken.value = '';
        }
      }
    }
    
    brokers.assignAll(loaded);
    _updateConnectedCount();
    isLoading.value = false;
  }

  void _updateConnectedCount() {
    connectedCount.value =
        brokers.where((b) => b.status == BrokerStatus.connected).length;
  }

  /// Connects or Updates Groww Broker using real TOTP token generation call
  Future<bool> connectGroww({
    required String growwTotpToken,
    required String growwTotpSecret,
  }) async {
    if (growwTotpToken.trim().isEmpty || growwTotpSecret.trim().isEmpty) {
      showErrorPopup('Validation Error', 'Please enter both Groww TOTP Token and TOTP Secret.');
      return false;
    }

    isConnecting.value = true;

    try {
      final accessToken = await GrowwBrokerService.generateAccessToken(
        growwTotpToken: growwTotpToken,
        growwTotpSecret: growwTotpSecret,
      );

      if (accessToken != null && accessToken.isNotEmpty) {
        currentAccessToken.value = accessToken;

        var groww = growwBroker;
        if (groww == null) {
          groww = BrokerAccount(
            id: 'groww',
            name: 'Groww Broker',
            logoSymbol: 'GW',
            description: 'Groww Stock Broker API Integration',
            apiKey: growwTotpToken.trim(),
            totpSecret: growwTotpSecret.trim(),
            status: BrokerStatus.connected,
            lastConnectedAt: DateTime.now(),
          );
          brokers.add(groww);
        } else {
          groww.apiKey = growwTotpToken.trim();
          groww.totpSecret = growwTotpSecret.trim();
          groww.status = BrokerStatus.connected;
          groww.lastConnectedAt = DateTime.now();
        }

        brokers.refresh();
        _updateConnectedCount();
        await StorageService.saveBrokers(brokers);

        isConnecting.value = false;

        Get.snackbar(
          'Success',
          'Groww Broker Connected Successfully!',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );

        return true;
      } else {
        throw Exception('Token generation returned an empty result.');
      }
    } catch (e) {
      isConnecting.value = false;
      final errString = e.toString().replaceAll('Exception: ', '');
      showErrorPopup('Groww Connection Error', errString);
      return false;
    }
  }

  /// Disconnects Groww broker and resets tokens
  Future<void> disconnectGroww() async {
    final groww = growwBroker;
    if (groww != null) {
      groww.status = BrokerStatus.disconnected;
      groww.lastConnectedAt = null;
      currentAccessToken.value = '';
      brokers.refresh();
      _updateConnectedCount();
      await StorageService.saveBrokers(brokers);

      Get.snackbar(
        'Disconnected',
        'Groww Broker disconnected successfully.',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Shows proper error pop-up dialog with OK button
  void showErrorPopup(String title, String message) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}

