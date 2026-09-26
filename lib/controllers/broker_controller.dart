import 'package:get/get.dart';
import '../models/broker.dart';
import '../services/storage_service.dart';
import '../services/megabull_api_service.dart';

class BrokerController extends GetxController {
  final RxList<BrokerAccount> brokers = <BrokerAccount>[].obs;
  final RxBool isLoading = true.obs;
  final RxInt connectedCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadBrokers();
  }

  Future<void> loadBrokers() async {
    isLoading.value = true;
    final loaded = await StorageService.getBrokers();
    brokers.assignAll(loaded);
    _updateConnectedCount();

    final megabull = brokers.firstWhereOrNull((b) => b.id == 'megabull');
    if (megabull != null && megabull.status == BrokerStatus.connected) {
      MegaBullApiService.apiKey = megabull.apiKey.isNotEmpty
          ? megabull.apiKey
          : 'd35a226d-5b3a-44d7-a954-2db87bd069a7';
      MegaBullApiService.baseUrl = megabull.baseUrl.isNotEmpty
          ? megabull.baseUrl
          : 'https://api.megabull.in';
    }

    isLoading.value = false;
  }

  void _updateConnectedCount() {
    connectedCount.value =
        brokers.where((b) => b.status == BrokerStatus.connected).length;
  }

  Future<void> connectBroker(BrokerAccount broker) async {
    broker.status = BrokerStatus.connected;
    broker.lastConnectedAt = DateTime.now();
    brokers.refresh();
    _updateConnectedCount();
    await StorageService.saveBrokers(brokers);

    if (broker.id == 'megabull') {
      MegaBullApiService.apiKey = broker.apiKey;
      MegaBullApiService.baseUrl = broker.baseUrl.isNotEmpty
          ? broker.baseUrl
          : 'https://api.megabull.in';
    }
  }

  Future<void> disconnectBroker(BrokerAccount broker) async {
    broker.status = BrokerStatus.disconnected;
    broker.apiKey = '';
    broker.apiSecret = '';
    broker.accountId = '';
    brokers.refresh();
    _updateConnectedCount();
    await StorageService.saveBrokers(brokers);
  }

  Future<void> addCustomBroker(BrokerAccount customBroker) async {
    brokers.insert(0, customBroker);
    _updateConnectedCount();
    await StorageService.saveBrokers(brokers);
  }

  Future<void> removeCustomBroker(BrokerAccount customBroker) async {
    brokers.removeWhere((b) => b.id == customBroker.id);
    _updateConnectedCount();
    await StorageService.saveBrokers(brokers);
  }
}
