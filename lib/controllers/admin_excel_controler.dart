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

  var startDate = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  var endDate = DateTime.now().obs;

  void updateDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
  }

  void downloadReport() async {
    try {
      isExporting.value = true;
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))), 
        barrierDismissible: false
      );

      DateTime start = startDate.value;
      DateTime end = endDate.value;
      DateTime endFullDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

      String startStr = DateFormat('yyyy-MM-dd').format(start);
      String endStr = DateFormat('yyyy-MM-dd').format(end);
      String reportTitle = "Laporan_${DateFormat('dd MMM').format(start)}-${DateFormat('dd MMM yyyy').format(end)}";

      // 1. FETCH DATA
      var futureEmployees = _db.getAllEmployees();
      var futureSchedule = FirebaseFirestore.instance.collection('shift_schedule')
          .where('date', isGreaterThanOrEqualTo: startStr)
          .where('date', isLessThanOrEqualTo: endStr)
          .get();
      var futureAttendance = FirebaseFirestore.instance.collection('attendance_logs')
          .where('date', isGreaterThanOrEqualTo: startStr)
          .where('date', isLessThanOrEqualTo: endStr)
          .get();

      var results = await Future.wait([futureEmployees, futureSchedule, futureAttendance]);

      List<UserModel> employees = results[0] as List<UserModel>;
      QuerySnapshot scheduleSnap = results[1] as QuerySnapshot;
      QuerySnapshot attendanceSnap = results[2] as QuerySnapshot;

      // 2. MAPPING DATA
      Map<String, Map<String, dynamic>> finalMap = {};

      // Init Slot Kosong
      for (var emp in employees) {
        finalMap[emp.uid] = {};
      }

      // Masukin JADWAL Dulu (Sebagai Base Layer)
      for (var doc in scheduleSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String uid = data['uid'];
        String date = data['date'];
        
        if (finalMap.containsKey(uid)) {
          finalMap[uid]![date] = {
            'type': 'schedule',
            'value': data['shiftId'], // "pagi", "Siang", "Libur"
            'shiftId': data['shiftId'] // Simpan buat cadangan
          };
        }
      }

      // Masukin ABSENSI (Layer Atas)
      for (var doc in attendanceSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String uid = data['uid'] ?? data['userId']; 
        String date = data['date'];
        
        if (finalMap.containsKey(uid)) {
          // 🔥 LOGIC PENENTUAN SHIFT (Biar warnanya gak putih)
          // Prioritas 1: Ambil dari log absen (shiftName/shiftId)
          // Prioritas 2: Ambil dari data jadwal yang udah kita simpan di loop sebelumnya
          String shiftFromLog = data['shiftName'] ?? data['shiftId'] ?? '';
          
          String shiftFromSchedule = "";
          if (finalMap[uid]![date] != null && finalMap[uid]![date]!['shiftId'] != null) {
             shiftFromSchedule = finalMap[uid]![date]!['shiftId'];
          }

          // Gabungkan: Kalau log kosong, pake jadwal
          String finalShiftName = shiftFromLog.isNotEmpty ? shiftFromLog : shiftFromSchedule;

          // Format Jam
          String checkIn = "-";
          if (data['checkInTime'] != null) {
            DateTime t = (data['checkInTime'] as Timestamp).toDate();
            checkIn = DateFormat('HH:mm').format(t);
          }
          
          String status = data['status'] ?? 'Hadir'; // "Terlambat" / "Hadir"
          
          finalMap[uid]![date] = {
            'type': 'attendance',
            'value': checkIn, 
            'status': status, 
            'shift': finalShiftName // 🔥 INI KUNCINYA BIAR WARNA MUNCUL
          };
        }
      }

      if (Get.isDialogOpen ?? false) Get.back(); 
      
      await _excelService.exportAttendanceMatrix(
        reportTitle, 
        employees, 
        finalMap,
        start,
        endFullDay 
      );

      Get.snackbar(
        "Berhasil", 
        "Laporan Absensi berhasil didownload! 📂",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20)
      );

    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Gagal", "$e", backgroundColor: Colors.red, colorText: Colors.white);
      print("Excel Error: $e");
    } finally {
      isExporting.value = false;
    }
  }
}