import 'package:absensi_greenliving/controllers/admin_history_controler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Buat baca Timestamp

class AdminHistoryPage extends StatelessWidget {
  const AdminHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminHistoryController());

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF6), 
      appBar: AppBar(
        title: Text("Riwayat Pegawai", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 22)),
        backgroundColor: const Color(0xFF1B5E20),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          // SORTING BUTTON
          Obx(() => PopupMenuButton<bool>(
            icon: const Icon(Icons.sort, color: Colors.white),
            initialValue: controller.isNewest.value,
            onSelected: (val) {
               controller.isNewest.value = val;
               controller.runFilter(); // Refresh filter
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: true, child: Text("Terbaru")),
              const PopupMenuItem(value: false, child: Text("Terlama")),
            ],
          ))
        ],
      ),
      body: Column(
        children: [
          // 🔥 1. SEARCH BAR AREA
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            color: const Color(0xFFFDFBF6),
            child: TextField(
              controller: controller.searchController, // Pake Controller TextField
              onChanged: (val) => controller.runFilter(), // Trigger Filter pas ngetik
              decoration: InputDecoration(
                hintText: "Cari nama pegawai...",
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF1B5E20)),
                ),
              ),
            ),
          ),

          // 🔥 2. LIST DATA (Expanded biar menuhin sisa layar)
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
              }

              // Kalau kosong karena search gak ketemu
              if (controller.finalLogs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 80, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text(
                        controller.searchController.text.isEmpty 
                            ? "Belum ada data absensi" 
                            : "Nama tidak ditemukan", 
                        style: GoogleFonts.poppins(color: Colors.grey)
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: controller.finalLogs.length,
                itemBuilder: (context, index) {
                  // 🔥 AMBIL DATA DARI MAP
                  final log = controller.finalLogs[index];
                  final String name = log['name'] ?? 'Unknown';
                  
                  // Format Data (Timestamp -> String)
                  Timestamp? ts = log['checkInTime'];
                  DateTime date = ts != null ? ts.toDate() : DateTime.now();

                  Timestamp? tsOut = log['checkOutTime'];
                  DateTime? dateOut = tsOut != null ? tsOut.toDate() : null;

                  String tanggal = DateFormat('yyyy-MM-dd').format(date);
                  String jamMasuk = DateFormat('HH:mm').format(date);
                  String jamPulang = dateOut != null ? DateFormat('HH:mm').format(dateOut) : '--:--';

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
                        // NAMA PEGAWAI
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF1B5E20).withOpacity(0.1),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?', 
                                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20))
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name, 
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color.fromARGB(255, 0, 0, 0)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(tanggal, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        
                        const Divider(height: 25), 
                        
                        // JAM DATANG & PULANG
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
          ),
        ],
      ),
    );
  }
}