import 'package:absensi_greenliving/controllers/admin_employe_controler.dart';
import 'package:absensi_greenliving/models/user_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:absensi_greenliving/views/auth/register_page.dart';
import 'package:intl/intl.dart'; 

class AdminEmployeePage extends StatelessWidget {
  const AdminEmployeePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminEmployeeController());
    final Color primaryGreen = const Color(0xFF1B5E20);
    final Color bgGrey = const Color(0xFFF2F7F2);

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: Text(
          "Data Pegawai",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        
        // 🔥 TOMBOL FILTER BARU
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: "Urutkan Data",
            onPressed: () => _showSortBottomSheet(context, controller),
          )
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Get.to(() => const RegisterPage());
          controller.loadEmployees(); 
        },
        backgroundColor: primaryGreen,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(
          "Tambah", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.loadEmployees();
        },
        color: primaryGreen,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.employees.isEmpty) {
            return Center(
              child: Text("Belum ada data pegawai.", style: GoogleFonts.poppins(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: controller.employees.length,
            itemBuilder: (context, index) {
              final user = controller.employees[index];
              return _buildEmployeeCard(context, user, primaryGreen, controller);
            },
          );
        }),
      ),
    );
  }

  // 🔥 BOTTOM SHEET PILIHAN SORTING
  void _showSortBottomSheet(BuildContext context, AdminEmployeeController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Urutkan Berdasarkan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            
            _buildSortOption(controller, "senior", "Paling Senior (Lama)", Icons.history),
            _buildSortOption(controller, "junior", "Paling Baru (Junior)", Icons.new_releases),
            const Divider(),
            _buildSortOption(controller, "az", "Nama (A - Z)", Icons.sort_by_alpha),
            _buildSortOption(controller, "za", "Nama (Z - A)", Icons.sort_by_alpha_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(AdminEmployeeController controller, String value, String label, IconData icon) {
    return Obx(() {
      bool isSelected = controller.currentSortOption.value == value;
      return ListTile(
        leading: Icon(icon, color: isSelected ? const Color(0xFF1B5E20) : Colors.grey),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1B5E20) : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF1B5E20)) : null,
        onTap: () {
          controller.applySort(value);
          Get.back(); // Tutup sheet setelah milih
        },
      );
    });
  }

  Widget _buildEmployeeCard(BuildContext context, UserModel user, Color primaryColor, AdminEmployeeController controller) {
    String joinDateStr = "-";
    if (user.joinDate != null) { // DateTime.now() defaultnya gak null, tapi amanin aja
      joinDateStr = DateFormat('d MMM yyyy').format(user.joinDate);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  "${user.roleDisplayName} • ${user.email}", 
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(5)),
                  child: Text(
                    "Bergabung: $joinDateStr",
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700], fontStyle: FontStyle.italic),
                  ),
                )
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditDialog(context, controller, user);
              } else if (value == 'delete') {
                _showDeleteConfirm(context, controller, user);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 10), Text("Edit Data")])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 10), Text("Hapus Pegawai")])),
            ],
          ),
        ],
      ),
    );
  }

  // --- POPUP EDIT ---
  void _showEditDialog(BuildContext context, AdminEmployeeController controller, UserModel user) {
    final nameC = TextEditingController(text: user.name);
    String selectedRole = user.role; 

    Get.defaultDialog(
      title: "Edit Pegawai",
      titleStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      content: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: ['security', 'admin', 'cleaner'].contains(selectedRole) ? selectedRole : 'security',
              items: const [
                DropdownMenuItem(value: 'security', child: Text("Security")),
                DropdownMenuItem(value: 'cleaner', child: Text("Kebersihan")),
                DropdownMenuItem(value: 'admin', child: Text("Admin")),
              ],
              onChanged: (val) => selectedRole = val!,
              decoration: const InputDecoration(labelText: "Jabatan", border: OutlineInputBorder()),
            )
          ],
        ),
      ),
      textConfirm: "Simpan",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF1B5E20),
      onConfirm: () {
        controller.editEmployee(user.uid, nameC.text, selectedRole);
        Get.back(); 
      },
    );
  }

  // --- POPUP HAPUS ---
  void _showDeleteConfirm(BuildContext context, AdminEmployeeController controller, UserModel user) {
    Get.defaultDialog(
      title: "Hapus Pegawai?",
      middleText: "Anda yakin ingin menghapus ${user.name}?",
      textConfirm: "Ya, Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        controller.deleteEmployee(user.uid);
        Get.back(); 
      },
    );
  }
}