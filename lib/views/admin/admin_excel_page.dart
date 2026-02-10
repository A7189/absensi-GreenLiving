import 'package:absensi_greenliving/controllers/admin_excel_controler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminExcelPage extends StatelessWidget {
  const AdminExcelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExcelController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Background abu sangat muda biar konten nonjol
      
      // 🔥 APP BAR SIMPLE (Sesuai Screenshot)
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20), // Hijau Green Living
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Export Data Absen", 
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            fontSize: 18
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // KARTU PILIH TANGGAL (Simple Box)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Rentang Tanggal", style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 10),
                  
                  // Klik buat pilih tanggal
                  InkWell(
                    onTap: () async {
                      DateTimeRange? picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2030),
                        initialDateRange: DateTimeRange(start: controller.startDate.value, end: controller.endDate.value),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(primary: Color(0xFF1B5E20), onPrimary: Colors.white, onSurface: Colors.black),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) controller.updateDateRange(picked.start, picked.end);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF1B5E20), size: 20),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Obx(() => Text(
                              "${DateFormat('dd MMM yyyy').format(controller.startDate.value)}  -  ${DateFormat('dd MMM yyyy').format(controller.endDate.value)}",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                            )),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // INFO TOTAL HARI (Simple Badge)
            Obx(() {
              int days = controller.endDate.value.difference(controller.startDate.value).inDays + 1;
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Total Data: $days Hari",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              );
            }),

            const Spacer(),

            // TOMBOL DOWNLOAD (Full Width Hijau)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isExporting.value ? null : () => controller.downloadReport(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
                child: controller.isExporting.value
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        "Download Excel", 
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)
                      ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}