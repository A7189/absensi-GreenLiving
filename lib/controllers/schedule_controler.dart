import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ScheduleController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = true.obs;
  var weeklyShifts = <Map<String, dynamic>>[].obs;
  
  // 🔥 Variabel buat nyimpen Kamus Shift (Master Data)
  var masterShifts = <String, Map<String, dynamic>>{};

  @override
  void onInit() {
    super.onInit();
    loadMySchedule();
  }

  void loadMySchedule() async {
    User? user = _auth.currentUser;
    if (user == null) {
      Get.offAllNamed('/login');
      return;
    }

    try {
      isLoading.value = true;
      
      // 1. 🔥 BACA KAMUS DULU (Collection 'shifts')
      // Biar kita tau 'pagi' itu jam berapa, 'Malam' jam berapa.
      await _loadMasterShifts();

      List<Map<String, dynamic>> tempData = []; 
      DateTime now = DateTime.now();
      
      // 2. LOOPING 7 HARI KE DEPAN
      for (int i = 0; i < 7; i++) {
        DateTime targetDate = now.add(Duration(days: i));
        String dateString = DateFormat('yyyy-MM-dd').format(targetDate);

        // 3. AMBIL JADWAL HARIAN (Collection 'schedules' atau 'shift_schedule')
        // Pastikan nama collection ini sesuai sama tempat Ndan simpen tanggal
        QuerySnapshot snapshot = await _firestore
            .collection('shift_schedule') 
            .where('uid', isEqualTo: user.uid)
            .where('date', isEqualTo: dateString)
            .limit(1)
            .get();

        Map<String, dynamic>? shiftData;

        if (snapshot.docs.isNotEmpty) {
          var data = snapshot.docs.first.data() as Map<String, dynamic>;
          String shiftId = data['shiftId'] ?? 'libur'; // Contoh: "pagi" atau "Malam"
          
          // 4. 🔥 COCOKKAN DENGAN KAMUS
          // Kita cari detail jamnya di variabel masterShifts
          var masterDetail = masterShifts[shiftId]; 
          
          // Handle Case Sensitive (Jaga-jaga 'pagi' vs 'Pagi')
          if (masterDetail == null) {
             masterDetail = masterShifts[shiftId.toLowerCase()] ?? masterShifts[shiftId.capitalizeFirst];
          }

          if (masterDetail != null) {
            // ✅ KETEMU DI KAMUS!
            // Format DB Ndan pake titik "08.00", kita ubah ke titik dua "08:00" biar rapi
            String start = (masterDetail['startTime'] ?? '--:--').toString().replaceAll('.', ':');
            String end = (masterDetail['endTime'] ?? '--:--').toString().replaceAll('.', ':');

            shiftData = {
              'shiftName': shiftId.toUpperCase(), // Tampilkan nama shift
              'startTime': start, 
              'endTime': end,    
              'status': 'Terjadwal',
              'color': _getColorByShift(shiftId), // Kasih warna manual dikit biar cantik
            };
          } else {
            // Kalau di jadwal ada, tapi di kamus gak ada (Aneh sih, tapi handle aja)
            shiftData = {
              'shiftName': shiftId,
              'startTime': '--:--', 
              'endTime': '--:--',
              'status': 'Error Config',
              'color': 0xFF9E9E9E,
            };
          }
        }

        tempData.add({
          'date': targetDate,
          'hasShift': shiftData != null,
          'shift': shiftData, 
        });
      }

      weeklyShifts.assignAll(tempData);

    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 🔥 FUNGSI BACA KAMUS 'shifts'
  Future<void> _loadMasterShifts() async {
    try {
      var snapshot = await _firestore.collection('shifts').get(); // <--- Sesuai SS image_a62742.png
      masterShifts.clear();
      
      for (var doc in snapshot.docs) {
        // Simpan dengan Key ID Dokumen (Misal: 'Malam', 'Siang', 'pagi')
        masterShifts[doc.id] = doc.data(); 
        
        // Simpan versi lowercase juga buat jaga-jaga typo
        masterShifts[doc.id.toLowerCase()] = doc.data();
      }
      print("✅ Master Shift Loaded: ${masterShifts.keys}");
    } catch (e) {
      print("❌ Gagal load master shift: $e");
    }
  }

  // Helper Warna (Opsional, biar UI tetep warna-warni)
  int _getColorByShift(String shiftId) {
    String s = shiftId.toLowerCase();
    if (s.contains('pagi')) return 0xFF1B5E20; // Hijau
    if (s.contains('siang')) return 0xFFF57C00; // Orange
    if (s.contains('malam')) return 0xFF1565C0; // Biru
    return 0xFF9E9E9E; // Abu
  }
}