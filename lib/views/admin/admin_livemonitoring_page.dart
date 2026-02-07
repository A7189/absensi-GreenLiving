import 'package:absensi_greenliving/controllers/admin_livemonitor_controler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminLiveMonitoringPage extends StatelessWidget {
  const AdminLiveMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminLiveMonitoringController());
    String todayDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      appBar: AppBar(
        title: Text("Monitoring Harian", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), 
          onPressed: () => Get.back()
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.loadLiveMonitor(),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Text(todayDate, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey[700])),
              ),
            ),
            const SizedBox(height: 20),

            // 🔥 FIX: HAPUS PARAMETER JAM BIAR BERSIH
            _buildShiftSection("SHIFT PAGI", Colors.orange, controller.pagiList),
            _buildShiftSection("SHIFT SIANG", Colors.blue, controller.siangList),
            _buildShiftSection("SHIFT MALAM", const Color(0xFF1B5E20), controller.malamList),

            const SizedBox(height: 30),
          ],
        );
      }),
    );
  }

  // 🔥 WIDGET UPDATE: Hapus parameter String time
  Widget _buildShiftSection(String title, Color color, List<Map<String, dynamic>> dataList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_time_filled, color: color, size: 18),
            const SizedBox(width: 8),
            // Hapus Text Jam, Sisain Judul Aja
            Text("$title", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text("${dataList.length} Personil", style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 10),
        
        if (dataList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Text("Tidak ada personil terjadwal.", style: GoogleFonts.poppins(color: Colors.grey, fontStyle: FontStyle.italic)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dataList.length,
            itemBuilder: (context, index) {
              var item = dataList[index];
              String name = item['name'] ?? 'Tanpa Nama';
              String checkInTime = item['checkInTime'] ?? '-';
              bool isPresent = item['isPresent'] ?? false;
              
              String statusLabel = item['statusLabel'] ?? 'Belum Hadir';
              String colorCode = item['statusColor'] ?? 'grey';
              
              Color statusColor = Colors.grey;
              if (colorCode == 'red') statusColor = Colors.red;
              else if (colorCode == 'green') statusColor = Colors.green;
              else if (colorCode == 'blue') statusColor = Colors.blue;

              double opacityVal = isPresent ? 1.0 : 0.5;

              return Opacity(
                opacity: opacityVal,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isPresent ? statusColor : Colors.grey.withOpacity(0.3), 
                      width: isPresent ? 1.5 : 1
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isPresent ? statusColor.withOpacity(0.1) : Colors.grey[100],
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "?", 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: isPresent ? statusColor : Colors.grey[600]
                          )
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name, 
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, 
                                fontSize: 15,
                                color: Colors.black87
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  isPresent ? Icons.check_circle : Icons.access_time, 
                                  size: 12, 
                                  color: statusColor
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPresent ? "$statusLabel ($checkInTime)" : "Belum Hadir",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12, 
                                    color: statusColor,
                                    fontWeight: isPresent ? FontWeight.w600 : FontWeight.normal
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      if (isPresent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20)
                          ),
                          child: Text(
                            statusLabel.split(' ')[0].toUpperCase(),
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)
                          ),
                        )
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}