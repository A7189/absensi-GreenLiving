import 'package:get/get.dart';
import '../services/auth_service.dart';
class RegisterController extends GetxController {
  final AuthService _authService = AuthService(); // Pastikan ini mengarah ke class yang benar

  var isLoading = false.obs;
  var selectedRole = 'security'.obs;
  var isPasswordVisible = false.obs;

  Future<void> registerUser(String name, String email, String password) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Semua kolom wajib diisi");
      return;
    }

    try {
      isLoading.value = true;
      
      // PERBAIKAN DI SINI: panggil register (r kecil)
      await _authService.register(
        email: email,
        password: password,
        name: name,
        role: selectedRole.value,
      );
      
      Get.snackbar("Sukses", "Akun berhasil didaftarkan. Silakan login.");
    } catch (e) {
      Get.snackbar("Gagal Daftar", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}