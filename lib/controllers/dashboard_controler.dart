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

  var weeklyStatus = <String>['pending', 'pending', 'pending', 'pending', 'pending', 'pending', 'pending'].obs;
  var presencePercentage = 0.0.obs;
  var totalPresentMonth = 0.obs;
  var cutiCount = 0.obs;

  var bufferMinutes = 60.obs; 
  var isTimeLocked = true.obs; 
  var shiftStatusTitle = "Memuat...".obs; 
  var shiftStatusSubtitle = "Tunggu sebentar...".obs; 
  var isTodayHoliday = false.obs;

  // Logic Lingkaran Jam Kerja (Countdown Sejak Absen)
  var remainingShiftHours = "00:00".obs; 
  var shiftProgress = 1.0.obs; 
  Timer? _timer; 

  @override
  void onInit() {
    super.onInit();
    fetchSettings().then((_) => loadDashboardData());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> refreshData() async {
    await fetchSettings();
    await loadDashboardData();
    if (Get.isRegistered<AttendanceController>()) {
      await Get.find<AttendanceController>().checkDailyStatus();
    }
  }

  Future<void> fetchSettings() async {
    int buffer = await _dbService.getAttendanceBuffer();
    bufferMinutes.value = buffer;
  }

  Future<void> loadDashboardData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day); 
    DateTime startOfWeek = todayStart.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

    try {
      QuerySnapshot snapshot = await _firestore.collection('attendance_logs')
          .where('uid', isEqualTo: uid)
          .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(startOfWeek))
          .where('date', isLessThan: DateFormat('yyyy-MM-dd').format(endOfWeek))
          .get();

      List<String> tempStatus = List.filled(7, 'pending');
      for (var doc in snapshot.docs) {
        String dateString = doc['date']; 
        DateTime logDate = DateTime.parse(dateString);
        int dayIndex = logDate.weekday - 1; 
        if (dayIndex >= 0 && dayIndex < 7) tempStatus[dayIndex] = 'done'; 
      }

      for (int i = 0; i < 7; i++) {
        DateTime checkDate = startOfWeek.add(Duration(days: i));
        if (tempStatus[i] == 'pending' && checkDate.isBefore(todayStart)) tempStatus[i] = 'absent'; 
      }
      weeklyStatus.value = tempStatus;

      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      AggregateQuerySnapshot countTask = await _firestore.collection('attendance_logs')
          .where('uid', isEqualTo: uid)
          .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(startOfMonth))
          .count()
          .get();
      
      totalPresentMonth.value = countTask.count ?? 0;
      presencePercentage.value = (totalPresentMonth.value / 23).clamp(0.0, 1.0);

      cutiCount.value = await _dbService.getUserApprovedLeaveDays(uid);

      ShiftModel? todayShift = await _dbService.getTodayShift(uid);
      
      if (todayShift != null) {
        isTodayHoliday.value = false; 
        String shiftName = (todayShift.type).capitalizeFirst ?? "Regular";
        DateTime? dbCheckIn = await _dbService.fetchTodayCheckInTime(uid);
        
        _startAttendanceTimer(todayShift, dbCheckIn, shiftName);
      } else {
        isTodayHoliday.value = true; 
        isTimeLocked.value = true;
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

  void _startAttendanceTimer(ShiftModel shift, DateTime? checkIn, String shiftName) {
    _timer?.cancel(); 
    _updateAttendanceTick(shift, checkIn, shiftName);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateAttendanceTick(shift, checkIn, shiftName);
    });
  }

  void _updateAttendanceTick(ShiftModel shift, DateTime? checkIn, String shiftName) {
    DateTime now = DateTime.now();

    // --- LOGIC LOCK BUTTON ---
    DateTime unlockTime = shift.startTime.subtract(Duration(minutes: bufferMinutes.value));
    if (now.isBefore(unlockTime)) {
      isTimeLocked.value = true;
      shiftStatusTitle.value = "Shift $shiftName";
      shiftStatusSubtitle.value = "Absen dibuka pukul ${DateFormat('HH:mm').format(unlockTime)}";
    } else {
      isTimeLocked.value = false;
      shiftStatusTitle.value = "Shift $shiftName"; 
      shiftStatusSubtitle.value = "Silakan tap tombol untuk absen"; 
    }

    // --- 🔥 LOGIC TIMER MUNDUR (COUNTDOWN) ---
    DateTime? activeCheckIn = checkIn;
    if (Get.isRegistered<AttendanceController>()) {
      var att = Get.find<AttendanceController>();
      if (att.currentStatus.value == 'checkIn' || att.currentStatus.value == 'checkOut') {
        activeCheckIn = att.checkInTime ?? checkIn;
      }
    }

    // Durasi shift yang seharusnya ditempuh (misal 8 jam)
    Duration totalShiftDuration = shift.endTime.difference(shift.startTime);

    if (activeCheckIn == null) {
      // KASUS 1: BELUM ABSEN -> Tampilkan durasi kerja yang harus dilakukan
      remainingShiftHours.value = _formatDuration(totalShiftDuration);
      shiftProgress.value = 1.0; 
    } else {
      // KASUS 2: SUDAH ABSEN -> TIMER MUNDUR
      // Target Pulang = Waktu Absen + Durasi Shift
      DateTime targetPulang = activeCheckIn.add(totalShiftDuration);

      if (now.isAfter(targetPulang)) {
        // SUDAH LEWAT TARGET PULANG
        remainingShiftHours.value = "Selesai";
        shiftProgress.value = 0.0;
        
        // Stop timer kalau sudah checkout
        if (Get.isRegistered<AttendanceController>() && Get.find<AttendanceController>().currentStatus.value == 'checkOut') {
          _timer?.cancel();
        }
      } else {
        // SEDANG BERJALAN (COUNTDOWN)
        Duration remaining = targetPulang.difference(now);
        remainingShiftHours.value = _formatDuration(remaining);

        // Lingkaran semakin berkurang
        double progress = remaining.inSeconds / totalShiftDuration.inSeconds;
        shiftProgress.value = progress.clamp(0.0, 1.0);
      }
    }
  }

  String _formatDuration(Duration d) {
    String h = d.inHours.toString().padLeft(2, "0");
    String m = d.inMinutes.remainder(60).toString().padLeft(2, "0");
    return "$h:$m";
  }
}