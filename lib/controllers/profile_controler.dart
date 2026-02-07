import 'package:absensi_greenliving/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _box = GetStorage();

  // Observable Data
  var name = 'Loading...'.obs;
  var email = ''.obs;
  var role = ''.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  // --- 1. LOAD DATA USER ---
  void loadProfile() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      email.value = currentUser.email ?? '';
      try {
        DocumentSnapshot doc = await _db.collection('users').doc(currentUser.uid).get();
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          name.value = data['name'] ?? 'User';
          role.value = data['role'] ?? 'Employee';
        }
      } catch (e) {
        print("Error load profile: $e");
      }
    }
  }

  // --- 2. EDIT PROFILE (GANTI NAMA) ---
  void showEditProfileDialog() {
    TextEditingController nameC = TextEditingController(text: name.value);
    
    Get.defaultDialog(
      title: "Edit Profile",
      content: Column(
        children: [
          TextField(
            controller: nameC,
            decoration: const InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          const Text("Email & Role tidak dapat diubah.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
        onPressed: () async {
          if (nameC.text.isNotEmpty) {
            Get.back(); // Tutup Dialog
            isLoading.value = true;
            try {
              String uid = _auth.currentUser!.uid;
              await _db.collection('users').doc(uid).update({'name': nameC.text});
              name.value = nameC.text; // Update UI langsung
              Get.snackbar("Sukses", "Profil berhasil diperbarui!");
            } catch (e) {
              Get.snackbar("Error", "Gagal update: $e");
            } finally {
              isLoading.value = false;
            }
          }
        },
        child: const Text("Simpan", style: TextStyle(color: Colors.white)),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  // --- 3. CHANGE PASSWORD (DENGAN RE-AUTH) ---
  void showChangePasswordDialog() {
    TextEditingController oldPassC = TextEditingController();
    TextEditingController newPassC = TextEditingController();
    
    Get.defaultDialog(
      title: "Ganti Password",
      content: Column(
        children: [
          TextField(
            controller: oldPassC,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Password Lama", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: newPassC,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Password Baru", border: OutlineInputBorder()),
          ),
        ],
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
        onPressed: () async {
          if (oldPassC.text.isEmpty || newPassC.text.isEmpty) {
            Get.snackbar("Error", "Semua kolom harus diisi");
            return;
          }
          Get.back();
          _changePasswordProcess(oldPassC.text, newPassC.text);
        },
        child: const Text("Ganti", style: TextStyle(color: Colors.white)),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  void _changePasswordProcess(String oldPass, String newPass) async {
    isLoading.value = true;
    try {
      User? user = _auth.currentUser;
      String email = user!.email!;

      // 1. Re-Authenticate (Pastikan itu beneran dia)
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: oldPass);
      await user.reauthenticateWithCredential(credential);

      // 2. Update Password
      await user.updatePassword(newPass);

      Get.snackbar("Sukses", "Password berhasil diubah! Silakan login ulang.");
      logout(); // Logout paksa biar login pake password baru
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Gagal", e.message ?? "Terjadi kesalahan");
    } catch (e) {
      Get.snackbar("Error", "$e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- 4. LOGOUT ---
  void logout() async {
    Get.defaultDialog(
      title: "Logout",
      middleText: "Yakin ingin keluar akun?",
      textConfirm: "Ya, Keluar",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red, // Merah biar warning
      onConfirm: () async {
        await _auth.signOut();
        _box.remove('remember_me'); 
        Get.offAllNamed(Routes.LOGIN);
      },
    );
  }
}