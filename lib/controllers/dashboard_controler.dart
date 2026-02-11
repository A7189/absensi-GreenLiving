import 'dart:async';
import 'package:absensi_greenliving/controllers/attedance_controler.dart';
import 'package:absensi_greenliving/models/shift_models.dart'; 
import 'package:absensi_greenliving/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DashboardController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();

  // 🔥 DATA VISUAL DASHBOARD (FITUR LAMA - AMAN)
  var weeklyStatus = <String>['pending', 'pending', 'pending', 'pending', 'pending', 'pending', 'pending'].obs;
  var presencePercentage = 0.0.obs;
  var totalPresentMonth = 0.obs;
  var cutiCount = 0.obs;

  // 🔥 [NEW] VARIABLE BUAT LOCK SYSTEM & STATUS TEKS (INI YANG TADINYA ERROR)
  var bufferMinutes = 60.obs; // Default 1 jam
  var isTimeLocked = true.obs; 
  var shiftStatusTitle = "Memuat...".obs; 
  var shiftStatusSubtitle = "Tunggu sebentar...".obs; 
  var isTodayHoliday = false.obs;

  // Logic Lingkaran Jam Kerja
  var remainingShiftHours = "00:00".obs; 
  var shiftProgress = 1.0.obs; 
  Timer? _timer; 

  @override
  void onInit() {
    super.onInit();
    // Ambil setting dulu, baru load data
    fetchSettings().then((_) => loadDashboardData());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // --- FUNGSI REFRESH ---
  Future<void> refreshData() async {
    await fetchSettings();
    await loadDashboardData();
    if (Get.isRegistered<AttendanceController>()) {
      await Get.find<AttendanceController>().checkDailyStatus();
    }
  }

  // 🔥 AMBIL SETTING BUFFER DARI DB
  Future<void> fetchSettings() async {
    int buffer = await _dbService.getAttendanceBuffer();
    bufferMinutes.value = buffer;
  }

  // --- FUNGSI UTAMA: TARIK DATA DASHBOARD ---
  Future<void> loadDashboardData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // ... (Code History Mingguan & Statistik - TETAP SAMA TIDAK DISENTUH) ...
    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day); 
    DateTime startOfWeek = todayStart.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

    try {
      // 1. Ambil History Mingguan
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

      // 4. Hitung Statistik Bulanan
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

      // 🔥 6. UPDATE STATUS LIBUR & TIMER (LOGIC UTAMA)
      ShiftModel? todayShift = await _dbService.getTodayShift(uid);
      
      if (todayShift != null) {
        // ADA JADWAL
        isTodayHoliday.value = false; 
        
        // Ambil nama shift (Pagi/Siang/Malam) untuk judul
        String shiftName = (todayShift.type).capitalizeFirst ?? "Regular";

        _startRealShiftTimer(todayShift.startTime, todayShift.endTime, shiftName);
      } else {
        // LIBUR -> Tombol Terkunci
        isTodayHoliday.value = true; 
        isTimeLocked.value = true;
        
        // Update Teks Status biar gak error
        shiftStatusTitle.value = "Hari Ini Libur";
        shiftStatusSubtitle.value = "Tidak ada jadwal shift hari ini.";
        
        remainingShiftHours.value = "Libur";
        shiftProgress.value = 0.0;
        _timer?.cancel();
      }

    } catch (e) {
      print("Error dashboard: $e");
    }
  }

  // 🔥 CORE LOGIC TIMER (DITAMBAH PARAMETER SHIFT NAME)
  void _startRealShiftTimer(DateTime start, DateTime end, String shiftName) {
    _timer?.cancel(); 
    _updateTimerTick(start, end, shiftName); // Update lsg biar gak nunggu
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimerTick(start, end, shiftName);
    });
  }

  void _updateTimerTick(DateTime start, DateTime end, String shiftName) {
    DateTime now = DateTime.now();

    // 🔥 LOGIC BARU: CEK APAKAH SUDAH MASUK WAKTU BUFFER (H-1 JAM)
    DateTime unlockTime = start.subtract(Duration(minutes: bufferMinutes.value));

    if (now.isBefore(unlockTime)) {
      // --- BELUM WAKTUNYA (TERKUNCI) ---
      isTimeLocked.value = true;
      shiftStatusTitle.value = "Shift $shiftName";
      shiftStatusSubtitle.value = "Absen dibuka pukul ${DateFormat('HH:mm').format(unlockTime)}";
    } else {
      // --- SUDAH DIBUKA ---
      isTimeLocked.value = false;
      shiftStatusTitle.value = "Shift $shiftName"; 
      shiftStatusSubtitle.value = "Silakan tap tombol untuk absen"; 
    }

    // --- LOGIC LAMA: LINGKARAN JAM KERJA ---
    
    // KASUS 1: BELUM MULAI SHIFT
    if (now.isBefore(start)) {
      Duration wait = start.difference(now);
      remainingShiftHours.value = _formatDuration(wait); 
      shiftProgress.value = 1.0; 
      return;
    }

    // KASUS 2: SUDAH SELESAI SHIFT
    if (now.isAfter(end)) {
      remainingShiftHours.value = "Selesai";
      shiftProgress.value = 0.0; 
      _timer?.cancel();
      return;
    }

    // KASUS 3: SEDANG BEKERJA (TIMER MUNDUR)
    Duration remaining = end.difference(now);
    Duration totalShift = end.difference(start);

    remainingShiftHours.value = _formatDuration(remaining);

    double progress = remaining.inSeconds / totalShift.inSeconds;
    shiftProgress.value = progress.clamp(0.0, 1.0);
  }

  String _formatDuration(Duration d) {
    String h = d.inHours.toString().padLeft(2, "0");
    String m = d.inMinutes.remainder(60).toString().padLeft(2, "0");
    return "$h:$m";
  }
}