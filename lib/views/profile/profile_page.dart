import 'package:absensi_greenliving/controllers/profile_controler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final controller = Get.put(ProfileController());

    const Color forestGreen = Color(0xFF1B5E20);
    const Color backgroundColor = Color(0xFFF2F7F2);

    return Scaffold(
      backgroundColor: backgroundColor,
      // Stack biar Header hijaunya bisa ada di belakang foto profile
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none, // Biar avatar yang nonjol ga kepotong
              alignment: Alignment.center,
              children: [
                // 1. HEADER HIJAU
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: forestGreen,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60.0),
                    child: Text(
                      "My Profile",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // 2. FOTO PROFIL (Ngambang)
                Positioned(
                  bottom: -50, // Geser ke bawah header
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: backgroundColor, width: 4), // Border putih krem
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage('assets/Logo.png'), // Ganti foto user nanti
                      // child: Icon(Icons.person, size: 50, color: Colors.grey), // Pake ini kalo blm ada gambar
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60), // Jarak kompensasi buat foto yang nonjol

            // 3. NAMA & ROLE
            Obx(() => Column(
              children: [
                Text(
                  controller.name.value,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                Text(
                  "${controller.role.value} • ${controller.email.value}",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            )),

            const SizedBox(height: 30),

            // 4. MENU OPTIONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildProfileMenu(
                    icon: Icons.person_outline,
                    title: "Edit Profile",
                    onTap: () {
                      // 🔥 PANGGIL FUNGSI EDIT DARI CONTROLLER
                      controller.showEditProfileDialog();
                    },
                  ),
                  _buildProfileMenu(
                    icon: Icons.lock_outline,
                    title: "Change Password",
                    onTap: () {
                      // 🔥 PANGGIL FUNGSI GANTI PASS DARI CONTROLLER
                      controller.showChangePasswordDialog();
                    },
                  ),
                  _buildProfileMenu(
                    icon: Icons.info_outline,
                    title: "About Apps",
                    onTap: () {
                      _showAboutAppsDialog();
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // LOGOUT BUTTON
                  _buildProfileMenu(
                    icon: Icons.logout,
                    title: "Log Out",
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: () => controller.logout(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- DIALOG ABOUT APPS ---
  void _showAboutAppsDialog() {
    Get.defaultDialog(
      title: "About Application",
      titleStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      content: Column(
        children: [
          const Icon(Icons.spa, size: 50, color: Color(0xFF1B5E20)),
          const SizedBox(height: 10),
          Text("Green Living Attendance", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          Text("Version 1.0.0", style: GoogleFonts.poppins(color: Colors.grey)),
          const SizedBox(height: 20),
          Text(
            "Aplikasi absensi dan manajemen jadwal satpam Green Living Residence. Dibuat untuk mempermudah monitoring kinerja.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          const SizedBox(height: 20),
          Text("Made by : Pragaza", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20))),
        ],
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
        onPressed: () => Get.back(), 
        child: const Text("Tutup", style: TextStyle(color: Colors.white))
      ),
    );
  }

  // Widget kecil buat bikin menu biar kodingan ga panjang
  Widget _buildProfileMenu({
    required IconData icon,
    required String title,
    Color textColor = const Color(0xFF333333),
    Color iconColor = const Color(0xFF1B5E20),
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}