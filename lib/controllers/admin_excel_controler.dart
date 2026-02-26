import 'package:absensi_greenliving/models/user_models.dart';
import 'package:absensi_greenliving/services/database_service.dart';
import 'package:absensi_greenliving/services/excel_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ExcelController extends GetxController {
  final DatabaseService _dbService = DatabaseService(); 
  final ExcelService _excelService = ExcelService(); 

  var isExporting = false.obs; 
  var startDate = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  var endDate = DateTime.now().obs;

  void updateDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
  }

  Future<void> downloadReport() async {
    // Tampilkan Loading
    isExporting.value = true;
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))), 
      barrierDismissible: false
    );

    try {
      DateTime start = startDate.value;
      DateTime end = endDate.value;
      String startStr = DateFormat('yyyy-MM-dd').format(start);
      String endStr = DateFormat('yyyy-MM-dd').format(end);
      
      String fileName = "absensi green living (${DateFormat('dd-MM-yyyy').format(start)} - ${DateFormat('dd-MM-yyyy').format(end)})";

      // 1. FETCH DATA (Parallel)
      var results = await Future.wait([
        _dbService.getAllEmployees(),
        _dbService.getShiftsByDateRange(startStr, endStr),
        _dbService.getAttendanceByDateRange(startStr, endStr),
        _dbService.getApprovedLeaves() // Pastikan service udah bener (pake 's')
      ]);

      List<UserModel> employees = results[0] as List<UserModel>;
      QuerySnapshot scheduleSnap = results[1] as QuerySnapshot;
      QuerySnapshot attendanceSnap = results[2] as QuerySnapshot;
      QuerySnapshot leaveSnap = results[3] as QuerySnapshot;

      // 2. MAPPING DATA
      Map<String, Map<String, dynamic>> finalMap = {};

      // Inisialisasi Map User
      for (var emp in employees) {
        finalMap[emp.uid] = {};
      }

      // A. JADWAL
      for (var doc in scheduleSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String uid = data['uid'];
        String date = data['date'];
        if (finalMap.containsKey(uid)) {
          finalMap[uid]![date] = {
            'type': 'schedule', 
            'value': data['shiftId'], 
            'shift': data['shiftId']
          };
        }
      }

      // B. DATA IZIN (Logic Timezone Fix & Multi-day)
      for (var doc in leaveSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String uid = data['uid'] ?? data['userId'];
        
        if (finalMap.containsKey(uid)) {
          Timestamp? startTs = data['startDate'];
          Timestamp? endTs = data['endDate'];

          if (startTs != null && endTs != null) {
            // Fix Timezone Indonesia
            DateTime leaveStart = startTs.toDate().toLocal();
            DateTime leaveEnd = endTs.toDate().toLocal();

            // Reset Jam ke 00:00
            leaveStart = DateTime(leaveStart.year, leaveStart.month, leaveStart.day);
            leaveEnd = DateTime(leaveEnd.year, leaveEnd.month, leaveEnd.day);

            int daysDiff = leaveEnd.difference(leaveStart).inDays;
            if (daysDiff < 0) daysDiff = 0;

            // Loop Durasi Izin
            for (int i = 0; i <= daysDiff; i++) {
               DateTime currentLeaveDate = leaveStart.add(Duration(days: i));
               String dateKey = DateFormat('yyyy-MM-dd').format(currentLeaveDate);
               
               // Cek Range Laporan
               if (dateKey.compareTo(startStr) >= 0 && dateKey.compareTo(endStr) <= 0) {
                  finalMap[uid]![dateKey] = {
                    'type': 'permission', 
                    'value': data['type'] ?? 'Izin', 
                    'reason': data['reason'] ?? '-'
                  };
               }
            }
          }
        }
      }

      // C. ABSENSI (Menimpa Izin jika Hadir)
      for (var doc in attendanceSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String uid = data['uid'] ?? data['userId']; 
        String date = data['date'];
        
        if (finalMap.containsKey(uid)) {
          String shiftName = data['shiftName'] ?? data['shiftId'] ?? '';
          
          // Fallback shift name dari jadwal jika kosong
          if (shiftName.isEmpty && finalMap[uid]![date] != null) {
             if (finalMap[uid]![date]!['type'] != 'permission') {
                shiftName = finalMap[uid]![date]!['shift'] ?? '';
             }
          }

          String checkIn = "-";
          if (data['checkInTime'] != null) {
            DateTime t = (data['checkInTime'] as Timestamp).toDate();
            checkIn = DateFormat('HH:mm').format(t);
          }
          String checkOut = "-";
          if (data['checkOutTime'] != null) {
            DateTime t = (data['checkOutTime'] as Timestamp).toDate();
            checkOut = DateFormat('HH:mm').format(t);
          }
          
          finalMap[uid]![date] = {
            'type': 'attendance', 
            'in': checkIn, 
            'out': checkOut, 
            'status': data['status'] ?? 'Hadir', 
            'shift': shiftName
          };
        }
      }

      // Tutup Loading
      if (Get.isDialogOpen ?? false) Get.back(); 
      
      // Export Excel
      await _excelService.exportAttendanceSplit(fileName, employees, finalMap, start, end);

      Get.snackbar("Berhasil", "Laporan siap! 📂", backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      // Catch Minimalis (Cuma tutup loading & kasih notif biar user ga bingung)
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Gagal", "Terjadi kesalahan: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isExporting.value = false;
    }
  }
}