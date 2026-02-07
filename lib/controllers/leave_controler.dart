import 'package:absensi_greenliving/models/leave_models.dart';
import 'package:absensi_greenliving/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaveController extends GetxController {
  final DatabaseService _db = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Form Controllers
  final reasonController = TextEditingController();
  
  // Variables
  var selectedType = 'Sakit'.obs;
  var startDate = DateTime.now().obs;
  var endDate = DateTime.now().obs;
  var isLoading = false.obs;

  final List<String> leaveTypes = ['Sakit', 'Izin', 'Cuti'];

  // Variable Penampung Riwayat
  var myLeaves = <QueryDocumentSnapshot>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyLeaves(); // Panggil saat controller dibuat
  }

  // 🔥 UPDATE: TARIK DARI COLLECTION YANG BENAR ('leave_requests')
  void fetchMyLeaves() {
    User? user = _auth.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('leave_requests') // <--- SUDAH DISESUAIKAN DENGAN SS DATABASE
        .where('uid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true) // Biar yang baru nongol paling atas
        .snapshots()
        .listen((snapshot) {
          myLeaves.assignAll(snapshot.docs);
        });
  }

  // Update Tanggal UI
  void updateDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
  }

  void updateType(String? type) {
    if (type != null) selectedType.value = type;
  }

  Future<void> submitRequest() async {
    if (reasonController.text.isEmpty) {
      Get.snackbar("Error", "Alasan wajib diisi bro!", backgroundColor: Colors.red[100]);
      return;
    }

    try {
      isLoading.value = true;
      User? authUser = _auth.currentUser;
      
      if (authUser != null) {
        // 1. Ambil Nama User
        var userModel = await _db.getUser(authUser.uid);
        String userName = userModel?.name ?? "User"; 

        // 2. Bikin Model (Field sudah cocok sama SS: name, reason, status, type, uid)
        final request = LeaveModel(
          uid: authUser.uid,
          name: userName, 
          type: selectedType.value,
          reason: reasonController.text,
          status: 'Pending', 
          startDate: startDate.value,
          endDate: endDate.value,
          createdAt: DateTime.now(),
        );

        // 3. Kirim via DatabaseService (Pastikan service ini juga nulis ke 'leave_requests')
        // Kalau service Ndan masih nulis ke 'leaves', ganti manual di sini biar aman:
        await FirebaseFirestore.instance.collection('leave_requests').add(request.toMap());
        
        Get.back(); 
        Get.snackbar("Sukses", "Pengajuan berhasil dikirim!", backgroundColor: Colors.green[100]);
        reasonController.clear();
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal kirim: $e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    reasonController.dispose();
    super.onClose();
  }
}