import 'package:absensi_greenliving/services/database_service.dart';
import 'package:get/get.dart';

class AdminDashboardController extends GetxController {
  final DatabaseService _db = DatabaseService();

  var isLoading = true.obs;
  
  // Data Live Monitoring
  var activeGuards = 0.obs;
  var totalGuards = 0.obs;

  // Data Perizinan
  var pendingCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  void loadDashboardData() async {
    try {
      // Jalankan barengan biar cepet (Parallel)
      var statsFuture = _db.getLiveMonitoringStats();
      var pendingFuture = _db.getPendingLeaveCount();

      var results = await Future.wait([statsFuture, pendingFuture]);

      // Parsing Hasil Monitoring
      var monitoringData = results[0] as Map<String, int>;
      activeGuards.value = monitoringData['active'] ?? 0;
      totalGuards.value = monitoringData['total'] ?? 0;

      // Parsing Hasil Pending
      pendingCount.value = results[1] as int;

    } catch (e) {
      print("Error dashboard: $e");
    } finally {
      isLoading.value = false;
    }
  }

 
}