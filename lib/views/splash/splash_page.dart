import 'package:absensi_greenliving/controllers/auth_controler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  // --- 🛠️ SETTINGAN TAMPILAN ---
  final double imageSize = 130.0;     // Ukuran Logo
  final double circlePadding = 25.0;  // Jarak putih di sekitar logo
  final double shadowBlur = 20.0;     // Blur bayangan
  // -----------------------------

  @override
  Widget build(BuildContext context) {
    Get.put(AuthController()); 

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20), // IJO FOREST GREEN
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. LOGO DALAM LINGKARAN PUTIH
            _buildLogoCircle(),
            
            const SizedBox(height: 30),
            
            // 2. TEKS JUDUL
            Text(
              "Green Living\nAttendance",
              textAlign: TextAlign.center,
              style: GoogleFonts.dancingScript(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 50),

            // 3. LOADING (Putih)
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }

  // Widget Logo dipisah biar rapi
  Widget _buildLogoCircle() {
    return Container(
      padding: EdgeInsets.all(circlePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: shadowBlur,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Image.asset(
        'assets/Logo.png',
        width: imageSize, 
        height: imageSize,
        fit: BoxFit.contain,
        // Error handler kalau logo gak ketemu, ganti jadi Icon Security
        errorBuilder: (context, error, stackTrace) => 
            Icon(Icons.security, size: imageSize, color: const Color(0xFF1B5E20)),
      ),
    );
  }
}