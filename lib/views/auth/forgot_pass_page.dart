import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller lokal biar praktis
    final emailController = TextEditingController();
    final isLoading = false.obs;

    // 🔥 LOGIC KIRIM EMAIL RESET
    Future<void> sendResetEmail() async {
      if (emailController.text.trim().isEmpty) {
        Get.snackbar("Error", "Email tidak boleh kosong", 
          backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      if (!GetUtils.isEmail(emailController.text.trim())) {
        Get.snackbar("Error", "Format email tidak valid", 
          backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      try {
        isLoading.value = true;
        
        // Fungsi Ajaib Firebase
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: emailController.text.trim()
        );

        // Sukses
        Get.snackbar("Berhasil", "Link reset password telah dikirim ke email Anda. Cek Folder Spam jika tidak ada.", 
          backgroundColor: const Color(0xFF1B5E20), colorText: Colors.white, duration: const Duration(seconds: 4));
        
        // Balik ke login setelah dikit
        await Future.delayed(const Duration(seconds: 2));
        Get.back();

      } on FirebaseAuthException catch (e) {
        String message = "Terjadi kesalahan.";
        if (e.code == 'user-not-found') {
          message = "Email tidak terdaftar.";
        } else if (e.code == 'invalid-email') {
          message = "Email tidak valid.";
        }
        Get.snackbar("Gagal", message, backgroundColor: Colors.red, colorText: Colors.white);
      } catch (e) {
        Get.snackbar("Error", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Lupa Password?",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Jangan panik. Masukkan email yang terdaftar, kami akan mengirimkan link untuk mereset password Anda.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),

            // INPUT EMAIL
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1B5E20)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // TOMBOL KIRIM
            SizedBox(
              width: double.infinity,
              height: 55,
              child: Obx(() => ElevatedButton(
                onPressed: isLoading.value ? null : sendResetEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "Kirim Link Reset",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                      ),
                    ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}