import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/shift_models.dart';

class ScheduleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔥 FUNGSI BARU: Get Shift Berdasarkan Tanggal (Tarik dari DB)
  // Tidak lagi pakai hitungan matematika (joinDate), tapi real data dari Admin.
  Future<ShiftModel?> getShiftForDate(String uid, DateTime targetDate) async {
    try {
      // 1. Normalisasi Tanggal ke String (Format: yyyy-MM-dd)
      String dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
      
      // 2. Bentuk ID Dokumen Jadwal (Format: UID-TANGGAL)
      String scheduleDocId = "$uid-$dateStr";

      // 3. Cek apakah ada jadwal di 'shift_schedule'
      DocumentSnapshot scheduleDoc = await _db.collection('shift_schedule').doc(scheduleDocId).get();

      // Kalau gak ada dokumennya, berarti Libur / Belum diset
      if (!scheduleDoc.exists) {
        return null; 
      }

      // 4. Ambil Shift ID (Contoh: "pagi", "malam", "siang")
      var scheduleData = scheduleDoc.data() as Map<String, dynamic>;
      String shiftId = scheduleData['shiftId'] ?? 'Libur';

      // Kalau ID-nya Libur, langsung return null (atau model Libur)
      if (shiftId.toLowerCase() == 'libur') return null;

      // 5. Ambil Detail Jam dari Master 'shifts'
      DocumentSnapshot shiftMasterDoc = await _db.collection('shifts').doc(shiftId).get();

      if (shiftMasterDoc.exists) {
        var masterData = shiftMasterDoc.data() as Map<String, dynamic>;

        // 🔥 FIX FORMAT JAM: Handle format '08.00' (titik) jadi '08:00' (titik dua)
        String startStr = (masterData['startTime'] as String).replaceAll('.', ':');
        String endStr = (masterData['endTime'] as String).replaceAll('.', ':');
        
        // Ambil Toleransi dari DB (Default 0 kalo gak ada)
        int tolerance = masterData['Tolerance'] ?? masterData['toleranceMinutes'] ?? 0;

        // Parsing String Jam ke DateTime spesifik tanggal target
        DateTime startTime = _parseTime(targetDate, startStr);
        DateTime endTime = _parseTime(targetDate, endStr);

        // Handle Shift Lintas Hari (Misal Masuk 22:00, Pulang 07:00 besoknya)
        if (endTime.isBefore(startTime)) {
          endTime = endTime.add(const Duration(days: 1));
        }

        return ShiftModel(
          uid: uid,
          date: targetDate, // Tanggal yang diminta
          type: shiftId,    // Pagi/Siang/Malam
          startTime: startTime,
          endTime: endTime,
          toleranceMinutes: tolerance, // 🔥 Masuk ke Model
        );
      }

      return null;
    } catch (e) {
      print("Error getShiftForDate: $e");
      return null;
    }
  }

  // Helper: Gabungin Tanggal Target + Jam dari DB
  DateTime _parseTime(DateTime date, String timeStr) {
    try {
      List<String> parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      // Fallback kalo parsing gagal
      return DateTime(date.year, date.month, date.day, 0, 0);
    }
  }
}