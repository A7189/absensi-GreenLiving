import 'package:absensi_greenliving/controllers/attedance_controler.dart';
import 'package:absensi_greenliving/controllers/dashboard_controler.dart';
import 'package:absensi_greenliving/controllers/nav_controler.dart';
import 'package:absensi_greenliving/models/shift_models.dart';
import 'package:absensi_greenliving/models/user_models.dart';
import 'package:absensi_greenliving/services/database_service.dart';
import 'package:absensi_greenliving/views/admin/admin_dashboard_page.dart';
import 'package:absensi_greenliving/views/admin/admin_schedule_page.dart'; 
import 'package:absensi_greenliving/views/user/dashboard_page.dart';
import 'package:absensi_greenliving/views/profile/profile_page.dart';
import 'package:absensi_greenliving/widgets/custome_bottom_navbar.dart'; 
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainWrapper extends StatelessWidget {
  final bool isAdmin;

  const MainWrapper({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final navPageController = Get.put(NavigationController());
    final attendanceController = Get.put(AttendanceController());
    
    // Pastikan DashboardController ada biar bisa cek status Lock
    DashboardController? dashboardController;
    if (!isAdmin) {
      dashboardController = Get.put(DashboardController()); 
    }

    final List<Widget> pages = isAdmin
        ? [
            const AdminDashboardPage(), 
            const AdminSchedulePage(),  
            const ProfilePage(),        
          ]
        : [
            const DashboardPage(),      
            const ProfilePage(),        
          ];

    return Scaffold(
      extendBody: true, 
      body: Obx(() {
          int safeIndex = navPageController.selectedIndex.value;
          if (safeIndex >= pages.length) {
            safeIndex = 0;
            Future.microtask(() => navPageController.selectedIndex.value = 0);
          }
          return IndexedStack(
            index: safeIndex,
            children: pages,
          );
      }),
      
      // Kirim DashboardController ke FAB biar sinkron
      floatingActionButton: isAdmin ? null : _buildFabAbsen(attendanceController, dashboardController),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      bottomNavigationBar: CustomBottomNavBar(isAdmin: isAdmin),
    );
  }

  // 🔥 UPDATE FAB: KONEK KE DASHBOARD CONTROLLER BUAT CEK LOCK
  Widget _buildFabAbsen(AttendanceController controller, DashboardController? dashController) {
    return Obx(() {
      String status = controller.currentStatus.value;
      bool loading = controller.isLoading.value;
      
      // 🔥 LOGIC LOCK SYSTEM DARI DASHBOARD
      // Default false kalau controller belum siap
      bool isSystemLocked = dashController?.isTimeLocked.value ?? false; 
      
      // Ambil judul shift buat cek "Force Lock" (Menunggu/Libur)
      String title = dashController?.shiftStatusTitle.value ?? "";
      bool isForceLocked = title.contains("Menunggu") || title.contains("Libur");
      
      // Kunci hanya berlaku pas Masuk (Pending). Kalau Pulang (CheckIn), bebas.
      bool isLocked = (status == 'pending') ? (isSystemLocked || isForceLocked) : false;

      Color fabColor;
      IconData icon;
      bool isDisabled = false;

      if (status == 'pending') {
        if (isLocked) {
          // --- TERKUNCI (ABU-ABU) ---
          fabColor = Colors.grey.shade400; 
          icon = Icons.lock_clock; // Icon Gembok
          isDisabled = true;       // Matikan fungsi
        } else {
          // --- TERBUKA (IJO) ---
          fabColor = const Color(0xFF1B5E20); 
          icon = Icons.fingerprint_rounded;
        }
      } else if (status == 'checkIn') {
        fabColor = const Color(0xFFE65100); 
        icon = Icons.logout_rounded;
      } else {
        // --- SELESAI HARI INI ---
        fabColor = Colors.grey; 
        icon = Icons.check_circle_outline;
        isDisabled = true;
      }

      return SizedBox(
        width: 75,
        height: 75,
        child: FloatingActionButton(
          // 🔥 Matikan fungsi kalau locked
          onPressed: (loading || isDisabled)
              ? null
              : () {
                  // Double check biar aman
                  if (isLocked) {
                    Get.snackbar("Eits!", "Belum waktunya absen bro.");
                    return;
                  }
                  _handleAttendance(controller);
                },
          backgroundColor: fabColor,
          shape: const CircleBorder(),
          elevation: isDisabled ? 0 : 6, // Ilangin shadow kalau mati
          child: loading
              ? const CircularProgressIndicator(color: Colors.white)
              : Icon(icon, size: 36, color: Colors.white),
        ),
      );
    });
  }

  void _handleAttendance(AttendanceController controller) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      
      final userModel = UserModel(
        uid: currentUser.uid,
        name: currentUser.displayName ?? 'Security User',
        email: currentUser.email ?? '',
        role: 'security',
        joinDate: DateTime.now(),
        officeLat: controller.officeLat.value,
        officeLng: controller.officeLng.value,
      );
      
      final db = DatabaseService();
      ShiftModel? todayShift = await db.getTodayShift(currentUser.uid);

      await controller.submitAttendance(userModel, todayShift);
      
      // 🔥 REFRESH DASHBOARD SETELAH ABSEN BIAR UPDATE VISUAL
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshData();
      }
    }
  }
}