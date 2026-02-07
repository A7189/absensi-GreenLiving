import 'package:absensi_greenliving/models/user_models.dart';
import 'package:absensi_greenliving/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Perlu import ini buat akses Firestore langsung
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminEmployeeController extends GetxController {
  final DatabaseService _service = DatabaseService();
  
  // 🔥 Akses DB Langsung (Karena di Service belum ada fungsi update/delete)
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var employees = <UserModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadEmployees();
  }

  // 1. AMBIL DATA (Pake Service karena fungsinya ada)
  Future<void> loadEmployees() async {
    try {
      isLoading.value = true;
      // Panggil fungsi getAllEmployees dari DatabaseService
      List<UserModel> result = await _service.getAllEmployees();
      employees.assignAll(result);
    } catch (e) {
      print("Error load employees: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 2. EDIT DATA (Direct Firestore)
  void editEmployee(String uid, String newName, String newRole) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      
      // 🔥 Update langsung ke collection 'users'
      await _db.collection('users').doc(uid).update({
        'name': newName,
        'role': newRole,
      });
      
      Get.back(); // Tutup Loading
      Get.back(); // Tutup Dialog Edit
      
      loadEmployees(); // Refresh List
      
      Get.snackbar("Sukses", "Data berhasil diperbarui", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Gagal update: $e");
    }
  }

  // 3. HAPUS DATA (Direct Firestore)
  void deleteEmployee(String uid) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

      // 🔥 Hapus langsung dari collection 'users'
      await _db.collection('users').doc(uid).delete();
      
      Get.back(); // Tutup Loading
      Get.back(); // Tutup Dialog Confirm
      
      loadEmployees(); // Refresh List
      
      Get.snackbar("Dihapus", "Pegawai dihapus dari database", backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Gagal hapus: $e");
    }
  }
}