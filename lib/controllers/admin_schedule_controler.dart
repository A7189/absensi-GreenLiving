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

  // Cache Jadwal (Key: "2026-02-16", Value: "pagi")
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
    fetchUserShifts(); 
  }

  // --- 4. TARIK JADWAL USER (REFRESH) ---
  Future<void> fetchUserShifts() async {
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
    fetchUserShifts(); 
  }
  
  void setSpecificMonth(DateTime date) {
    currentMonth.value = date;
    fetchUserShifts();
  }

  // --- 5. UPDATE MANUAL SATUAN ---
  void updateSingleShift(DateTime date, String type) async {
    if (selectedUser.value == null) return;
    try {
      String uid = selectedUser.value!.uid;
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      // Optimistic Update
      userShifts[dateStr] = type;
      userShifts.refresh();
      
      DocumentReference docRef = _firestore.collection('shift_schedule').doc("$uid-$dateStr");
      
      if (type == 'Libur') {
         await docRef.delete(); 
      } else {
         await docRef.set({
          'uid': uid, 
          'date': dateStr, 
          'shiftId': type, 
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await fetchUserShifts();

    } catch (e) { 
      print("Error update single: $e");
      fetchUserShifts(); // Revert
    }
  }

  // --- 6. GENERATE OTOMATIS (SUPPORTS ALL SHIFTS) ---
  void executeGenerate({required String startShiftId, required DateTime startDate}) async {
    if (selectedUser.value == null) return;
    
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    try {
      WriteBatch batch = _firestore.batch();
      String uid = selectedUser.value!.uid;
      
      List<String> pattern = [];
      int currentPatternIdx = 0;

      // --- LOGIC PEMBAGIAN POLA ---

      // KELOMPOK 1: SATPAM (Rotasi 7 Hari)
      if (['Pagi', 'Siang', 'Malam', 'Libur'].contains(startShiftId)) {
          pattern = ['Malam', 'Malam', 'Siang', 'Siang', 'Pagi', 'Pagi', 'Libur'];
          
          if (startShiftId == 'Malam') currentPatternIdx = 0;
          if (startShiftId == 'Siang') currentPatternIdx = 2;
          if (startShiftId == 'Pagi') currentPatternIdx = 4;
          if (startShiftId == 'Libur') currentPatternIdx = 6;
      } 
      
      // KELOMPOK 2: NON-SATPAM (Tukang Sampah, Sapu, Taman - Flat)
      else {
          pattern = [startShiftId]; // Pola cuma 1 shift terus menerus
          currentPatternIdx = 0;
      }
      
      // Generate buat 31 Hari
      int durationDays = 31; 

      for (int i = 0; i < durationDays; i++) {
        DateTime date = startDate.add(Duration(days: i));
        String dateStr = DateFormat('yyyy-MM-dd').format(date);
        
        String shiftId = pattern[currentPatternIdx % pattern.length];
        
        // Kalau Rotasi, index nambah. Kalau Flat, index tetep.
        if (pattern.length > 1) {
            currentPatternIdx++;
        }
        
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
      if (Get.isDialogOpen ?? false) Get.back();
      
      await fetchUserShifts(); 
      Get.snackbar("Sukses", "Jadwal berhasil digenerate untuk $startShiftId!");
      
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