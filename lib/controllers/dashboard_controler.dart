import 'dart:async';
import 'package:absensi_greenliving/controllers/attedance_controler.dart';
import 'package:absensi_greenliving/models/shift_models.dart'; // 🔥 Import Model Shift
import 'package:absensi_greenliving/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DashboardController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();

  // 🔥 DATA VISUAL DASHBOARD (TETAP SAMA)
  var weeklyStatus = <String>['pending', 'pending', 'pending', 'pending', 'pending', 'pending', 'pending'].obs;
  var presencePercentage = 0.0.obs;
  var totalPresentMonth = 0.obs;
  var cutiCount = 0.obs;

  // Logic Lingkaran Jam Kerja
  var remainingShiftHours = "00:00".obs; // Format Jam:Menit
  var shiftProgress = 1.0.obs; 
  Timer? _timer; 

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // --- FUNGSI REFRESH (Buat Pull-to-Refresh) ---
  Future<void> refreshData() async {
    await loadDashboardData();
    if (Get.isRegistered<AttendanceController>()) {
      await Get.find<AttendanceController>().checkDailyStatus();
    }
  }

  // --- FUNGSI UTAMA: TARIK DATA DASHBOARD ---
  Future<void> loadDashboardData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day); 
    DateTime startOfWeek = todayStart.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

    try {
      // 1. Ambil History Mingguan (TETAP SAMA)
      QuerySnapshot snapshot = await _firestore.collection('attendance_logs')
          .where('uid', isEqualTo: uid)
          .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(startOfWeek))
          .where('date', isLessThan: DateFormat('yyyy-MM-dd').format(endOfWeek))
          .get();

      List<String> tempStatus = List.filled(7, 'pending');

      // 2. Isi Hijau (Done)
      for (var doc in snapshot.docs) {
        String dateString = doc['date']; 
        DateTime logDate = DateTime.parse(dateString);
        int dayIndex = logDate.weekday - 1; 
        if (dayIndex >= 0 && dayIndex < 7) {
          tempStatus[dayIndex] = 'done'; 
        }
      }

      // 3. Isi Merah (Absent)
      for (int i = 0; i < 7; i++) {
        DateTime checkDate = startOfWeek.add(Duration(days: i));
        if (tempStatus[i] == 'pending' && checkDate.isBefore(todayStart)) {
          tempStatus[i] = 'absent'; 
        }
      }
      weeklyStatus.value = tempStatus;

      // 4. Hitung Statistik Bulanan (TETAP SAMA)
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      AggregateQuerySnapshot countTask = await _firestore.collection('attendance_logs')
          .where('uid', isEqualTo: uid)
          .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(startOfMonth))
          .count()
          .get();
      
      totalPresentMonth.value = countTask.count ?? 0;
      presencePercentage.value = (totalPresentMonth.value / 23).clamp(0.0, 1.0);

      // 5. Data Cuti
      int totalCuti = await _dbService.getUserApprovedLeaveDays(uid);
      cutiCount.value = totalCuti;

   
      ShiftModel? todayShift = await _dbService.getTodayShift(uid);
      
      if (todayShift != null) {
        _startRealShiftTimer(todayShift.startTime, todayShift.endTime);
      } else {
        // Kalau Libur / Gak ada shift
        remainingShiftHours.value = "Libur";
        shiftProgress.value = 0.0;
        _timer?.cancel();
      }

    } catch (e) {
      print("Error dashboard: $e");
    }
  }

  // 🔥 CORE LOGIC TIMER (MENGHITUNG MUNDUR DARI DATA SHIFT ASLI)
  void _startRealShiftTimer(DateTime start, DateTime end) {
    _timer?.cancel(); // Matikan timer lama biar gak numpuk

    // Update pertama kali langsung (biar gak nunggu 1 detik)
    _updateTimerTick(start, end);

    // Jalanin Timer Tiap Detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimerTick(start, end);
    });
  }

  void _updateTimerTick(DateTime start, DateTime end) {
    DateTime now = DateTime.now();

    // KASUS 1: BELUM MULAI SHIFT
    if (now.isBefore(start)) {
      Duration wait = start.difference(now);
      // Tampilkan "08:00" atau hitung mundur menuju masuk
      remainingShiftHours.value = _formatDuration(wait); 
      shiftProgress.value = 1.0; // Masih penuh
      return;
    }

    // KASUS 2: SUDAH SELESAI SHIFT
    if (now.isAfter(end)) {
      remainingShiftHours.value = "Selesai";
      shiftProgress.value = 0.0; // Habis
      _timer?.cancel();
      return;
    }

    // KASUS 3: SEDANG BEKERJA (TIMER MUNDUR)
    Duration remaining = end.difference(now);
    Duration totalShift = end.difference(start);

    // Format HH:mm
    remainingShiftHours.value = _formatDuration(remaining);

    // Hitung Progress Lingkaran
    // 1.0 (Penuh) -> 0.0 (Kosong)
    double progress = remaining.inSeconds / totalShift.inSeconds;
    shiftProgress.value = progress.clamp(0.0, 1.0);
  }

  // Helper Format Jam:Menit (Contoh: 04:30)
  String _formatDuration(Duration d) {
    String h = d.inHours.toString().padLeft(2, "0");
    String m = d.inMinutes.remainder(60).toString().padLeft(2, "0");
    // String s = d.inSeconds.remainder(60).toString().padLeft(2, "0"); // Detik opsional
    return "$h:$m";
  }
}