import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminLiveMonitoringController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = true.obs;
  
  var pagiList = <Map<String, dynamic>>[].obs;
  var siangList = <Map<String, dynamic>>[].obs;
  var malamList = <Map<String, dynamic>>[].obs;

  // 🔥 VARIABLE PENAMPUNG CONFIG SHIFT (Dari DB)
  var shiftConfigs = <String, Map<String, dynamic>>{};

  @override
  void onInit() {
    super.onInit();
    loadLiveMonitor();
  }

  void loadLiveMonitor() async {
    try {
      isLoading.value = true;
      pagiList.clear();
      siangList.clear();
      malamList.clear();
      shiftConfigs.clear(); // Reset config

      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 1. 🔥 LOAD CONFIG SHIFT DULU (PENTING!)
      var shiftsSnapshot = await _firestore.collection('shifts').get();
      for (var doc in shiftsSnapshot.docs) {
        shiftConfigs[doc.id.toLowerCase()] = doc.data();
      }

      // 2. LOAD DATA LAINNYA
      var usersSnapshot = await _firestore.collection('users').get();
      
      var scheduleSnapshot = await _firestore
          .collection('shift_schedule') 
          .where('date', isEqualTo: todayDate)
          .get();

      var logSnapshot = await _firestore
          .collection('attendance_logs')
          .where('date', isEqualTo: todayDate)
          .get();

      // 3. JAHIT DATA
      for (var userDoc in usersSnapshot.docs) {
        String uid = userDoc.id;
        var userData = userDoc.data();
        String name = userData['name'] ?? 'Tanpa Nama';
        String role = userData['role'] ?? 'user';

        if (role == 'admin') continue;

        // --- A. CEK ABSENSI ---
        var logDoc = logSnapshot.docs.firstWhereOrNull((doc) => doc['uid'] == uid);
        bool hasCheckedIn = logDoc != null;
        String checkInTimeStr = "-";
        DateTime? checkInDate;

        if (hasCheckedIn) {
          Timestamp? ts = logDoc['checkInTime'];
          if (ts != null) {
            checkInDate = ts.toDate();
            checkInTimeStr = DateFormat('HH:mm').format(checkInDate);
          }
        }

        // --- B. CEK JADWAL DATABASE ---
        var scheduleDoc = scheduleSnapshot.docs.firstWhereOrNull((doc) => doc['uid'] == uid);
        String shiftId = scheduleDoc != null ? (scheduleDoc['shiftId'] ?? '') : '';

        // --- C. LOGIC PENENTUAN SHIFT (DINAMIS DARI DB) ---
        String finalShift = 'Libur';
        Map<String, dynamic>? activeConfig;

        // PRIORITAS 1: IKUT JADWAL DB
        if (shiftId.isNotEmpty && shiftConfigs.containsKey(shiftId.toLowerCase())) {
          String key = shiftId.toLowerCase();
          if (key.contains('pagi')) finalShift = 'Pagi';
          else if (key.contains('siang')) finalShift = 'Siang';
          else if (key.contains('malam')) finalShift = 'Malam';
          
          activeConfig = shiftConfigs[key];
        } 
        // PRIORITAS 2: KALAU JADWAL KOSONG TAPI HADIR -> CARI SHIFT TERDEKAT
        else if (hasCheckedIn && checkInDate != null) {
          finalShift = _findClosestShift(checkInDate);
          activeConfig = shiftConfigs[finalShift.toLowerCase()];
        }

        // --- D. LOGIC STATUS (TERLAMBAT/TEPAT) PAKAI TOLERANSI DB ---
        String statusLabel = "Belum Hadir";
        String statusColor = "grey";

        if (hasCheckedIn && checkInDate != null && activeConfig != null) {
          // Ambil Jam Mulai dari Config (Format DB: "08.00" atau "22.00")
          String startStr = activeConfig['startTime'] ?? "00.00"; 
          // Ambil Toleransi (Default 10 menit kalo null)
          int tolerance = activeConfig['Tolerance'] ?? 10; 

          // Parsing Jam Mulai shift hari ini
          DateTime now = DateTime.now();
          List<String> parts = startStr.replaceAll('.', ':').split(':');
          int startH = int.parse(parts[0]);
          int startM = int.parse(parts[1]);

          DateTime shiftStart = DateTime(now.year, now.month, now.day, startH, startM);

          // Handle Shift Malam (Start 22.00, Absen 01.00 besoknya)
          // Kalau jam absen < jam 12 siang & jam mulai shift > 18 sore, berarti absennya besok
          if (checkInDate.hour < 12 && startH > 18) {
             // Shift startnya kemarin malem (tapi logic monitoring harian biasanya per tanggal)
             // Kita anggap shift startnya jam 22.00 hari ini
          }

          // Hitung Selisih Menit
          int diffMinutes = checkInDate.difference(shiftStart).inMinutes;

          if (diffMinutes > tolerance) {
            statusLabel = "Terlambat (${diffMinutes}m)"; // Lewat toleransi
            statusColor = "red";
          } else if (diffMinutes < -30) {
            statusLabel = "Awal";
            statusColor = "blue";
          } else {
            statusLabel = "Tepat Waktu";
            statusColor = "green";
          }
        } else if (hasCheckedIn) {
          // Fallback kalau config gak ketemu
          statusLabel = "Hadir";
          statusColor = "green";
        }

        Map<String, dynamic> employeeData = {
          'name': name,
          'checkInTime': checkInTimeStr,
          'statusLabel': statusLabel,
          'statusColor': statusColor,
          'isPresent': hasCheckedIn,
          'uid': uid,
        };

        if (finalShift == 'Pagi') pagiList.add(employeeData);
        else if (finalShift == 'Siang') siangList.add(employeeData);
        else if (finalShift == 'Malam') malamList.add(employeeData);
      }

    } catch (e) {
      print("Error Live Monitor: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 🔥 HELPER: CARI SHIFT YANG JAM MULAINYA PALING DEKET SAMA JAM ABSEN
  String _findClosestShift(DateTime checkInTime) {
    String closestShift = 'Pagi';
    int minDiff = 9999;

    shiftConfigs.forEach((key, config) {
      String startStr = config['startTime'] ?? "00.00";
      List<String> parts = startStr.replaceAll('.', ':').split(':');
      int startH = int.parse(parts[0]);

      // Hitung jarak jam (Absolute)
      // Misal Pagi(8), Siang(14). Absen jam 10.
      // Jarak ke Pagi = 2, Jarak ke Siang = 4. Menang Pagi.
      int diff = (checkInTime.hour - startH).abs();
      
      // Handle wrap around tengah malam (Jam 22 vs Jam 01 = jarak 3 jam)
      if (diff > 12) diff = 24 - diff; 

      if (diff < minDiff) {
        minDiff = diff;
        if (key.contains('pagi')) closestShift = 'Pagi';
        else if (key.contains('siang')) closestShift = 'Siang';
        else if (key.contains('malam')) closestShift = 'Malam';
      }
    });

    return closestShift;
  }
}