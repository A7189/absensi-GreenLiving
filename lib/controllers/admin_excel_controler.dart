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

  // ========================================================
  // 🔥 FUNGSI UTAMA: DOWNLOAD REKAP (MATRIX)
  // ========================================================
  void downloadMonthlyRecap() async {
    try {
      isExporting.value = true;
      
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))), 
        barrierDismissible: false
      );

      DateTime now = DateTime.now();
      String monthName = DateFormat('MMMM_yyyy', 'id_ID').format(now);
      
      DateTime start = DateTime(now.year, now.month, 1);
      DateTime end = DateTime(now.year, now.month + 1, 0);
      String startStr = DateFormat('yyyy-MM-dd').format(start);
      String endStr = DateFormat('yyyy-MM-dd').format(end);

      // --- BELANJA DATA ---
      var futureEmployees = _db.getAllEmployees();
      var futureSchedule = FirebaseFirestore.instance.collection('shift_schedule')
          .where('date', isGreaterThanOrEqualTo: startStr)
          .where('date', isLessThanOrEqualTo: endStr)
          .get();
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
        monthName, 
        employees, 
        finalMap,
        start,
        end
      );

      // 🔥 FIX: BALIKIN KE ATAS (TOP)
      Get.snackbar(
        "Berhasil", 
        "Laporan $monthName telah didownload! 📂",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP, // <--- UDAH SAYA PINDAH KE ATAS
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