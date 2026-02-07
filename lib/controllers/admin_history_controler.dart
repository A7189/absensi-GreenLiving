import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Buat TextEditingController
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminHistoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = true.obs;
  
  // 🔥 GUDANG DATA (Data Mentah + Nama User)
  List<Map<String, dynamic>> masterLogs = []; 

  // 🔥 DATA TAMPIL (Hasil Filter)
  var finalLogs = <Map<String, dynamic>>[].obs; 
  
  // Controller Search & Sort
  TextEditingController searchController = TextEditingController();
  var isNewest = true.obs; 

  @override
  void onInit() {
    super.onInit();
    loadAdminHistory();
  }

  void loadAdminHistory() async {
    try {
      isLoading.value = true;
      masterLogs.clear();

      // 1. 🔥 AMBIL KAMUS NAMA (Semua User)
      // Biar kita tau UID "A123" itu namanya "Budi"
      var usersSnapshot = await _firestore.collection('users').get();
      Map<String, String> userMap = {};
      
      for (var doc in usersSnapshot.docs) {
        userMap[doc.id] = doc.data()['name'] ?? 'Unknown';
      }

      // 2. 🔥 AMBIL SEMUA LOG ABSENSI (Tanpa Filter UID)
      var logsSnapshot = await _firestore
          .collection('attendance_logs')
          .orderBy('createdAt', descending: true) // Default urut terbaru
          .get();

      // 3. 🔥 JAHIT DATA (Gabungin Log + Nama User)
      for (var doc in logsSnapshot.docs) {
        var data = doc.data();
        String uid = data['uid'] ?? ''; // <--- PENTING: Pakai 'uid' sesuai DB

        // Kita bikin object baru yang lengkap
        Map<String, dynamic> completeLog = {
          'id': doc.id,
          'uid': uid,
          'name': userMap[uid] ?? 'User Tidak Dikenal', 
          'status': data['status'] ?? 'Hadir',
          'checkInTime': data['checkInTime'], 
          'date': data['date'] ?? '-',
          'location': data['location'] ?? [],
          'checkOutTime': data['checkOutTime'] ?? null,
        };

        masterLogs.add(completeLog);
      }

      // 4. Tampilkan Awal
      runFilter();

    } catch (e) {
      print("Error load admin history: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void runFilter() {
    // Copy dari Gudang
    List<Map<String, dynamic>> tempResult = List.from(masterLogs);

    // 1. Filter Search (By Nama)
    String query = searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      tempResult = tempResult.where((log) {
        String name = log['name'].toString().toLowerCase();
        return name.contains(query);
      }).toList();
    }

    // 2. Sorting (Tanggal)
    tempResult.sort((a, b) {
      Timestamp tA = a['checkInTime'] ?? Timestamp.now();
      Timestamp tB = b['checkInTime'] ?? Timestamp.now();
      return isNewest.value 
          ? tB.compareTo(tA) // Terbaru di atas
          : tA.compareTo(tB); // Terlama di atas
    });

    // Lempar ke UI
    finalLogs.assignAll(tempResult);
  }

  // Helper Format Tanggal UI
  String formatDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate());
    }
    return "-";
  }
}