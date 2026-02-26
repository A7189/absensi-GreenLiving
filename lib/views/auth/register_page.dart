import 'package:absensi_greenliving/controllers/register_controler.dart';
import 'package:absensi_greenliving/models/user_models.dart'; 
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // 🔥 TAMBAHAN: Buat format tanggal biar rapi

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisterController());
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    final List<Map<String, String>> roleOptions = [
      {'value': UserModel.roleSecurity, 'label': 'Satpam'},
      {'value': UserModel.roleCleaner, 'label': 'Kebersihan'},
      {'value': UserModel.roleAdmin,    'label': 'Administrator'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun Karyawan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- NAMA ---
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap', 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline)
              ),
            ),
            const SizedBox(height: 16),
            
            // --- EMAIL ---
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email', 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined)
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            // --- PASSWORD ---
            Obx(() => TextField(
              controller: passwordController,
              obscureText: !controller.isPasswordVisible.value,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(controller.isPasswordVisible.value ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => controller.isPasswordVisible.toggle(),
                ),
              ),
            )),
            const SizedBox(height: 16),

            // --- DROPDOWN ROLE ---
            Obx(() => DropdownButtonFormField<String>(
              value: roleOptions.any((e) => e['value'] == controller.selectedRole.value) 
                  ? controller.selectedRole.value 
                  : UserModel.roleSecurity,
              decoration: const InputDecoration(
                labelText: 'Posisi / Jabatan', 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work_outline)
              ),
              items: roleOptions.map((role) {
                return DropdownMenuItem(
                  value: role['value'], 
                  child: Text(role['label']!), 
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) controller.selectedRole.value = val;
              },
            )),

            const SizedBox(height: 16),

            // --- 🔥 TAMBAHAN: TANGGAL BERGABUNG (DATE PICKER) ---
            Obx(() => TextField(
              readOnly: true, // Gabisa ngetik manual
              onTap: () => controller.pickJoinDate(context), // Klik -> Buka Kalender
              decoration: const InputDecoration(
                labelText: 'Tanggal Bergabung',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                suffixIcon: Icon(Icons.arrow_drop_down),
                hintText: "Pilih Tanggal",
              ),
              // Nampilin tanggal yang dipilih (Format: 14 Februari 2026)
              controller: TextEditingController(
                text: DateFormat('dd MMMM yyyy').format(controller.joinDate.value)
              ),
            )),
            
            const SizedBox(height: 32),
            
            // --- TOMBOL DAFTAR ---
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading.value 
                  ? null 
                  : () => controller.registerUser(nameController.text, emailController.text, passwordController.text),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF1B5E20), 
                  foregroundColor: Colors.white,
                ),
                child: controller.isLoading.value 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('DAFTAR SEKARANG', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}