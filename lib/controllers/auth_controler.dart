import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import '../routes/app_routes.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _box = GetStorage();

  late TextEditingController emailC;
  late TextEditingController passwordC;

  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var rememberMe = false.obs; 

  @override
  void onInit() {
    super.onInit();
    emailC = TextEditingController();
    passwordC = TextEditingController();
    rememberMe.value = _box.read('remember_me') ?? false;
  }

  // 🔥 1. Cek Status Pas App Baru Nyala
  @override
  void onReady() {
    super.onReady();
    _checkAutoLogin();
  }

  @override
  void onClose() {
    emailC.dispose();
    passwordC.dispose();
    super.onClose();
  }

  // 🔥 2. LOGIC AUTO LOGIN (FIXED: HP BARU GAK STUCK LAGI)
  void _checkAutoLogin() async {
    // Delay buat nampilin Splash Screen (Logo) sebentar
    await Future.delayed(const Duration(seconds: 2));

    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      // === KONDISI 1: ADA USER NYANGKUT (HP LAMA) ===
      try {
        DocumentSnapshot userDoc = await _db.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;
          String role = data['role'] ?? 'user';

          if (role == 'admin') {
            Get.offAllNamed(Routes.MAIN, arguments: true); 
          } else {
            Get.offAllNamed(Routes.MAIN, arguments: false);
          }
        } else {
          await _auth.signOut();
          Get.offAllNamed(Routes.LOGIN); // Data DB ilang -> Tendang ke Login
        }
      } catch (e) {
        // Error koneksi dll -> Tendang ke Login biar aman
        print("Auto login error: $e");
        Get.offAllNamed(Routes.LOGIN); 
      }
    } else {
      // === KONDISI 2: HP BARU / BELUM LOGIN ===
      // 🔥 FIX: Karena app mulai dari SPLASH, kita WAJIB arahkan ke LOGIN
      print("User null, arahkan ke Login Page...");
      Get.offAllNamed(Routes.LOGIN); 
    }
  }

  // --- 3. FUNGSI LOGIN MANUAL ---
  Future<void> login() async {
    String email = emailC.text.trim();
    String password = passwordC.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Email dan password wajib diisi");
      return;
    }

    try {
      isLoading.value = true;
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        _box.write('remember_me', rememberMe.value);

        DocumentSnapshot userDoc = await _db
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;
          String role = data['role'] ?? 'User'; 

          // CEK ROLE
          if (role == 'admin') {
            Get.offAllNamed(Routes.MAIN, arguments: true); 
          } else {
            Get.offAllNamed(Routes.MAIN, arguments: false); 
          }

        } else {
          await _auth.signOut();
          Get.snackbar("Error", "Akun ditemukan, tapi data user tidak ada");
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = "";
      switch (e.code) {
        case 'user-not-found': msg = "Email tidak terdaftar"; break;
        case 'wrong-password': msg = "Password salah"; break;
        case 'invalid-email': msg = "Format email salah"; break;
        case 'network-request-failed': msg = "Periksa koneksi internet Anda"; break;
        default: msg = "Gagal masuk: ${e.message}";
      }
      Get.snackbar("Login Gagal", msg);
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan sistem: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleRememberMe() {
    rememberMe.value = !rememberMe.value;
  }

  void logout() async {
    try {
      await _auth.signOut();       
      Get.offAllNamed(Routes.LOGIN); 
    } catch (e) {
      Get.snackbar("Error", "Gagal logout: $e");
    }
  }
}