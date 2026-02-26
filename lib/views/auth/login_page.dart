import 'package:absensi_greenliving/controllers/auth_controler.dart';
import 'package:absensi_greenliving/views/auth/forgot_pass_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final controller = Get.put(AuthController());

    // ❌ JANGAN BIKIN CONTROLLER DI SINI (Gua Hapus)
    // final emailController = TextEditingController();
    // final passwordController = TextEditingController();

    const Color darkBlue = Color(0xFF2A3979);
    const Color lightGrayBorder = Color(0xFFE0E0E0);
    const Color backgroundColor = Color(0xFFFDFBF6);

    InputDecoration customInputDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: lightGrayBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: lightGrayBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: darkBlue, width: 1.5)),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: Image.asset(
                    'assets/Logo.png',
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                  ),
                ),
                Text(
                  'Welcome',
                  style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                ),
                const SizedBox(height: 40),
                
                // INPUT EMAIL (Pake controller.emailC)
                TextField(
                  controller: controller.emailC, // ✅ PAKE INI
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: customInputDecoration('Email address'),
                ),
                
                const SizedBox(height: 20),
                
                // INPUT PASSWORD (Pake controller.passwordC)
                Obx(() => TextField(
                  controller: controller.passwordC, // ✅ PAKE INI
                  obscureText: !controller.isPasswordVisible.value,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: customInputDecoration('Password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(controller.isPasswordVisible.value ? Icons.visibility : Icons.visibility_off, color: Colors.grey[400]),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                  ),
                )),
                
                const SizedBox(height: 15),
                
                // CHECKBOX REMEMBER ME
                Row(
                  children: [
                    Obx(() => SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: controller.rememberMe.value,
                        activeColor: const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        onChanged: (val) => controller.toggleRememberMe(),
                      ),
                    )),
                    const SizedBox(width: 8),
                    Text(
                      "Remember me",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const Spacer(),
                   TextButton(
  // 🔥 Ganti ini: Dari Snackbar jadi Navigasi ke Halaman Lupa Password
  onPressed: () => Get.to(() => const ForgotPasswordPage()), 
  
  child: Text(
    'Forget password?',
    style: GoogleFonts.poppins(
      color: Colors.grey[600], 
      fontSize: 14, 
      fontWeight: FontWeight.w500
    ),
  ),
),
                  ],
                ),

                const SizedBox(height: 25),
                
                // TOMBOL LOGIN
                Obx(() => SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.login(), // ✅ GAK PERLU KIRIM PARAMETER LAGI
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 115, 23),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text('Log in', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                )),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}