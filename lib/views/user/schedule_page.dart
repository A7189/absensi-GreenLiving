
import 'package:absensi_greenliving/controllers/schedule_controler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';


class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScheduleController());

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      appBar: AppBar(
        title: const Text(
          'Jadwal Kerja',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadMySchedule(),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.weeklyShifts.isEmpty) {
          return const Center(
            child: Text("Jadwal tidak tersedia\n(Coba refresh atau hubungi Admin)", textAlign: TextAlign.center),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: controller.weeklyShifts.length,
          itemBuilder: (context, index) {
            final item = controller.weeklyShifts[index];
            
            // 1. AMBIL DATA DARI MAP (Sesuai Controller Baru)
            DateTime date = item['date'];
            var shiftData = item['shift']; // Ini Map<String, dynamic>, bukan ShiftModel lagi

            // Cek Hari Ini
            bool isToday = DateFormat('yyyy-MM-dd').format(date) == 
                           DateFormat('yyyy-MM-dd').format(DateTime.now());

            // Default Values (Libur)
            String label = "Libur";
            String start = "--:--";
            String end = "--:--";
            Color statusColor = Colors.grey;
            Color bgColor = Colors.grey.withOpacity(0.1);

            // 2. JIKA ADA SHIFT -> ISI DATANYA
            if (shiftData != null) {
              label = shiftData['shiftName']; // "Shift Pagi"
              start = shiftData['startTime']; // "08:00" (Sudah String)
              end = shiftData['endTime'];     // "16:00" (Sudah String)
              
              // Ambil warna dari Controller (Integer), ubah jadi Color
              int colorInt = shiftData['color'] ?? 0xFF9E9E9E;
              statusColor = Color(colorInt);
              bgColor = statusColor.withOpacity(0.1); // Background pudar sesuai warna shift
            } else {
              // Kalau Libur -> Merah pudar dikit biar sadar
              statusColor = Colors.red[300]!;
              bgColor = Colors.red.withOpacity(0.05);
            }

            String hours = "$start - $end";

            return _buildScheduleCard(date, label, hours, statusColor, bgColor, isToday);
          },
        );
      }),
    );
  }

  // 🔥 WIDGET KARTU (Updated logic color)
  Widget _buildScheduleCard(
    DateTime date, 
    String label, 
    String hours, 
    Color statusColor, 
    Color bgColor, 
    bool isToday
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, // Card tetap putih biar bersih
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isToday ? const Color(0xFF1B5E20) : Colors.transparent, // Border Hijau kalau hari ini
          width: isToday ? 2 : 0
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // BAGIAN KIRI: TANGGAL
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE', 'id_ID').format(date), // Nama Hari
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isToday ? const Color(0xFF1B5E20) : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMM yyyy', 'id_ID').format(date), // Tanggal
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          
          const Spacer(),
          
          // BAGIAN KANAN: LABEL SHIFT & JAM
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Badge Shift (Warna Background ikut Status)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bgColor, // Background pudar
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: statusColor, // Teks warna tajam
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Jam Kerja
              Text(
                hours,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}