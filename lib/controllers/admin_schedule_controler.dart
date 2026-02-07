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
      
      // Auto pilih user pertama kalau belum ada yang dipilih
      if (employees.isNotEmpty && selectedUser.value == null) {
        selectUser(employees[0]);
      }
    } catch (e) {
      print("Error fetch employees: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- 2. AMBIL MASTER SHIFT (JAM KERJA) ---
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

  // --- 4. TARIK JADWAL USER TERPILIH ---
  void fetchShiftsForSelectedUser() async {
    if (selectedUser.value == null) return;

    try {
      isShiftLoading.value = true;

      String uid = selectedUser.value!.uid;
      DateTime date = currentMonth.value;
      
      // Hitung Range Tanggal Bulan Ini
      DateTime start = DateTime(date.year, date.month, 1);
      DateTime end = DateTime(date.year, date.month + 1, 0);
      
      String startStr = DateFormat('yyyy-MM-dd').format(start);
      String endStr = DateFormat('yyyy-MM-dd').format(end);

      var query = await _firestore.collection('shift_schedule')
          .where('uid', isEqualTo: uid)
          .where('date', isGreaterThanOrEqualTo: startStr)
          .where('date', isLessThanOrEqualTo: endStr)
          .get();

      // Reset map lokal sebelum diisi ulang untuk bulan yang baru
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

  // --- [NEW] NAVIGASI BULAN ---
  void changeMonth(int offset) {
    DateTime newDate = DateTime(currentMonth.value.year, currentMonth.value.month + offset);
    currentMonth.value = newDate;
    fetchShiftsForSelectedUser(); 
  }
  
  void setSpecificMonth(DateTime date) {
    currentMonth.value = date;
    fetchShiftsForSelectedUser();
  }

  // --- 5. UPDATE MANUAL (KLIK TANGGAL) ---
  void updateSingleShift(DateTime date, String type) async {
    if (selectedUser.value == null) return;
    try {
      String uid = selectedUser.value!.uid;
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      userShifts[dateStr] = type; 
      
      await _firestore.collection('shift_schedule').doc("$uid-$dateStr").set({
        'uid': uid, 
        'date': dateStr, 
        'shiftId': type, 
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) { 
      fetchShiftsForSelectedUser(); 
    }
  }

  // --- 6. GENERATE OTOMATIS (AUTO POLA) [UPDATED] ---
  void executeGenerate({required String startShiftId, required DateTime startDate}) async {
    if (selectedUser.value == null) return;
    try {
      Get.back(); // Tutup dialog
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      
      WriteBatch batch = _firestore.batch();
      String uid = selectedUser.value!.uid;
      
      // Gunakan bulan dari startDate yang dipilih user
      DateTime month = startDate;
      int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      
      // Pola Rotasi: 2-2-2-2
      List<String> pattern = ['pagi', 'pagi', 'Siang', 'Siang', 'Malam', 'Malam', 'Libur', 'Libur'];
      
      int startIndex = 0;
      if (startShiftId == 'Siang') startIndex = 2;
      if (startShiftId == 'Malam') startIndex = 4;
      if (startShiftId == 'Libur') startIndex = 6;
      
      int currentPatternIdx = startIndex;

      // Loop mulai dari Tanggal yang dipilih (startDate.day)
      for (int i = startDate.day; i <= daysInMonth; i++) {
        DateTime date = DateTime(month.year, month.month, i);
        String dateStr = DateFormat('yyyy-MM-dd').format(date);
        
        String shiftId = pattern[currentPatternIdx % pattern.length];
        currentPatternIdx++;
        
        DocumentReference docRef = _firestore.collection('shift_schedule').doc("$uid-$dateStr");
        batch.set(docRef, {
          'uid': uid, 
          'date': dateStr, 
          'shiftId': shiftId, 
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit(); 
      
      Get.back();
      fetchShiftsForSelectedUser(); 
      Get.snackbar("Sukses", "Jadwal berhasil dibuat mulai tgl ${startDate.day}!");
      
    } catch (e) { 
      Get.back(); 
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
      int tol = int.tryParse(tolerance) ?? 10; 
      await _firestore.collection('shifts').doc(shiftId).update({'startTime': start, 'endTime': end, 'Tolerance': tol});
      fetchMasterShifts(); 
      Get.back(); Get.back(); 
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "$e");
    }
  }
}