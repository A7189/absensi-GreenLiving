import 'package:absensi_greenliving/controllers/nav_controler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomBottomNavBar extends StatelessWidget {
  final bool isAdmin;

  const CustomBottomNavBar({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return Obx(
      () => BottomAppBar(
        shape: isAdmin ? null : const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 20,
        child: SizedBox(
          // 🔥 UBAH JADI 70 (Titik Aman, gak kerendahan gak ketinggian)
          height: 70, 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: isAdmin 
                ? _buildAdminMenu(controller) 
                : _buildUserMenu(controller),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAdminMenu(NavigationController controller) {
    return [
      _buildNavItem(
        icon: controller.selectedIndex.value == 0 ? Icons.dashboard : Icons.dashboard_outlined,
        label: 'Monitor',
        isSelected: controller.selectedIndex.value == 0,
        onTap: () => controller.changeIndex(0),
      ),
      _buildNavItem(
        icon: controller.selectedIndex.value == 1 ? Icons.edit_calendar : Icons.edit_calendar_outlined,
        label: 'Jadwal',
        isSelected: controller.selectedIndex.value == 1,
        onTap: () => controller.changeIndex(1),
      ),
      _buildNavItem(
        icon: controller.selectedIndex.value == 2 ? Icons.person : Icons.person_outline,
        label: 'Profil',
        isSelected: controller.selectedIndex.value == 2,
        onTap: () => controller.changeIndex(2),
      ),
    ];
  }

  List<Widget> _buildUserMenu(NavigationController controller) {
    return [
      _buildNavItem(
        icon: controller.selectedIndex.value == 0 ? Icons.grid_view_rounded : Icons.grid_view_outlined,
        label: 'Dashboard',
        isSelected: controller.selectedIndex.value == 0,
        onTap: () => controller.changeIndex(0),
      ),
      const SizedBox(width: 50), 
      _buildNavItem(
        icon: controller.selectedIndex.value == 1 ? Icons.person : Icons.person_outline,
        label: 'Profil',
        isSelected: controller.selectedIndex.value == 1,
        onTap: () => controller.changeIndex(1),
      ),
    ];
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Padding dirapetin dikit
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF1B5E20) : Colors.grey,
              // 🔥 KECILIN DIKIT (Standar Android = 24)
              size: 24, 
            ),
            // 🔥 JARAK RAPETIN DIKIT
            const SizedBox(height: 2), 
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF1B5E20) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}