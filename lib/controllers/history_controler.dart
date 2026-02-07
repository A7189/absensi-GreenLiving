import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class HistoryController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = true.obs;
  var historyList = <QueryDocumentSnapshot>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  void fetchHistory() async {
    try {
      isLoading.value = true;
      User? user = _auth.currentUser;

      if (user != null) {
        // 🔥 FIX 1: FILTER LANGSUNG DARI FIREBASE
        // Pakai 'uid' (sesuai SS image_b08c8a.png), JANGAN 'userId'
        QuerySnapshot snapshot = await _db
            .collection('attendance_logs')
            .where('uid', isEqualTo: user.uid) // <--- INI KUNCINYA
            .get();

        // Ambil datanya
        var dataList = snapshot.docs.toList();

        // 🔥 FIX 2: SORTING MANUAL (Biar gak perlu bikin Index di Firebase Console)
        // Kita urutkan berdasarkan tanggal (Terbaru di atas)
        dataList.sort((a, b) {
          var dataA = a.data() as Map<String, dynamic>;
          var dataB = b.data() as Map<String, dynamic>;
          
          // Ambil tanggal (misal "2026-02-05")
          String dateA = dataA['date'] ?? '';
          String dateB = dataB['date'] ?? '';
          
          // Kalau tanggal sama, cek jam masuk (biar makin akurat)
          if (dateA == dateB) {
             Timestamp? timeA = dataA['checkInTime'];
             Timestamp? timeB = dataB['checkInTime'];
             if (timeA != null && timeB != null) {
               return timeB.compareTo(timeA);
             }
          }
          
          return dateB.compareTo(dateA); // Descending (B ke A)
        });

        historyList.assignAll(dataList);
        
        // Debugging Print (Cek di Console)
        print("✅ History Loaded: ${historyList.length} data ditemukan.");
      }
    } catch (e) {
      print("❌ Error Fetch History: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Helper Format Jam (Hanya Jam:Menit)
  String formatTime(dynamic timestamp) {
    if (timestamp == null) return '--:--';
    try {
      if (timestamp is Timestamp) {
        DateTime date = timestamp.toDate();
        return DateFormat('HH:mm').format(date);
      }
      return timestamp.toString();
    } catch (e) {
      return '--:--';
    }
  }
  
  // Helper Format Tanggal Lengkap (Opsional buat UI)
  String formatDate(String dateString) {
    try {
      DateTime dt = DateTime.parse(dateString);
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);
    } catch (e) {
      return dateString;
    }
  }
}