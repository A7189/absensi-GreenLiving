import 'package:absensi_greenliving/controllers/admin_leave_controler.dart';
import 'package:absensi_greenliving/models/leave_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminLeaveApprovalPage extends StatelessWidget {
  const AdminLeaveApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final controller = Get.put(AdminLeaveController());

    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text("Persetujuan Izin", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: const Color(0xFF1B5E20),
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: "Permintaan Baru"),
              Tab(text: "Riwayat"),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async => await controller.loadAllData(),
          color: const Color(0xFF1B5E20),
          child: TabBarView(
            children: [
              _buildPendingList(controller), // Tab 1 (Live Data)
              _buildHistoryList(controller), // Tab 2 (Live Data)
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 1: PERMINTAAN MASUK (PENDING) ---
  Widget _buildPendingList(AdminLeaveController controller) {
    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
      if (controller.pendingList.isEmpty) return _emptyState("Tidak ada permintaan baru");

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.pendingList.length,
        itemBuilder: (context, index) {
          final item = controller.pendingList[index];
          return _buildLeaveCard(context, item, isPending: true, controller: controller);
        },
      );
    });
  }

  // --- TAB 2: RIWAYAT (HISTORY) ---
  Widget _buildHistoryList(AdminLeaveController controller) {
    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
      if (controller.historyList.isEmpty) return _emptyState("Belum ada riwayat izin");

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.historyList.length,
        itemBuilder: (context, index) {
          final item = controller.historyList[index];
          return _buildLeaveCard(context, item, isPending: false, controller: controller);
        },
      );
    });
  }

  Widget _emptyState(String msg) {
    return Center(child: Text(msg, style: GoogleFonts.poppins(color: Colors.grey)));
  }

  // --- WIDGET KARTU IZIN ---
  Widget _buildLeaveCard(BuildContext context, LeaveModel item, {required bool isPending, required AdminLeaveController controller}) {
    // 1. Warna Badge
    Color typeColor = Colors.blue;
    if (item.type == 'Sakit') typeColor = Colors.red;
    if (item.type == 'Cuti' || item.type == 'Cuti Tahunan') typeColor = Colors.orange;

    // 2. Format Tanggal
    String dateRange = "${DateFormat('dd MMM').format(item.startDate)} - ${DateFormat('dd MMM yyyy').format(item.endDate)}";
    
    // 3. Hitung Durasi Hari
    int daysCount = item.endDate.difference(item.startDate).inDays + 1;
    String days = "$daysCount Hari";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // HEADER KARTU (Nama & Tipe)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1B5E20).withOpacity(0.1),
                  child: Text(item.name.isNotEmpty ? item.name[0] : '?', style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Security Staff", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                // Badge Tipe Izin
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: typeColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    item.type,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: typeColor),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // BODY KARTU (Tanggal & Alasan)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    // Tampilkan Tanggal & Durasi
                    Text("$dateRange ($days)", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Alasan:",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  item.reason,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),

          // FOOTER (Tombol Aksi / Status History)
          if (isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showConfirmDialog(context, controller, item, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Tolak"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showConfirmDialog(context, controller, item, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Setujui", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            )
          else 
            // Kalau History, tunjukin statusnya
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.status == 'Approved' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
              ),
              child: Text(
                "Status: ${item.status == 'Approved' ? 'Disetujui' : 'Ditolak'}",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: item.status == 'Approved' ? Colors.green : Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, AdminLeaveController controller, LeaveModel item, bool isApproved) {
    Get.defaultDialog(
      title: isApproved ? "Setujui Izin?" : "Tolak Izin?",
      middleText: "Aksi ini tidak bisa dibatalkan.",
      textConfirm: "Ya, Proses",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      buttonColor: isApproved ? const Color(0xFF1B5E20) : Colors.red,
      onConfirm: () {
        Get.back();
        if (item.id != null) {
          controller.updateStatus(item.id!, isApproved);
        }
      },
    );
  }
}