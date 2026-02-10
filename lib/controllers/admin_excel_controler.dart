import 'package:absensi_greenliving/models/user_models.dart';
import 'package:absensi_greenliving/services/database_service.dart';
import 'package:absensi_greenliving/services/excel_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ExcelController extends GetxController {
  final DatabaseService _db = DatabaseService(); 
  final ExcelService _excelService = ExcelService(); 

  var isExporting = false.obs; 

  // 🔥 STATE TANGGAL (DEFAULT: BULAN INI)
  var startDate = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  var endDate = DateTime.now().obs;

  // Fungsi Update Tanggal dari UI
  void updateDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
  }

  // ========================================================
  // 🔥 FUNGSI UTAMA: DOWNLOAD CUSTOM RANGE
  // ========================================================
  void downloadReport() async {
    try {
      isExporting.value = true;
      
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))), 
        barrierDismissible: false
      );

      // 1. Ambil Tanggal dari State
      DateTime start = startDate.value;
      DateTime end = endDate.value; // Ambil jam 00:00
      
      // Fix End Date: Set ke jam 23:59:59 biar data hari terakhir keambil semua
      DateTime endFullDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

      String startStr = DateFormat('yyyy-MM-dd').format(start);
      String endStr = DateFormat('yyyy-MM-dd').format(end);
      
      // Nama File & Judul Laporan
      String reportTitle = "Laporan_${DateFormat('dd MMM').format(start)}-${DateFormat('dd MMM yyyy').format(end)}";

      // --- BELANJA DATA ---
      var futureEmployees = _db.getAllEmployees();
      
      // Ambil Jadwal di Range
      var futureSchedule = FirebaseFirestore.instance.collection('shift_schedule')
          .where('date', isGreaterThanOrEqualTo: startStr)
          .where('date', isLessThanOrEqualTo: endStr)
          .get();
          
      // Ambil Absen di Range
      var futureAttendance = FirebaseFirestore.instance.collection('attendance')
          .where('date', isGreaterThanOrEqualTo: startStr)
          .where('date', isLessThanOrEqualTo: endStr)
          .get();

      var results = await Future.wait([futureEmployees, futureSchedule, futureAttendance]);

      List<UserModel> employees = results[0] as List<UserModel>;
      QuerySnapshot scheduleSnap = results[1] as QuerySnapshot;
      QuerySnapshot attendanceSnap = results[2] as QuerySnapshot;

      // --- MASAK DATA (MERGING) ---
      Map<String, Map<String, dynamic>> finalMap = {};

      for (var emp in employees) {
        finalMap[emp.uid] = {};
      }

      for (var doc in scheduleSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String uid = data['uid'];
        String date = data['date'];
        if (finalMap.containsKey(uid)) {
          finalMap[uid]![date] = {
            'type': 'schedule',
            'value': data['shiftId'] 
          };
        }
      }

      for (var doc in attendanceSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String uid = data['uid'];
        String date = data['date'];
        if (finalMap.containsKey(uid)) {
          String checkIn = "-";
          if (data['checkInTime'] != null) {
            DateTime t = (data['checkInTime'] as Timestamp).toDate();
            checkIn = DateFormat('HH:mm').format(t);
          }
          String status = data['status'] ?? 'Hadir';
          finalMap[uid]![date] = {
            'type': 'attendance',
            'value': checkIn, 
            'status': status, 
            'shift': data['shift']
          };
        }
      }

      // --- CETAK EXCEL ---
      Get.back(); // Tutup Loading
      
      await _excelService.exportAttendanceMatrix(
        reportTitle, // Nama File Custom
        employees, 
        finalMap,
        start,
        endFullDay // Kirim end date yg udah dipolin jamnya
      );

      Get.snackbar(
        "Berhasil", 
        "Laporan berhasil didownload! 📂",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20)
      );

    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Gagal", "Terjadi kesalahan: $e", backgroundColor: Colors.red, colorText: Colors.white);
      print("Excel Controller Error: $e");
    } finally {
      isExporting.value = false;
    }
  }
}