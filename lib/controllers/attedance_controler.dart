import 'dart:async';
import 'package:absensi_greenliving/controllers/dashboard_controler.dart';
import 'package:absensi_greenliving/models/shift_models.dart'; // 🔥 IMPORT MODEL
import 'package:absensi_greenliving/models/user_models.dart';
import 'package:absensi_greenliving/services/database_service.dart';
import 'package:absensi_greenliving/services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendanceController extends GetxController {
  final DatabaseService _dbService = DatabaseService();
  final LocationService _locationService = LocationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Variables
  var officeLat = 0.0.obs;
  var officeLng = 0.0.obs;
  var radiusMeters = 50.0.obs;
  var isWithinRadius = false.obs;
  var currentDistance = 0.0.obs;
  var isLoading = false.obs;

  // Status Logic
  var currentStatus = 'pending'.obs; 
  String? currentDocId; 
  DateTime? checkInTime; 

  StreamSubscription<Position>? _positionStream;

  @override
  void onInit() {
    super.onInit();
    _initSystem();
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        checkDailyStatus();
      }
    });
  }

  Future<void> _initSystem() async {
    try {
      final config = await _dbService.getOfficeConfig();
      if (config != null) {
        officeLat.value = (config['officeLat'] as num).toDouble();
        officeLng.value = (config['officeLng'] as num).toDouble();
        radiusMeters.value = (config['radius'] as num).toDouble();
      }
    } catch (e) { print("Config error: $e"); }
    _startLocationTracking();
  }

  // --- CEK STATUS HARIAN DARI DB ---
  Future<void> checkDailyStatus() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      DateTime now = DateTime.now();
      String todayDocId = DateFormat('yyyy-MM-dd').format(now);

      QuerySnapshot snapshot = await _firestore.collection('attendance_logs')
          .where('uid', isEqualTo: uid)
          .where('date', isEqualTo: todayDocId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data() as Map<String, dynamic>;
        currentDocId = snapshot.docs.first.id;
        
        if (data['checkInTime'] != null) {
           checkInTime = (data['checkInTime'] as Timestamp).toDate();
        }

        if (data['checkOutTime'] != null || data['checkOut'] != null) {
          currentStatus.value = 'checkOut'; 
        } else {
          currentStatus.value = 'checkIn'; 
        }
      } else {
        currentStatus.value = 'pending';
        currentDocId = null;
      }
    } catch (e) {
      print("❌ Error check status: $e");
    }
  }

  // --- 🔥 CORE LOGIC ABSENSI ---
  Future<void> submitAttendance(UserModel user, ShiftModel? shift) async {
    
    // 1. VALIDASI JADWAL
    if (shift == null) {
       Get.snackbar("Jadwal Kosong", "Hari ini Anda Libur.");
       return;
    }

    if (currentStatus.value == 'checkOut') return; 

    try {
      isLoading.value = true;
      Position position = await _locationService.getCurrentLocation();
      double distance = _locationService.calculateDistance(
        position.latitude, position.longitude, officeLat.value, officeLng.value,
      );
      DateTime now = DateTime.now();

      // 2. VALIDASI LOKASI
      if (distance <= radiusMeters.value) {
        
        // === ABSEN MASUK ===
        if (currentStatus.value == 'pending') {
          
          String statusKehadiran = "Hadir";
          int minutesLate = 0;
          
          // 🔥 AMBIL TOLERANSI DARI DB (ShiftModel)
          int tolerance = shift.toleranceMinutes; 

          DateTime lateLimit = shift.startTime.add(Duration(minutes: tolerance));

          if (now.isAfter(lateLimit)) {
             statusKehadiran = "Terlambat";
             minutesLate = now.difference(shift.startTime).inMinutes;
          }

          DocumentReference docRef = await _firestore.collection('attendance_logs').add({
            'uid': user.uid,
            'date': DateFormat('yyyy-MM-dd').format(now),
            'checkInTime': now, 
            'checkIn': now, 
            'location': GeoPoint(position.latitude, position.longitude),
            'lat': position.latitude, 'lng': position.longitude,
            
            // Simpan Data Shift
            'shiftId': shift.type, 
            'shiftName': shift.type,
            'shiftStart': DateFormat('HH:mm').format(shift.startTime), 
            'shiftEnd': DateFormat('HH:mm').format(shift.endTime),
            
            // Simpan info toleransi
            'appliedTolerance': tolerance,
            
            'status': statusKehadiran, 
            'lateMinutes': minutesLate,  
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          currentDocId = docRef.id;
          currentStatus.value = 'checkIn'; 
          checkInTime = now; 
          
          _notifyDashboard();
          
          if (statusKehadiran == "Terlambat") {
             Get.snackbar("Terlambat", "Batas toleransi $tolerance menit. Anda telat $minutesLate menit.");
          } else {
             Get.snackbar("Sukses", "Absen Masuk (${shift.type}) Berhasil");
          }
        } 
        
        // === ABSEN PULANG ===
        else if (currentStatus.value == 'checkIn') {
          
          // 🔥 PERINGATAN PULANG CEPAT (EARLY LEAVE WARNING)
          if (now.isBefore(shift.endTime)) {
             Duration sisa = shift.endTime.difference(now);
             
             // Dialog Konfirmasi
             bool? confirm = await Get.defaultDialog(
               title: "Pulang Lebih Awal?",
               titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
               middleText: "Shift berakhir ${sisa.inHours} Jam ${sisa.inMinutes % 60} Menit lagi.\nYakin mau pulang sekarang?",
               textConfirm: "Ya, Pulang",
               textCancel: "Batal",
               confirmTextColor: Colors.white,
               buttonColor: Colors.orange,
               onConfirm: () => Get.back(result: true),
               onCancel: () => Get.back(result: false)
             );

             if (confirm != true) { 
               isLoading.value = false; 
               return; // Batal Absen
             }
          }

          if (currentDocId != null) {
            await _firestore.collection('attendance_logs').doc(currentDocId).update({
              'checkOutTime': now,
              'checkOut': now,
              'checkOutLocation': GeoPoint(position.latitude, position.longitude),
            });
            currentStatus.value = 'checkOut'; 
            _notifyDashboard();
            Get.snackbar("Selesai", "Hati-hati di jalan");
            
            // Refresh Dashboard biar Timer berhenti
            if (Get.isRegistered<DashboardController>()) {
               Get.find<DashboardController>().refreshData();
            }
          } else {
             await checkDailyStatus(); 
             Get.snackbar("Info", "Data sinkronisasi ulang, coba tekan sekali lagi.");
          }
        }
      } else {
        Get.snackbar("Gagal", "Posisi Anda terlalu jauh: ${distance.toStringAsFixed(1)}m");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void _notifyDashboard() {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadDashboardData();
    }
  }

  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream().listen((p) {
        if (officeLat.value == 0.0) return;
        double d = _locationService.calculateDistance(p.latitude, p.longitude, officeLat.value, officeLng.value);
        currentDistance.value = d; isWithinRadius.value = d <= radiusMeters.value;
    });
  }
  
  @override void onClose() { _positionStream?.cancel(); super.onClose(); }
}