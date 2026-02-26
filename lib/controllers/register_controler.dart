import 'package:absensi_greenliving/models/user_models.dart'; 
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';

class RegisterController extends GetxController {
  final AuthService _authService = AuthService(); 

  var isLoading = false.obs;
  
  var selectedRole = UserModel.roleSecurity.obs; 
  
  var isPasswordVisible = false.obs;

  var joinDate = DateTime.now().obs;

  Future<void> pickJoinDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: joinDate.value,
      firstDate: DateTime(2000), 
      lastDate: DateTime.now(),  
    );
    if (picked != null && picked != joinDate.value) {
      joinDate.value = picked;
    }
  }

  Future<void> registerUser(String name, String email, String password) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Semua kolom wajib diisi", 
        backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      return;
    }

    try {
      isLoading.value = true;
      
      await _authService.register(
        email: email,
        password: password,
        name: name,
        role: selectedRole.value, 
        joinDate: joinDate.value, 
      );
      
      Get.back();
      Get.snackbar("Sukses", "Akun berhasil dibuat dengan role: ${selectedRole.value}");
      
    } catch (e) {
      Get.snackbar("Gagal Daftar", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}