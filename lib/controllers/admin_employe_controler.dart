import 'package:absensi_greenliving/models/user_models.dart';
import 'package:absensi_greenliving/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminEmployeeController extends GetxController {
  final DatabaseService _service = DatabaseService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var employees = <UserModel>[].obs;

  // 🔥 VARIABLE SORTING
  var currentSortOption = 'senior'.obs; // Default: Paling Senior di atas

  @override
  void onInit() {
    super.onInit();
    loadEmployees();
  }

  Future<void> loadEmployees() async {
    try {
      isLoading.value = true;
      List<UserModel> result = await _service.getAllEmployees();
      employees.assignAll(result);
      
      // 🔥 LANGSUNG JALANKAN SORTING SETELAH LOAD
      applySort(currentSortOption.value);
      
    } catch (e) {
      print("Error load employees: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 🔥 FUNGSI FILTER/SORTING SAKTI
  void applySort(String option) {
    currentSortOption.value = option;
    
    switch (option) {
      case 'az': // Nama A-Z
        employees.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'za': // Nama Z-A
        employees.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'senior': // Lama -> Baru (Join Date Ascending)
        employees.sort((a, b) => a.joinDate.compareTo(b.joinDate));
        break;
      case 'junior': // Baru -> Lama (Join Date Descending)
        employees.sort((a, b) => b.joinDate.compareTo(a.joinDate));
        break;
    }
    employees.refresh(); // Update UI paksa
  }

  // ... (Fungsi editEmployee dan deleteEmployee TETAP SAMA kayak sebelumnya, jangan dihapus)
   void editEmployee(String uid, String newName, String newRole) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      await _db.collection('users').doc(uid).update({
        'name': newName,
        'role': newRole,
      });
      Get.back(); Get.back(); 
      loadEmployees(); 
      Get.snackbar("Sukses", "Data diperbarui", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "$e");
    }
  }

  void deleteEmployee(String uid) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      await _db.collection('users').doc(uid).delete();
      Get.back(); Get.back(); 
      loadEmployees(); 
      Get.snackbar("Dihapus", "Pegawai dihapus", backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "$e");
    }
  }
}