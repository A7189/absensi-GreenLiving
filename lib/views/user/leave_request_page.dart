import 'package:absensi_greenliving/controllers/leave_controler.dart';
import 'package:absensi_greenliving/routes/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class LeaveRequestPage extends StatelessWidget {
  const LeaveRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller tetap dipanggil di sini biar data ke-load
    final controller = Get.put(LeaveController());

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      appBar: AppBar(
        title: Text("Riwayat Izin", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1B5E20),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      
      // 🔥 TOMBOL MENGAMBANG (FAB) BUAT NAMBAH IZIN
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Arahkan ke Halaman Form
          Get.toNamed(Routes.ADD_LEAVE, arguments: controller.myLeaves.length.toString()); 
        },
        backgroundColor: const Color(0xFF1B5E20),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("Buat Izin", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      body: Obx(() {
        if (controller.myLeaves.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text("Belum ada riwayat izin", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: controller.myLeaves.length,
          itemBuilder: (context, index) {
            var data = controller.myLeaves[index].data() as Map<String, dynamic>;
            return _buildHistoryCard(data);
          },
        );
      }),
    );
  }

  // 🔥 WIDGET KARTU RIWAYAT (Desain Tetap Rapi)
  Widget _buildHistoryCard(Map<String, dynamic> data) {
    String status = data['status'] ?? 'Pending';
    Color statusColor;
    Color bgColor;

    switch (status.toLowerCase()) {
      case 'approved':
      case 'disetujui':
        statusColor = Colors.green[700]!;
        bgColor = Colors.green[50]!;
        break;
      case 'rejected':
      case 'ditolak':
        statusColor = Colors.red[700]!;
        bgColor = Colors.red[50]!;
        break;
      default:
        statusColor = Colors.orange[700]!;
        bgColor = Colors.orange[50]!;
    }

    String dateRange = "-";
    try {
      if (data['startDate'] != null && data['endDate'] != null) {
        DateTime start = (data['startDate'] as Timestamp).toDate();
        DateTime end = (data['endDate'] as Timestamp).toDate();
        dateRange = "${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end)}";
      }
    } catch (e) { dateRange = "Error Tanggal"; }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 4)), 
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['type'] ?? 'Izin', 
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 5),
              Text(dateRange, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Alasan: ${data['reason'] ?? '-'}",
            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}