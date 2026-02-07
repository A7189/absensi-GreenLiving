import 'package:absensi_greenliving/controllers/history_controler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HistoryController());

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF6),
      appBar: AppBar(
        title: Text("Riwayat Absensi", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white,fontSize: 22)),
        backgroundColor: const Color(0xFF1B5E20),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
        }

        if (controller.historyList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_toggle_off, size: 80, color: Colors.grey),
                const SizedBox(height: 10),
                Text("Belum ada riwayat absen", style: GoogleFonts.poppins(color: Colors.grey)),
                TextButton(onPressed: () => controller.fetchHistory(), child: const Text("Refresh"))
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: controller.historyList.length,
          itemBuilder: (context, index) {
            var data = controller.historyList[index].data() as Map<String, dynamic>;
            
            String tanggal = data['date'] ?? '-';
            
            // 🔥 AMBIL DATA LANGSUNG TO THE POINT
            var checkInRaw = data['checkIn'];   // Waktu Masuk
            var checkOutRaw = data['checkOut']; // Waktu Pulang

            String jamMasuk = controller.formatTime(checkInRaw);
            String jamPulang = controller.formatTime(checkOutRaw);

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(tanggal, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  const Divider(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // KOLOM DATANG
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("DATANG", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.login, size: 18, color: Colors.green),
                              const SizedBox(width: 5),
                              Text(jamMasuk, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                            ],
                          ),
                        ],
                      ),
                      Container(height: 30, width: 1, color: Colors.grey[300]),
                      // KOLOM PULANG
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("PULANG", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Text(jamPulang, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                              const SizedBox(width: 5),
                              const Icon(Icons.logout, size: 18, color: Colors.orange),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}