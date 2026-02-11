import 'package:absensi_greenliving/models/user_models.dart';
import 'package:absensi_greenliving/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminScheduleController extends GetxController {
  final DatabaseService _db = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; 
  
  // State
  var isLoading = false.obs;
  var isShiftLoading = false.obs;
  
  // Data
  var employees = <UserModel>[].obs; 
  var selectedUser = Rxn<UserModel>(); 
  var currentMonth = DateTime.now().obs;

  // Cache Jadwal (Key: "2026-01-29", Value: "pagi")
  var userShifts = <String, String>{}.obs; 
  
  // Cache Master Shift
  var masterShifts = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchEmployees();
    fetchMasterShifts();
  }

  // --- 1. AMBIL DATA PEGAWAI ---
  void fetchEmployees() async {
    isLoading.value = true;
    try {
      employees.value = await _db.getAllEmployees();
      
      if (employees.isNotEmpty && selectedUser.value == null) {
        selectUser(employees[0]);
      }
    } catch (e) {
      print("Error fetch employees: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- 2. AMBIL MASTER SHIFT ---
  void fetchMasterShifts() async {
    try {
      var snapshot = await _firestore.collection('shifts').get();
      masterShifts.value = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("Error fetch master shifts: $e");
    }
  }

  // --- 3. LOGIC PILIH USER ---
  void selectUser(UserModel user) {
    if (selectedUser.value?.uid == user.uid) return;
    
    userShifts.clear(); 
    selectedUser.value = user; 
    fetchShiftsForSelectedUser(); 
  }

  // --- 4. TARIK JADWAL USER ---
  Future<void> fetchShiftsForSelectedUser() async {
    if (selectedUser.value == null) return;

    try {
      isShiftLoading.value = true;

      String uid = selectedUser.value!.uid;
      DateTime date = currentMonth.value;
      
      // Ambil Range Tanggal (Tgl 1 - Akhir Bulan)
      DateTime start = DateTime(date.year, date.month, 1);
      DateTime end = DateTime(date.year, date.month + 1, 0);
      
      String startStr = DateFormat('yyyy-MM-dd').format(start);
      String endStr = DateFormat('yyyy-MM-dd').format(end);

      var query = await _firestore.collection('shift_schedule')
          .where('uid', isEqualTo: uid)
          .where('date', isGreaterThanOrEqualTo: startStr)
          .where('date', isLessThanOrEqualTo: endStr)
          .get();

      userShifts.clear();

      for (var doc in query.docs) {
        var data = doc.data();
        if (data['shiftId'] != null) {
          userShifts[data['date']] = data['shiftId'];
        }
      }
      userShifts.refresh(); 

    } catch (e) {
      print("Error fetch jadwal: $e");
    } finally {
      isShiftLoading.value = false;
    }
  }

  // --- NAVIGASI BULAN ---
  void changeMonth(int offset) {
    DateTime newDate = DateTime(currentMonth.value.year, currentMonth.value.month + offset);
    currentMonth.value = newDate;
    fetchShiftsForSelectedUser(); 
  }
  
  void setSpecificMonth(DateTime date) {
    currentMonth.value = date;
    fetchShiftsForSelectedUser();
  }

  // --- 5. UPDATE MANUAL SATUAN ---
  void updateSingleShift(DateTime date, String type) async {
    if (selectedUser.value == null) return;
    try {
      String uid = selectedUser.value!.uid;
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      // Update tampilan langsung (Optimistic)
      userShifts[dateStr] = type;
      userShifts.refresh();
      
      DocumentReference docRef = _firestore.collection('shift_schedule').doc("$uid-$dateStr");
      
      if (type == 'Libur') {
         await docRef.delete(); // Kalo libur hapus doc
      } else {
         await docRef.set({
          'uid': uid, 
          'date': dateStr, 
          'shiftId': type, 
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 🔥 [TAMBAHAN AUTO REFRESH] Ambil data terbaru dari DB biar sinkron
      await fetchShiftsForSelectedUser();

    } catch (e) { 
      fetchShiftsForSelectedUser(); // Revert kalo gagal
    }
  }

  // --- 6. GENERATE OTOMATIS (POLA BARU: MALAM-MALAM-SIANG-SIANG-PAGI-PAGI-LIBUR) ---
  void executeGenerate({required String startShiftId, required DateTime startDate}) async {
    if (selectedUser.value == null) return;
    try {
      Get.back(); 
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      
      WriteBatch batch = _firestore.batch();
      String uid = selectedUser.value!.uid;
      
      // 🔥 POLA BARU SESUAI REQUEST
      // Urutan: Malam, Malam, Siang, Siang, Pagi, Pagi, Libur
      // Total siklus: 7 Hari
      List<String> pattern = ['Malam', 'Malam', 'Siang', 'Siang', 'pagi', 'pagi', 'Libur'];
      
      // Tentukan Start Index Berdasarkan Pilihan User
      int startIndex = 0;
      
      // Kalau pilih "Mulai dari Malam", start index 0
      if (startShiftId == 'Malam') startIndex = 0;
      
      // Kalau pilih "Mulai dari Siang", start index 2 (karena Malam-Malam-Siang...)
      if (startShiftId == 'Siang') startIndex = 2;
      
      // Kalau pilih "Mulai dari Pagi", start index 4
      if (startShiftId == 'pagi') startIndex = 4;
      
      // Kalau pilih "Mulai dari Libur", start index 6
      if (startShiftId == 'Libur') startIndex = 6;
      
      int currentPatternIdx = startIndex;

      // Generate buat 30 Hari ke depan
      int durationDays = 30; 

      for (int i = 0; i < durationDays; i++) {
        DateTime date = startDate.add(Duration(days: i));
        String dateStr = DateFormat('yyyy-MM-dd').format(date);
        
        // Ambil Shift ID dari Pola (Looping pake Modulo)
        String shiftId = pattern[currentPatternIdx % pattern.length];
        currentPatternIdx++;
        
        DocumentReference docRef = _firestore.collection('shift_schedule').doc("$uid-$dateStr");
        
        if (shiftId == 'Libur') {
           batch.delete(docRef); 
        } else {
           batch.set(docRef, {
            'uid': uid, 
            'date': dateStr, 
            'shiftId': shiftId, 
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      await batch.commit(); 
      
      if (Get.isDialogOpen ?? false) Get.back(); // Tutup Loading
      
      // Refresh Grid
      await fetchShiftsForSelectedUser(); 
      
      Get.snackbar("Sukses", "Pola (Malam-Siang-Pagi) berhasil dibuat!");
      
    } catch (e) { 
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error", "$e"); 
    }
  }
  
  // --- 7. CONFIG MASTER SHIFT ---
  Future<Map<String, dynamic>> getShiftDetail(String shiftId) async {
      var doc = await _firestore.collection('shifts').doc(shiftId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : {'startTime': '00.00', 'endTime': '00.00', 'Tolerance': 0};
  }
  
  void updateMasterShift(String shiftId, String start, String end, String tolerance) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      int tol = int.tryParse(tolerance) ?? 0; 
      
      await _firestore.collection('shifts').doc(shiftId).update({
        'startTime': start, 
        'endTime': end, 
        'Tolerance': tol 
      });
      
      fetchMasterShifts(); 
      Get.back(); Get.back(); 
      Get.snackbar("Sukses", "Jam kerja $shiftId diperbarui");
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "$e");
    }
  }
}