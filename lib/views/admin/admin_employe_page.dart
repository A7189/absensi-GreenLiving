import 'package:absensi_greenliving/controllers/admin_employe_controler.dart';
import 'package:absensi_greenliving/models/user_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:absensi_greenliving/views/auth/register_page.dart';

class AdminEmployeePage extends StatelessWidget {
  const AdminEmployeePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject Controller
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
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Tunggu sampai balik dari halaman Register, terus refresh
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
      
      // 🔥 FITUR TARIK UNTUK REFRESH (PULL TO REFRESH)
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

  Widget _buildEmployeeCard(BuildContext context, UserModel user, Color primaryColor, AdminEmployeeController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ),
          ),
          const SizedBox(width: 15),
          
          // Info Pegawai
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  "${user.role} • ${user.email}", // Tampilkan Role & Email
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // 🔥 MENU EDIT / HAPUS
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
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 10), Text("Edit Data")]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 10), Text("Hapus Pegawai")]),
              ),
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
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: (selectedRole == 'security' || selectedRole == 'admin') ? selectedRole : 'security',
              items: const [
                DropdownMenuItem(value: 'security', child: Text("Security")),
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
      },
    );
  }

  // --- POPUP HAPUS ---
  void _showDeleteConfirm(BuildContext context, AdminEmployeeController controller, UserModel user) {
    Get.defaultDialog(
      title: "Hapus Pegawai?",
      middleText: "Anda yakin ingin menghapus ${user.name}? \n\nData absensi & jadwal dia akan tetap tersimpan di database, tapi dia tidak bisa login lagi.",
      textConfirm: "Ya, Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        controller.deleteEmployee(user.uid);
      },
    );
  }
}