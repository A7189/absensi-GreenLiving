import 'package:absensi_greenliving/controllers/leave_controler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AddLeavePage extends StatelessWidget {
  const AddLeavePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 FIX: Pake Get.find() biar nyambung sama Controller dari halaman History
    final controller = Get.find<LeaveController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      appBar: AppBar(
        title: Text("Pengajuan Izin", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1B5E20),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Jenis Izin"),
            const SizedBox(height: 10),
            
            // DROPDOWN TIPE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Obx(() => DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedType.value,
                  isExpanded: true,
                  items: controller.leaveTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, style: GoogleFonts.poppins()),
                    );
                  }).toList(),
                  onChanged: controller.updateType,
                ),
              )),
            ),

            const SizedBox(height: 20),
            _buildSectionTitle("Tanggal (Mulai - Selesai)"),
            const SizedBox(height: 10),

            // 🔥 DATE RANGE PICKER
            InkWell(
              onTap: () async {
                DateTimeRange? pickedRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF1B5E20),
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                
                if (pickedRange != null) {
                  controller.updateDateRange(pickedRange.start, pickedRange.end);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Color(0xFF1B5E20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Obx(() {
                        // Pastikan initializeDateFormatting sudah dipanggil di main.dart kalau mau locale ID
                        // Kalau error, apus 'id_ID' jadi default dulu
                        String start = DateFormat('dd MMM yyyy').format(controller.startDate.value);
                        String end = DateFormat('dd MMM yyyy').format(controller.endDate.value);
                        return Text(
                          "$start - $end", 
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildSectionTitle("Alasan"),
            const SizedBox(height: 10),

            // TEXT AREA ALASAN
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
              ),
              child: TextField(
                controller: controller.reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Contoh: Sakit demam, perlu istirahat 2 hari...",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(15),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // TOMBOL KIRIM
            SizedBox(
              width: double.infinity,
              height: 55,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: controller.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Kirim Pengajuan", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
    );
  }
}