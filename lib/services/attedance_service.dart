import 'package:absensi_greenliving/models/attedance_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getOfficeConfig() async {
    try {
      DocumentSnapshot doc = await _db.collection('settings').doc('office_config').get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil konfigurasi kantor: $e');
    }
  }

  Future<void> saveAttendance(AttendanceModel attendance) async {
    try {
      await _db.collection('attendance_logs').add(attendance.toMap());
    } catch (e) {
      throw Exception('Gagal menyimpan data absensi: $e');
    }
  }

  Future<bool> checkTodayAttendance(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final query = await _db
        .collection('attendance_logs')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }
}