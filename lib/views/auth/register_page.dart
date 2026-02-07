import 'package:absensi_greenliving/controllers/register_controler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisterController());
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Obx(() => TextField(
              controller: passwordController,
              obscureText: !controller.isPasswordVisible.value,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(controller.isPasswordVisible.value ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => controller.isPasswordVisible.toggle(),
                ),
              ),
            )),
            const SizedBox(height: 16),
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedRole.value,
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              items: ['security', 'admin'].map((role) {
                return DropdownMenuItem(value: role, child: Text(role.toUpperCase()));
              }).toList(),
              onChanged: (val) => controller.selectedRole.value = val!,
            )),
            const SizedBox(height: 32),
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading.value 
                  ? null 
                  : () => controller.registerUser(nameController.text, emailController.text, passwordController.text),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: controller.isLoading.value 
                  ? const CircularProgressIndicator() 
                  : const Text('DAFTAR SEKARANG'),
              ),
            )),
          ],
        ),
      ),
    );
  }
}