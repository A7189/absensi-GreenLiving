import 'package:absensi_greenliving/models/leave_models.dart';
import 'package:absensi_greenliving/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminLeaveController extends GetxController {
  final DatabaseService _db = DatabaseService();

  var isLoading = false.obs;
  
  // Kita pisah list-nya biar enak buat TabView
  var pendingList = <LeaveModel>[].obs; // Tab 1: Permintaan Baru
  var historyList = <LeaveModel>[].obs; // Tab 2: Riwayat (Approved/Rejected)

  @override
  void onInit() {
    super.onInit();
    loadAllData(); // Tarik data pas controller dibuat
  }

  // 1. TARIK SEMUA DATA (Pending & History)
  Future<void> loadAllData() async {
    try {
      isLoading.value = true;
      
      // Ambil data secara paralel biar cepet
      var pendingData = await _db.getPendingLeaveRequests();
      var historyData = await _db.getHistoryLeaveRequests();
      
      pendingList.assignAll(pendingData);
      historyList.assignAll(historyData);
      
    } catch (e) {
      print("Error load data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 2. UPDATE STATUS (Approve / Reject)
  void updateStatus(String docId, bool isApproved) async {
    String status = isApproved ? "Approved" : "Rejected";
    
    try {
      // Tampilkan Loading
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      
      // Panggil Service
      await _db.updateLeaveStatus(docId, status);
      
      Get.back(); // Tutup Loading
      
      // Refresh Data Otomatis (biar item pindah dari Pending ke History)
      loadAllData(); 
      
      Get.snackbar(
        isApproved ? "Disetujui" : "Ditolak", 
        "Status perizinan berhasil diperbarui",
        backgroundColor: isApproved ? Colors.green : Colors.red,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.back(); // Tutup Loading kalau error
      Get.snackbar("Error", "Gagal update: $e");
    }
  }
}