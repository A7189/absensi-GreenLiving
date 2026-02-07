import 'package:absensi_greenliving/controllers/attedance_controler.dart';
import 'package:absensi_greenliving/controllers/dashboard_controler.dart';
import 'package:absensi_greenliving/controllers/nav_controler.dart';
import 'package:absensi_greenliving/models/shift_models.dart'; // 🔥 IMPORT MODEL SHIFT
import 'package:absensi_greenliving/models/user_models.dart';
import 'package:absensi_greenliving/services/database_service.dart'; // 🔥 IMPORT DB SERVICE
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
    
    if (!isAdmin) {
      Get.put(DashboardController()); 
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
      
      floatingActionButton: isAdmin ? null : _buildFabAbsen(attendanceController),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      bottomNavigationBar: CustomBottomNavBar(isAdmin: isAdmin),
    );
  }

  Widget _buildFabAbsen(AttendanceController controller) {
    return Obx(() {
      String status = controller.currentStatus.value;
      bool loading = controller.isLoading.value;
      
      Color fabColor;
      IconData icon;
      bool isDisabled = false;

      if (status == 'pending') {
        fabColor = const Color(0xFF1B5E20); 
        icon = Icons.fingerprint_rounded;
      } else if (status == 'checkIn') {
        fabColor = const Color(0xFFE65100); 
        icon = Icons.logout_rounded;
      } else {
        fabColor = Colors.grey; 
        icon = Icons.check_circle_outline;
        isDisabled = true;
      }

      return SizedBox(
        width: 75,
        height: 75,
        child: FloatingActionButton(
          onPressed: (loading || isDisabled)
              ? null
              : () {
                  _handleAttendance(controller);
                },
          backgroundColor: fabColor,
          shape: const CircleBorder(),
          elevation: 6,
          child: loading
              ? const CircularProgressIndicator(color: Colors.white)
              : Icon(icon, size: 36, color: Colors.white),
        ),
      );
    });
  }

  // 🔥 LOGIC INI YANG DIUPDATE BIAR SAMA KAYAK DASHBOARD
  void _handleAttendance(AttendanceController controller) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      
      // 1. Siapkan User Model
      final userModel = UserModel(
        uid: currentUser.uid,
        name: currentUser.displayName ?? 'Security User',
        email: currentUser.email ?? '',
        role: 'security',
        joinDate: DateTime.now(),
        officeLat: controller.officeLat.value,
        officeLng: controller.officeLng.value,
      );
      
      // 🔥 2. TARIK SHIFT DARI DB (METODE BARU)
      // Gak pake dummy "shift_pagi" lagi
      final db = DatabaseService();
      ShiftModel? todayShift = await db.getTodayShift(currentUser.uid);

      // 🔥 3. KIRIM KE CONTROLLER
      await controller.submitAttendance(userModel, todayShift);
    }
  }
}